implement doc_load_checked(d, path) = let
  val res = doc_load(d, path)
in
  if res then true
  else if ieq(fs_exists(path), 1) then let
    val () = report_failure("doc_load", path)
  in
    false
  end
  else true
end

fun find_task_node_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, i: int, n: int
): int =
  if recfuel > 0 then (
    if i < 0 orelse i >= n then ~1
    else if is_kind(doc_node_kind(d, i), KTask) then i
    else let
      val p = doc_node_parent(d, i)
    in
      if ige(p, 0) andalso ilt(p, n) then find_task_node_with_fuel(recfuel - 1, d, p, n)
      else ~1
    end
  ) else ~1

fun fold_region_offset_d(d: !Doc, reg: int): int =
  case+ d of
  | @DOC(s) => let
      val off = fold_region_offset(s.regions, reg)
    in
      fold@(d); off
    end

implement doc_toggle(d, i0) = let
  val n = d_nnodes(d)
in
  if i0 < 0 orelse i0 >= n then ()
  else let
    val st = doc_node_start(d, i0)
    val line = doc_line_of(d, st)
    val reg = doc_line_region(d, line)
  in
    if reg < 0 then ()
    else let
      val off = fold_region_offset_d(d, reg)
      val () = if fold_has(d, off) then fold_del(d, off) else fold_add(d, off)
      val () = d_bump_ver(d)
    in
      doc_compute_foldability(d)
    end
  end
end

fun deep_toggle_one_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, r: int, nreg: int, owner_l: int, fend_l: int, target_coll: int
): void =
  if recfuel > 0 then (
    if r >= nreg then ()
    else let
      val o = doc_region_owner(d, r)
    in
      if ige(o, owner_l) andalso ilt(o, fend_l) then let
        val off = fold_region_offset_d(d, r)
        val () = if ieq(target_coll, 1) then fold_add(d, off) else fold_del(d, off)
      in
        deep_toggle_one_with_fuel(recfuel - 1, d, iadd(r, 1), nreg, owner_l, fend_l, target_coll)
      end else deep_toggle_one_with_fuel(recfuel - 1, d, iadd(r, 1), nreg, owner_l, fend_l, target_coll)
    end
  ) else ()

fun toggle_region_subtree(d: !Doc, reg: int): void =
  if reg < 0 then ()
  else let
      val owner_l = doc_region_owner(d, reg)
      val fend_l = doc_region_end(d, reg)
      val off = fold_region_offset_d(d, reg)
      val target_coll = (if fold_has(d, off) then 0 else 1) : int
      val nreg = doc_region_count(d)
      val () = deep_toggle_one_with_fuel(airlock_nat(MAX_REC_FUEL), d, 0, nreg, owner_l, fend_l, target_coll)
      val () = d_bump_ver(d)
    in
      doc_compute_foldability(d)
  end

implement doc_toggle_deep(d, i0) =
  if i0 < 0 orelse i0 >= d_nnodes(d) then ()
  else toggle_region_subtree(d, doc_line_region(d, doc_line_of(d, doc_node_start(d, i0))))

extern fun task_box_find_fuel_exhausted(d: !Doc, st: int, en: int, p: int): int = "mac#anth_die_int"

fun task_box_find_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, st: int, en: int, p: int): int =
  if recfuel > 0 then (
    if ige(p, en) orelse ige(iadd(p, 2), d_len(d)) then ~1
    else if ieq(doc_byte(d, p), CHAR_LBRACKET) andalso ieq(doc_byte(d, iadd(p, 2)), CHAR_RBRACKET) then iadd(p, 1)
    else task_box_find_with_fuel(recfuel - 1, d, st, en, iadd(p, 1))
  ) else task_box_find_fuel_exhausted(d, st, en, p)

fun task_box_find(d: !Doc, st: int, en: int, p: int): int = task_box_find_with_fuel(airlock_nat(MAX_REC_FUEL), d, st, en, p)

fun task_next_state(cur: int): int =
  task_mark_byte(task_next_mark(task_mark_of(cur)))

fun replace_task_mark(d: !Doc, pos: int, nxt: int): void = let
  var nb = buf_make(REPLACE_TASK_MARK_BUFFER_INITIAL_BYTES)
  val () = buf_push(nb, nxt)
  val () = doc_set_caret_move(d, pos)
  val () = doc_set_caret_extend(d, iadd(pos, 1))
  val () = doc_delete(d)
  val () = doc_insert_buf(d, nb, 1)
in
  buf_free(nb)
end

implement doc_toggle_task(d, i0) = let
  val n = d_nnodes(d)
  val i = find_task_node_with_fuel(airlock_nat(MAX_REC_FUEL), d, i0, n)
in
  if i < 0 orelse i >= n then ()
  else if not(is_kind(doc_node_kind(d, i), KTask)) then ()
  else let
    val st = doc_node_start(d, i)
    val en = doc_node_end(d, i)
    val pos = task_box_find(d, st, en, st)
  in
    if pos < 0 then ()
    else replace_task_mark(d, pos, task_next_state(doc_byte(d, pos)))
  end
end

implement column_w(avail) =
  if avail < 720 then avail else if avail > 850 then 850 else avail

implement column_x(pane, avail) = iadd(pane, idiv(isub(avail, column_w(avail)), 2))

extern fun has_kind_fuel_exhausted(d: !Doc, k: NodeKind, i: int): int = "mac#anth_die_int"

fun has_kind_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, k: NodeKind, i: int): int =
  if recfuel > 0 then (
    if ige(i, d_nnodes(d)) then 0
    else let
      val ki = doc_node_kind(d, i)
      val kc = kind_code(k)
      val kic = kind_code(ki)
      val hit = (if ieq(kc, kic) then true
        else if ieq(kc, kind_code(KImage)) andalso ieq(kic, kind_code(KEmbed)) then true
        else false)
    in
      if hit then 1
      else has_kind_with_fuel(recfuel - 1, d, k, iadd(i, 1))
    end
  ) else has_kind_fuel_exhausted(d, k, i)

fun has_kind(d: !Doc, k: NodeKind, i: int): int = has_kind_with_fuel(airlock_nat(MAX_REC_FUEL), d, k, i)

fun put_str(d: !Doc, s: string): void =
  doc_insert(d, c_str_ptr(s), c_strlen(s))

extern fun fill_paras_fuel_exhausted(d: !Doc, i: int): void = "mac#anth_die_void"

fun fill_paras_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, i: int): void =
  if recfuel > 0 then (
    if ige(i, 100) then ()
    else let
      val () = put_str(d, "paragraf\n\n")
    in
      fill_paras_with_fuel(recfuel - 1, d, iadd(i, 1))
    end
  ) else fill_paras_fuel_exhausted(d, i)

fun fill_paras(d: !Doc, i: int): void = fill_paras_with_fuel(airlock_nat(MAX_REC_FUEL), d, i)

extern fun first_heading_fuel_exhausted(d: !Doc, i: int): int = "mac#anth_die_int"

fun first_heading_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, i: int): int =
  if recfuel > 0 then (
    if ige(i, doc_nnodes(d)) then ~1
    else if is_kind(doc_node_kind(d, i), KH1) then i
    else first_heading_with_fuel(recfuel - 1, d, iadd(i, 1))
  ) else first_heading_fuel_exhausted(d, i)

fun first_heading(d: !Doc, i: int): int = first_heading_with_fuel(airlock_nat(MAX_REC_FUEL), d, i)

fun selftest_gap_check(d: !Doc): int = let
  val () = put_str(d, "ab")
  val () = doc_left_move(d)
  val () = doc_backspace(d)
in
  (if ieq(doc_len(d), 1) andalso ieq(doc_byte(d, 0), 98) andalso ieq(doc_caret(d), 0) then 1 else 0)
end

fun selftest_fill_markdown(d: !Doc): void = let
  val () = doc_right_move(d)
  val () = put_str(d, "\n# Baslik\n\n- madde\n- [ ] gorev\n- [x] bitti\n\n> alinti\n\n```\nkod\n```\n\n| a | b |\n| --- | --- |\n| 1 | 2 |\n\n[[Sayfa|ad]] ![[Resim.png]] #etiket/alt ==vurgu== $x$ $$y$$\n\n[^1]: not\n")
  val () = put_str(d, "[[Sayfa#b]]\n")
in
end
