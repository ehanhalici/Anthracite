fun run_cmd(d: !Doc, cmd: Cmd): void = let
  val () = run_motion_cmd(d, cmd)
in
  run_edit_cmd(d, cmd)
end

extern fun tabs_cmd_impl_fuel_exhausted(ts: Tabs, idx: int, cmd: Cmd): Tabs = "mac#anth_die_box"

fun tabs_cmd_impl_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), ts: Tabs, idx: int, cmd: Cmd): Tabs =
  if recfuel > 0 then (
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
  if recfuel > 0 then (
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
  if recfuel > 0 then (
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
  if recfuel > 0 then (
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
  if recfuel > 0 then (
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

extern fun tabs_ensure_paths_impl_fuel_exhausted(ts: Tabs, vault: !Buf): Tabs = "mac#anth_die_box"

fun tabs_ensure_paths_impl_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), ts: Tabs, vault: !Buf): Tabs =
  if recfuel > 0 then (
    case+ ts of
    | ~TNil() => TNil()
    | ~TCons(doc, path, title, sc, rest) => let
        val p2 = resolve_one_path(path, title, vault)
        val () = if save_ok(doc, p2) then () else ()
      in
        TCons(doc, p2, title, sc, tabs_ensure_paths_impl_with_fuel(recfuel - 1, rest, vault))
      end
  ) else tabs_ensure_paths_impl_fuel_exhausted(ts, vault)

fun tabs_ensure_paths_impl(ts: Tabs, vault: !Buf): Tabs = tabs_ensure_paths_impl_with_fuel(airlock_nat(MAX_REC_FUEL), ts, vault)

implement tabs_ensure_paths(ts, vault) = tabs_ensure_paths_impl(ts, vault)


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

fun tabs_copy_impl {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), ts: !Tabs, idx: int, dst: &Buf >> _): void =
  if recfuel > 0 then (
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
  ) else buffer_preserve(dst)
and copy_arm {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), stop: Toggle, doc: !Doc, rest: !Tabs, idx: int, dst: &Buf >> _): void =
  if recfuel > 0 then (
    if is_on(stop) then copy_here(doc, dst) else tabs_copy_impl(recfuel - 1, rest, isub(idx, 1), dst)
  ) else buffer_preserve(dst)

implement tabs_copy(ts, idx, dst) = tabs_copy_impl(airlock_nat(MAX_REC_FUEL), ts, idx, dst)

(* Var olan ama okunamayan dosya acilmaz: bos belge kaydedilip dosya ezilmesin. *)
fun open_loaded(ts: Tabs, doc: Doc, path: Buf): Tabs = let
  var title = buf_make(OPEN_LOADED_TITLE_INITIAL_BYTES)
  val () = base_name(path, title)
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

implement tabs_open(ts, path) =
  if is_image_path(path) then open_image(ts, path)
  else let
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

