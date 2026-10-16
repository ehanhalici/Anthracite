extern fun find_line_owner_node_fuel_exhausted(d: !Doc, line: int, i: int, n: int, best_i: int, best_r: int): int = "mac#anth_die_int"

fun find_line_owner_node_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, line: int, i: int, n: int, best_i: int, best_r: int
): int =
  if recfuel > 0 then (
    if i >= n then best_i
    else let
      val st = doc_node_start(d, i)
      val l = doc_line_of(d, st)
    in
      if ieq(l, line) then let
        val k = doc_node_kind(d, i)
        val r = node_block_rank(k)
      in
        if igt(r, best_r) then find_line_owner_node_with_fuel(recfuel - 1, d, line, iadd(i, 1), n, i, r)
        else find_line_owner_node_with_fuel(recfuel - 1, d, line, iadd(i, 1), n, best_i, best_r)
      end else find_line_owner_node_with_fuel(recfuel - 1, d, line, iadd(i, 1), n, best_i, best_r)
    end
  ) else find_line_owner_node_fuel_exhausted(d, line, i, n, best_i, best_r)

fun stamp_one_region_node(d: !Doc, r: int, nn: int): void = let
  val owner_l = doc_region_owner(d, r)
  val ni = find_line_owner_node_with_fuel(airlock_nat(MAX_REC_FUEL), d, owner_l, 0, nn, ~1, 0)
in
  if ige(ni, 0) andalso ilt(ni, nn) then let
    val fl = doc_node_flags(d, ni)
    val new_fl = (if ieq(iand(fl, FL_FOLDABLE), 0) then iadd(fl, FL_FOLDABLE) else fl)
    val () = node_field_set(d, ni, NF_FLAGS, new_fl)
    val off = doc_region_offset(d, r)
    val coll = (if fold_has(d, off) then 1 else 0) : int
    val () = node_field_set(d, ni, NF_COLLAPSED, coll)
  in
  end else ()
end

extern fun stamp_regions_m_fuel_exhausted(d: !Doc, r: int, nreg: int, nn: int): void = "mac#anth_die_void"

fun stamp_regions_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, r: int, nreg: int, nn: int
): void =
  if recfuel > 0 then (
    if r >= nreg then ()
    else let
      val () = stamp_one_region_node(d, r, nn)
    in
      stamp_regions_with_fuel(recfuel - 1, d, iadd(r, 1), nreg, nn)
    end
  ) else stamp_regions_m_fuel_exhausted(d, r, nreg, nn)

fun sync_one_node_hidden(d: !Doc, i: int): void = let
  val st = doc_node_start(d, i)
  val line = doc_line_of(d, st)
  val hid = doc_is_line_hidden(d, line)
in
  if ieq(hid, 1) then let
    val () = doc_node_set_hidden(d, i, On)
    val () = doc_node_set_height(d, i, 0)
  in
  end else
    doc_node_set_hidden(d, i, Off)
end

extern fun sync_nodes_hidden_m_fuel_exhausted(d: !Doc, i: int, n: int): void = "mac#anth_die_void"

fun sync_nodes_hidden_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, i: int, n: int
): void =
  if recfuel > 0 then (
    if i >= n then ()
    else let
      val () = sync_one_node_hidden(d, i)
    in
      sync_nodes_hidden_with_fuel(recfuel - 1, d, iadd(i, 1), n)
    end
  ) else sync_nodes_hidden_m_fuel_exhausted(d, i, n)

implement doc_compute_foldability(d) = let
  var r = doc_take_regions(d)
  var h = doc_take_hidden(d)
  val nreg = fold_region_build(d, r)
  val () = fold_regions_compute_hidden(d, r, h)
  val () = doc_put_regions(d, r)
  val () = doc_put_hidden(d, h)
  val nn = d_nnodes(d)
  val () = clear_flags_with_fuel(airlock_nat(MAX_REC_FUEL), d, 0, nn)
  val () = stamp_regions_with_fuel(airlock_nat(MAX_REC_FUEL), d, 0, nreg, nn)
  val () = sync_nodes_hidden_with_fuel(airlock_nat(MAX_REC_FUEL), d, 0, nn)
in
end

fun fold_apply(d: !Doc): void = doc_compute_foldability(d)

fun node_height(d: !Doc, i: int, lh: int): int = let
  val k = doc_node_kind(d, i)
  val lines = count_nl(d, doc_node_start(d, i), doc_node_end(d, i), 1)
in
  if is_on(doc_node_hidden(d, i)) then 0
  else if is_kind(k, KEmbed) then let
    val a = doc_node_height(d, i)
  in
    if igt(a, 8) then a else 0
  end
  else if is_inline(k) then 0
  else if is_kind(k, KHr) then 12
  else if is_kind(k, KImage) then let
    val a = doc_node_height(d, i)
  in
    if igt(a, 8) then a else 96
  end
  else imul(lines, lh)
end

fun apply_one_node_vis(d: !Doc, i: int, lh: int): void = let
  val st = doc_node_start(d, i)
  val line = doc_line_of(d, st)
  val hid = doc_is_line_hidden(d, line)
in
  if ieq(hid, 1) then let
    val () = doc_node_set_hidden(d, i, On)
    val () = doc_node_set_height(d, i, 0)
  in
  end else let
    val () = doc_node_set_hidden(d, i, Off)
    val h = node_height(d, i, lh)
    val () = doc_node_set_height(d, i, h)
  in
  end
end

extern fun apply_nodes_vis_m_fuel_exhausted(d: !Doc, i: int, n: int, lh: int): void = "mac#anth_die_void"

fun apply_nodes_vis_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, i: int, n: int, lh: int
): void =
  if recfuel > 0 then (
    if i >= n then ()
    else let
      val () = apply_one_node_vis(d, i, lh)
    in
      apply_nodes_vis_with_fuel(recfuel - 1, d, iadd(i, 1), n, lh)
    end
  ) else apply_nodes_vis_m_fuel_exhausted(d, i, n, lh)

implement doc_layout_ast_prepare(d, line_height) = let
  val () = doc_compute_foldability(d)
  val nodes = d_nnodes(d)
in
  apply_nodes_vis_with_fuel(airlock_nat(MAX_REC_FUEL), d, 0, nodes, line_height)
end

implement doc_layout_line_hidden(d, start, stop, node_count) = let
  val line = doc_line_of(d, start)
in
  doc_is_line_hidden(d, line)
end

extern fun widget_h_fuel_exhausted(d: !Doc, st: int, en: int, i: int, n: int, acc: int): int = "mac#anth_die_int"

fun widget_h_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, st: int, en: int, i: int, n: int, acc: int): int =
  if recfuel > 0 then (
    if ige(i, n) then acc
    else let
      val k = doc_node_kind(d, i)
      val ns = doc_node_start(d, i)
      val h = doc_node_height(d, i)
      val is_widget = is_kind(k, KImage) orelse is_kind(k, KEmbed) orelse is_kind(k, KMathb)
      val wh = if is_kind(k, KMathb) andalso ieq(h, 0) then 24 else h
      val use = if is_off(doc_node_hidden(d, i)) andalso ige(ns, st) andalso ilt(ns, en) andalso is_widget andalso igt(wh, acc) then wh else acc
    in
      widget_h_with_fuel(recfuel - 1, d, st, en, iadd(i, 1), n, use)
    end
  ) else widget_h_fuel_exhausted(d, st, en, i, n, acc)

fun widget_h(d: !Doc, st: int, en: int, i: int, n: int, acc: int): int = widget_h_with_fuel(airlock_nat(MAX_REC_FUEL), d, st, en, i, n, acc)

implement doc_layout_widget_height(d, start, stop, node_count) =
  widget_h(d, start, stop, 0, node_count, 0)

fun line_heading_extra(k: NodeKind, lh: int): int =
  if is_kind(k, KH1) then iadd(idiv(imul(lh, 3), 4), 24)
  else if is_kind(k, KH2) then iadd(idiv(lh, 2), 18)
  else if is_kind(k, KH3) then iadd(idiv(lh, 4), 14)
  else if is_kind(k, KH4) then 12
  else if is_kind(k, KH5) then 8
  else 0

extern fun line_heading_pad_fuel_exhausted(d: !Doc, st: int, en: int, i: int, n: int, lh: int, acc: int): int = "mac#anth_die_int"

fun line_heading_pad_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, st: int, en: int, i: int, n: int, lh: int, acc: int
): int =
  if recfuel > 0 then (
    if ige(i, n) then acc
    else let
      val k = doc_node_kind(d, i)
      val ns = doc_node_start(d, i)
      val ex = if ige(ns, st) andalso ilt(ns, en) then line_heading_extra(k, lh) else 0
    in
      line_heading_pad_with_fuel(recfuel - 1, d, st, en, iadd(i, 1), n, lh, imax(acc, ex))
    end
  ) else line_heading_pad_fuel_exhausted(d, st, en, i, n, lh, acc)

