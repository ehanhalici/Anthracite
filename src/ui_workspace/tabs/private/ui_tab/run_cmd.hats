fun run_cmd(d: !Doc, cmd: Cmd): void = let
  val () = run_motion_cmd(d, cmd)
in
  run_edit_cmd(d, cmd)
end

extern fun tabs_cmd_impl_fuel_exhausted(ts: Tabs, idx: int, cmd: Cmd): Tabs = "mac#anth_die_box"

fun tabs_cmd_impl_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), ts: Tabs, idx: int, cmd: Cmd): Tabs =
  if recursion_fuel_available(recfuel) then (
    case+ ts of
    | ~TNil() => TNil()
    | ~TCons(doc, path, title, sc, rest) => let
        val () = if ieq(idx, 0) then run_cmd(doc, cmd) else ()
      in
        if ieq(idx, 0) then TCons(doc, path, title, sc, rest) else TCons(doc, path, title, sc, tabs_cmd_impl_with_fuel(recfuel - 1, rest, isub(idx, 1), cmd))
      end
  ) else tabs_cmd_impl_fuel_exhausted(ts, idx, cmd)

fun tabs_cmd_impl(ts: Tabs, idx: int, cmd: Cmd): Tabs = tabs_cmd_impl_with_fuel(airlock_nat(MAX_REC_FUEL), ts, idx, cmd)

implement tabs_cmd(ts, idx, cmd) = tabs_cmd_impl(ts, idx, cmd)

extern fun tabs_ins_impl_fuel_exhausted(ts: Tabs, idx: int, p: ptr, n: int): Tabs = "mac#anth_die_box"

fun tabs_ins_impl_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), ts: Tabs, idx: int, p: ptr, n: int): Tabs =
  if recursion_fuel_available(recfuel) then (
    case+ ts of
    | ~TNil() => TNil()
    | ~TCons(doc, path, title, sc, rest) => let
        val () = if ieq(idx, 0) andalso igt(n, 0) then doc_insert(doc, p, n) else ()
      in
        if ieq(idx, 0) then TCons(doc, path, title, sc, rest) else TCons(doc, path, title, sc, tabs_ins_impl_with_fuel(recfuel - 1, rest, isub(idx, 1), p, n))
      end
  ) else tabs_ins_impl_fuel_exhausted(ts, idx, p, n)

fun tabs_ins_impl(ts: Tabs, idx: int, p: ptr, n: int): Tabs = tabs_ins_impl_with_fuel(airlock_nat(MAX_REC_FUEL), ts, idx, p, n)

implement tabs_ins(ts, idx, p, n) = tabs_ins_impl(ts, idx, p, n)

implement tabs_ins_buf(ts, idx, b, n) = tabs_ins(ts, idx, buf_ptr(b), n)

extern fun tabs_scroll_impl_fuel_exhausted(ts: Tabs, idx: int, dv: int, lim: int): Tabs = "mac#anth_die_box"

fun tabs_scroll_impl_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), ts: Tabs, idx: int, dv: int, lim: int): Tabs =
  if recursion_fuel_available(recfuel) then (
    case+ ts of
    | ~TNil() => TNil()
    | ~TCons(doc, path, title, sc, rest) => let
        val sc2 = if ieq(idx, 0) then imax(0, imin(lim, iadd(sc, dv))) else sc
      in
        if ieq(idx, 0) then TCons(doc, path, title, sc2, rest) else TCons(doc, path, title, sc2, tabs_scroll_impl_with_fuel(recfuel - 1, rest, isub(idx, 1), dv, lim))
      end
  ) else tabs_scroll_impl_fuel_exhausted(ts, idx, dv, lim)

fun tabs_scroll_impl(ts: Tabs, idx: int, dv: int, lim: int): Tabs = tabs_scroll_impl_with_fuel(airlock_nat(MAX_REC_FUEL), ts, idx, dv, lim)

implement tabs_scroll(ts, idx, dv, lim) = tabs_scroll_impl(ts, idx, dv, lim)

extern fun tabs_get_scroll_fuel_exhausted(ts: !Tabs, idx: int): int = "mac#anth_die_int"

fun tabs_get_scroll_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), ts: !Tabs, idx: int): int =
  if recursion_fuel_available(recfuel) then (
    case+ ts of
    | TNil() => 0
    | TCons(_, _, _, sc, rest) =>
        if ieq(idx, 0) then sc else tabs_get_scroll_m(recfuel - 1, rest, isub(idx, 1))
  ) else tabs_get_scroll_fuel_exhausted(ts, idx)

implement tabs_get_scroll(ts, idx) = tabs_get_scroll_m(airlock_nat(MAX_REC_FUEL), ts, idx)

extern fun tabs_set_scroll_fuel_exhausted(ts: Tabs, idx: int, nsc: int): Tabs = "mac#anth_die_box"

fun tabs_set_scroll_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), ts: Tabs, idx: int, nsc: int): Tabs =
  if recursion_fuel_available(recfuel) then (
    case+ ts of
    | ~TNil() => TNil()
    | ~TCons(doc, path, title, sc, rest) =>
        if ieq(idx, 0) then TCons(doc, path, title, imax(0, nsc), rest)
        else TCons(doc, path, title, sc, tabs_set_scroll_m(recfuel - 1, rest, isub(idx, 1), nsc))
  ) else tabs_set_scroll_fuel_exhausted(ts, idx, nsc)

implement tabs_set_scroll(ts, idx, sc) = tabs_set_scroll_m(airlock_nat(MAX_REC_FUEL), ts, idx, sc)

extern fun tabs_set_caret_fuel_exhausted(ts: Tabs, idx: int, c: int): Tabs = "mac#anth_die_box"

fun tabs_set_caret_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), ts: Tabs, idx: int, c: int): Tabs =
  if recursion_fuel_available(recfuel) then (
    case+ ts of
    | ~TNil() => TNil()
    | ~TCons(doc, path, title, sc, rest) => let
        val () = if ieq(idx, 0) then doc_set_caret_move(doc, c) else ()
      in
        if ieq(idx, 0) then TCons(doc, path, title, sc, rest)
        else TCons(doc, path, title, sc, tabs_set_caret_m(recfuel - 1, rest, isub(idx, 1), c))
      end
  ) else tabs_set_caret_fuel_exhausted(ts, idx, c)

implement tabs_set_caret(ts, idx, c) = tabs_set_caret_m(airlock_nat(MAX_REC_FUEL), ts, idx, c)

fun tabs_sync_cursor_focus_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), ts: !Tabs, focused: bool, active_idx: int, i: int
): void =
  if recursion_fuel_available(recfuel) then (
    case+ ts of
    | TNil() => ()
    | TCons(doc, _, _, _, rest) => let
        val () = doc_set_cursor_active(doc, focused andalso ieq(i, active_idx))
      in
        tabs_sync_cursor_focus_m(recfuel - 1, rest, focused, active_idx, iadd(i, 1))
      end
  ) else ()

implement tabs_sync_cursor_focus(ts, focused, active_idx) =
  tabs_sync_cursor_focus_m(airlock_nat(MAX_REC_FUEL), ts, focused, active_idx, 0)

datatype TabTextField = TabFieldPath | TabFieldTitle

extern fun tabs_get_buf_fuel_exhausted(ts: !Tabs, idx: int, field: TabTextField, dst: &Buf >> _): void = "mac#anth_die_void"

fun tabs_get_buf_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), ts: !Tabs, idx: int, field: TabTextField, dst: &Buf >> _
): void =
  if recursion_fuel_available(recfuel) then (
    case+ ts of
    | TNil() => buffer_clear(dst)
    | TCons(_, path, title, _, rest) =>
        if ieq(idx, 0) then (
          buffer_clear(dst);
          case+ field of
          | TabFieldPath() => buffer_append_all(dst, path)
          | TabFieldTitle() => buffer_append_all(dst, title)
        ) else tabs_get_buf_m(recfuel - 1, rest, isub(idx, 1), field, dst)
  ) else tabs_get_buf_fuel_exhausted(ts, idx, field, dst)

implement tabs_get_path(ts, idx, dst) = tabs_get_buf_m(airlock_nat(MAX_REC_FUEL), ts, idx, TabFieldPath(), dst)
implement tabs_get_title(ts, idx, dst) = tabs_get_buf_m(airlock_nat(MAX_REC_FUEL), ts, idx, TabFieldTitle(), dst)

fun buf_prefix_eq_m {rem:nat} .<rem>. (p: !Buf, pfx: !Buf, i: int, rem: int(rem)): bool =
  if rem = 0 then true
  else if ieq(buf_get(p, i), buf_get(pfx, i)) then buf_prefix_eq_m(p, pfx, iadd(i, 1), rem - 1)
  else false

fun path_has_prefix(p: !Buf, pfx: !Buf): bool = let
  val plen = buf_len(p)
  val xlen = buf_len(pfx)
in
  if ilt(plen, xlen) orelse ile(xlen, 0) then false
  else if ieq(plen, xlen) then buf_prefix_eq_m(p, pfx, 0, airlock_nat(xlen))
  else ieq(buf_get(p, xlen), CHAR_SLASH) andalso buf_prefix_eq_m(p, pfx, 0, airlock_nat(xlen))
end

fun append_suffix_opt(np: &Buf >> _, path: !Buf, olen: int, plen: int): void =
  if igt(plen, olen) then buffer_append_range(np, path, olen, plen) else ()

fun rewrite_tab_path(path: &Buf >> _, title: &Buf >> _, old_p: !Buf, new_p: !Buf): void =
  if path_has_prefix(path, old_p) then let
    val plen = buf_len(path)
    val olen = buf_len(old_p)
    var np = buf_make(iadd(buf_len(new_p), isub(plen, olen)))
    val () = buffer_append_all(np, new_p)
    val () = append_suffix_opt(np, path, olen, plen)
    val () = buffer_clear(path)
    val () = buffer_append_all(path, np)
    val () = buf_free(np)
    val () = buffer_clear(title)
  in
    base_name_no_md(path, title)
  end else ()

extern fun tabs_rename_prefix_fuel_exhausted(ts: Tabs, old_p: !Buf, new_p: !Buf): Tabs = "mac#anth_die_box"

fun tabs_rename_prefix_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), ts: Tabs, old_p: !Buf, new_p: !Buf
): Tabs =
  if recursion_fuel_available(recfuel) then (
    case+ ts of
    | ~TNil() => TNil()
    | ~TCons(doc, path, title, sc, rest) => let
        var p = path
        var t = title
        val () = rewrite_tab_path(p, t, old_p, new_p)
      in
        TCons(doc, p, t, sc, tabs_rename_prefix_m(recfuel - 1, rest, old_p, new_p))
      end
  ) else tabs_rename_prefix_fuel_exhausted(ts, old_p, new_p)

implement tabs_rename_prefix(ts, old_p, new_p) = tabs_rename_prefix_m(airlock_nat(MAX_REC_FUEL), ts, old_p, new_p)


fun resolve_save_path(path: Buf, title: !Buf, vault: !Buf, idx: int): Buf =
  if ieq(idx, 0) andalso ieq(buf_len(path), 0) andalso igt(buf_len(vault), 0) then let
    var nb = buf_make(iadd(buf_len(vault), iadd(buf_len(title), 8)))
    val () = child_path(vault, title, nb)
    val need_md = not(ends(nb, ".md"))
    val () = buffer_append_string_if(nb, toggle_of(need_md), ".md")
    val () = buf_free(path)
  in
    nb
  end else path

fun resolve_one_path(path: Buf, title: !Buf, vault: !Buf): Buf =
  resolve_save_path(path, title, vault, 0)


fun sync_vfs_one(doc: !Doc, path: !Buf, go: Toggle): void =
  if is_on(go) andalso igt(buf_len(path), 0) then let
    val () = if save_ok(doc, path) then () else ()
  in
    ()
  end else let
    val () = touch_doc(doc)
  in
    ()
  end

extern fun tabs_sync_vfs_impl_fuel_exhausted(ts: !Tabs, idx: int): void = "mac#anth_die_void"

fun tabs_sync_vfs_impl_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), ts: !Tabs, idx: int): void =
  if recursion_fuel_available(recfuel) then (
    case+ ts of
    | @TNil() => fold@(ts)
    | @TCons(doc, path, title, sc, rest) => let
        val () = sync_vfs_one(doc, path, toggle_of(ieq(idx, 0)))
        val () = if ine(idx, 0) then tabs_sync_vfs_impl_with_fuel(recfuel - 1, rest, isub(idx, 1)) else ()
        val () = seen_int(sc)
      in
        fold@(ts)
      end
  ) else tabs_sync_vfs_impl_fuel_exhausted(ts, idx)

fun tabs_sync_vfs_impl(ts: !Tabs, idx: int): void = tabs_sync_vfs_impl_with_fuel(airlock_nat(MAX_REC_FUEL), ts, idx)

implement tabs_sync_vfs(ts, idx) = tabs_sync_vfs_impl(ts, idx)

extern fun tabs_save_all_physical_impl_fuel_exhausted(ts: !Tabs): void = "mac#anth_die_void"

fun tabs_save_all_physical_impl_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), ts: !Tabs): void =
  if recursion_fuel_available(recfuel) then (
    case+ ts of
    | @TNil() => fold@(ts)
    | @TCons(doc, path, title, sc, rest) => let
        val () = if save_ok(doc, path) then () else ()
        val () = tabs_save_all_physical_impl_with_fuel(recfuel - 1, rest)
        val () = seen_int(sc)
      in
        fold@(ts)
      end
  ) else tabs_save_all_physical_impl_fuel_exhausted(ts)

fun tabs_save_all_physical_impl(ts: !Tabs): void = tabs_save_all_physical_impl_with_fuel(airlock_nat(MAX_REC_FUEL), ts)

implement tabs_save_all_physical(ts) = tabs_save_all_physical_impl(ts)

datatype FlushPolicy = FlushAll | FlushDirtyOnly

fun tab_needs_flush(p2: !Buf, pol: FlushPolicy): bool =
  case+ pol of
  | FlushAll() => true
  | FlushDirtyOnly() =>
      if ile(buf_len(p2), 0) orelse is_image_path(p2) then false
      else let
        val ps = buffer_c_string(p2)
      in
        if ieq(fs_exists(ps), 0) then true
        else let
          var vbuf = buf_make(256)
          val () = fs_vfs_buf(ps, vbuf, 255)
          val vp = buf_cstr(vbuf)
          val dirty = igt(c_strlen(vp), 0) andalso ieq(fs_exists(vp), 1)
          val () = buf_free(vbuf)
        in dirty end
      end

extern fun tabs_ensure_paths_impl_fuel_exhausted(ts: Tabs, vault: !Buf): Tabs = "mac#anth_die_box"

fun tabs_save_paths_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), ts: Tabs, vault: !Buf, pol: FlushPolicy
): Tabs =
  if recursion_fuel_available(recfuel) then (
    case+ ts of
    | ~TNil() => TNil()
    | ~TCons(doc, path, title, sc, rest) => let
        val p2 = resolve_one_path(path, title, vault)
        val () = if tab_needs_flush(p2, pol) then (if save_ok(doc, p2) then () else ()) else ()
      in
        TCons(doc, p2, title, sc, tabs_save_paths_with_fuel(recfuel - 1, rest, vault, pol))
      end
  ) else tabs_ensure_paths_impl_fuel_exhausted(ts, vault)

implement tabs_ensure_paths(ts, vault) =
  tabs_save_paths_with_fuel(airlock_nat(MAX_REC_FUEL), ts, vault, FlushAll())

implement tabs_flush_paths(ts, vault) =
  tabs_save_paths_with_fuel(airlock_nat(MAX_REC_FUEL), ts, vault, FlushDirtyOnly())


fun copy_here(doc: !Doc, dst: &Buf >> _): void = let
  val a = doc_anchor(doc)
  val c = doc_caret(doc)
  val lo = imin(a, c)
  val hi = imax(a, c)
  val () = buf_ensure(dst, iadd(isub(hi, lo), 2))
  val cap = buf_cap(dst)
  val n = doc_slice_buf(doc, lo, hi, dst, cap)
in
  buf_set_len(dst, n)
end

extern fun tabs_copy_fuel_exhausted(ts: !Tabs, idx: int, dst: &Buf >> _): void = "mac#anth_die_void"

fun tabs_copy_impl {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), ts: !Tabs, idx: int, dst: &Buf >> _): void =
  if recursion_fuel_available(recfuel) then (
    case+ ts of
    | @TNil() => fold@(ts)
    | @TCons(doc, path, title, sc, rest) => let
        val () = copy_arm(recfuel - 1, toggle_of(ieq(idx, 0)), doc, rest, idx, dst)
        val () = seen_buf(path)
        val () = seen_buf(title)
        val () = seen_int(sc)
      in
        fold@(ts)
      end
  ) else tabs_copy_fuel_exhausted(ts, idx, dst)
and copy_arm {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), stop: Toggle, doc: !Doc, rest: !Tabs, idx: int, dst: &Buf >> _): void =
  if recursion_fuel_available(recfuel) then (
    if is_on(stop) then copy_here(doc, dst) else tabs_copy_impl(recfuel - 1, rest, isub(idx, 1), dst)
  ) else tabs_copy_fuel_exhausted(rest, idx, dst)

implement tabs_copy(ts, idx, dst) = tabs_copy_impl(airlock_nat(MAX_REC_FUEL), ts, idx, dst)

(* Var olan ama okunamayan dosya acilmaz: bos belge kaydedilip dosya ezilmesin. *)
fun open_loaded(ts: Tabs, doc: Doc, path: Buf): Tabs = let
  var title = buf_make(OPEN_LOADED_TITLE_INITIAL_BYTES)
  val () = base_name_no_md(path, title)
in
  tabs_add(ts, doc, path, title)
end

fun open_image(ts: Tabs, path: Buf): Tabs = let
  val p = buffer_c_string(path)
  val ok = fs_exists(p)
in
  if ieq(ok, 1) then let
    val doc = doc_open()
  in
    open_loaded(ts, doc, path)
  end else let
    val () = buf_free(path)
  in
    ts
  end
end

fun open_document(ts: Tabs, path: Buf): Tabs = let
    val doc = doc_open()
    val ok = doc_load_checked(doc, buffer_c_string(path))
  in
    if ok then open_loaded(ts, doc, path)
    else let
      val () = doc_free(doc)
      val () = buf_free(path)
    in
      ts
    end
  end
implement tabs_open(ts, path) =
  if is_image_path(path) then open_image(ts, path) else open_document(ts, path)

fun tabs_wrap_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), ts: Tabs, idx: int, pre: string, plen: int, suf: string, suflen: int
): Tabs =
  if recursion_fuel_available(recfuel) then (
    case+ ts of
    | ~TNil() => TNil()
    | ~TCons(doc, path, title, sc, rest) => let
        val () = if ieq(idx, 0) then doc_wrap(doc, pre, plen, suf, suflen) else ()
      in
        if ieq(idx, 0) then TCons(doc, path, title, sc, rest)
        else TCons(doc, path, title, sc, tabs_wrap_with_fuel(recfuel - 1, rest, isub(idx, 1), pre, plen, suf, suflen))
      end
  ) else ts

implement tabs_wrap(ts, idx, pre, plen, suf, suflen) =
  tabs_wrap_with_fuel(airlock_nat(MAX_REC_FUEL), ts, idx, pre, plen, suf, suflen)

fun md_digit_prefix_m {rem:nat} .<rem>. (d: !Doc, i: int, n: int, cnt: int, rem: int(rem)): int =
  if rem = 0 then 0
  else if ige(i, n) orelse igt(cnt, 5) then 0
  else let
    val c = doc_byte(d, i)
  in
    if ige(c, 48) andalso ile(c, 57) then md_digit_prefix_m(d, iadd(i, 1), n, iadd(cnt, 1), rem - 1)
    else if igt(cnt, 0) andalso ieq(c, 46) andalso ilt(iadd(i, 1), n) andalso ieq(doc_byte(d, iadd(i, 1)), 32) then
      iadd(cnt, 2)
    else 0
  end

fun md_hash_prefix_m {rem:nat} .<rem>. (d: !Doc, i: int, n: int, cnt: int, rem: int(rem)): int =
  if rem = 0 then 0
  else if ige(i, n) orelse igt(cnt, 6) then 0
  else let
    val c = doc_byte(d, i)
  in
    if ieq(c, 35) then md_hash_prefix_m(d, iadd(i, 1), n, iadd(cnt, 1), rem - 1)
    else if igt(cnt, 0) andalso ieq(c, 32) then iadd(cnt, 1)
    else 0
  end

fun md_line_prefix_len(d: !Doc, ls: int, n: int): int =
  if ilt(ls, 0) orelse ige(ls, n) then 0
  else let
    val b0 = doc_byte(d, ls)
  in
    if ieq(b0, 35) then md_hash_prefix_m(d, ls, n, 0, airlock_nat(8))
    else if ieq(b0, 45) andalso ilt(iadd(ls, 5), n)
      andalso ieq(doc_byte(d, iadd(ls, 1)), 32) andalso ieq(doc_byte(d, iadd(ls, 2)), 91)
      andalso ieq(doc_byte(d, iadd(ls, 4)), 93) andalso ieq(doc_byte(d, iadd(ls, 5)), 32)
    then 6
    else if (ieq(b0, 45) orelse ieq(b0, 42) orelse ieq(b0, 62))
      andalso ilt(iadd(ls, 1), n) andalso ieq(doc_byte(d, iadd(ls, 1)), 32)
    then 2
    else if ige(b0, 48) andalso ile(b0, 57) then md_digit_prefix_m(d, ls, n, 0, airlock_nat(8))
    else 0
  end

fun doc_apply_line_prefix(d: !Doc, pre: string, plen: int): void = let
  val c = doc_caret(d)
  val line = doc_line_of(d, c)
  val ls = doc_line_start(d, line)
  val n = doc_len(d)
  val old_len = md_line_prefix_len(d, ls, n)
  val () = doc_set_caret_move(d, ls)
  val () = if igt(old_len, 0) then doc_delete_range(d, ls, imin(n, iadd(ls, old_len))) else ()
  val () = if igt(plen, 0) then doc_insert(d, c_str_ptr(pre), plen) else ()
  val after = if ige(c, iadd(ls, old_len)) then iadd(ls, iadd(plen, isub(c, iadd(ls, old_len)))) else iadd(ls, plen)
in
  doc_set_caret_move(d, imax(0, imin(doc_len(d), after)))
end

fun tabs_prefix_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), ts: Tabs, idx: int, pre: string, plen: int
): Tabs =
  if recursion_fuel_available(recfuel) then (
    case+ ts of
    | ~TNil() => TNil()
    | ~TCons(doc, path, title, sc, rest) => let
        val () = if ieq(idx, 0) then doc_apply_line_prefix(doc, pre, plen) else ()
      in
        if ieq(idx, 0) then TCons(doc, path, title, sc, rest)
        else TCons(doc, path, title, sc, tabs_prefix_with_fuel(recfuel - 1, rest, isub(idx, 1), pre, plen))
      end
  ) else ts

implement tabs_set_line_prefix(ts, idx, pre, plen) =
  tabs_prefix_with_fuel(airlock_nat(MAX_REC_FUEL), ts, idx, pre, plen)

fun path_prefix_eq_m {rem:nat} .<rem>. (a: !Buf, b: !Buf, i: int, rem: int(rem)): bool =
  if rem = 0 then true
  else ieq(buf_get(a, i), buf_get(b, i)) andalso path_prefix_eq_m(a, b, iadd(i, 1), rem - 1)

fun tab_path_matches_target(path: !Buf, target: !Buf, is_dir: bool): bool = let
  val plen = buf_len(path)
  val tlen = buf_len(target)
in
  if ile(tlen, 0) orelse ilt(plen, tlen) then false
  else if ieq(plen, tlen) then buffer_equal_from(path, target, 0)
  else if not(is_dir) then false
  else ieq(buf_get(path, tlen), 47) andalso path_prefix_eq_m(path, target, 0, airlock_nat(tlen))
end

fun tabs_discard_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), ts: Tabs, target: !Buf, is_dir: bool
): Tabs =
  if recursion_fuel_available(recfuel) then (
    case+ ts of
    | ~TNil() => TNil()
    | ~TCons(doc, path, title, sc, rest) =>
        if tab_path_matches_target(path, target, is_dir) then (
          doc_free(doc); buf_free(path); buf_free(title); seen_int(sc);
          tabs_discard_with_fuel(recfuel - 1, rest, target, is_dir)
        ) else TCons(doc, path, title, sc, tabs_discard_with_fuel(recfuel - 1, rest, target, is_dir))
  ) else ts

implement tabs_discard_matching(ts, target, is_dir) =
  tabs_discard_with_fuel(airlock_nat(MAX_REC_FUEL), ts, target, is_dir)
