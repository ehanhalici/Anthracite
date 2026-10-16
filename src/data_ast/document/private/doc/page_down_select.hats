fun page_down_select_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, k: int, nlines: int): void =
  if recursion_fuel_available(recfuel) then (
    if k < nlines then let
      val () = doc_down_select(d)
    in
      page_down_select_with_fuel(recfuel - 1, d, iadd(k, 1), nlines)
    end else ()
  ) else page_down_select_fuel_exhausted(d, k, nlines)

implement doc_page_down_select(d, nlines) = page_down_select_with_fuel(airlock_nat(MAX_REC_FUEL), d, 0, nlines)

implement doc_save(d, path) = let
  var b = buf_make(DOC_SAVE_BUFFER_INITIAL_BYTES)
  val () = doc_text(d, b)
  val n = buf_len(b)
  val ok = fs_write_buf(path, b, n)
  val () = if ieq(ok, 1) then log_info("DOC", "save_ok", path)
           else log_error("DOC", "save_failed", path)
  val () = buf_free(b)
in
  ok
end

implement doc_save_vfs(d, path) = let
  val plen = c_strlen(path)
in
  if plen <= 0 then 0
  else let
    var vbuf = buf_make(DOC_SAVE_VFS_VBUF_INITIAL_BYTES)
    val () = fs_vfs_buf(path, vbuf, 511)
    val vp = buf_cstr(vbuf)
    val vlen = c_strlen(vp)
    val res = if vlen > 0 then doc_save(d, vp) else 0
    val () = buf_free(vbuf)
  in
    res
  end
end

implement doc_save_physical(d, path) = let
  val plen = c_strlen(path)
in
  if plen <= 0 then 0
  else let
    val res = doc_save(d, path)
    var vbuf = buf_make(DOC_SAVE_PHYSICAL_VBUF_INITIAL_BYTES)
    val () = fs_vfs_buf(path, vbuf, 511)
    val vp = buf_cstr(vbuf)
    val vlen = c_strlen(vp)
    val ul = if igt(vlen, 0) andalso ieq(fs_exists(vp), 1) then fs_unlink(vp) else 0
    val () = if ine(ul, 0) then report_failure("vfs_unlink", vp) else ()
    val () = buf_free(vbuf)
  in
    res
  end
end

fun replace_all_raw(d: !Doc, p: ptr, n: int): void = let
  val b = take_gap(d)
  val () = buf_free(b)
  val nb = buf_make(imax(256, iadd(n, 64)))
  val c = buf_cap(nb)
  val () = put_gap(d, nb)
  val () = d_set_lo(d, 0)
  val () = d_set_hi(d, c)
  val () = d_set_len(d, 0)
  val () = d_set_caret(d, 0)
  val () = d_set_anchor(d, 0)
  val () = d_set_nnodes(d, 0)
in
  doc_insert_core(d, p, n)
end

fun replace_all(d: !Doc, p: ptr, n: int): void = let
  val () = put_uhist(d, HNil())
  val () = put_rhist(d, HNil())
  val () = fold_clear(d)
in
  replace_all_raw(d, p, n)
end

fun replace_all_buf(d: !Doc, src: !Buf, n: int): void =
  replace_all(d, buf_ptr(src), n)

fun replace_raw_buf(d: !Doc, src: !Buf, n: int): void =
  replace_all_raw(d, buf_ptr(src), n)

fun insert_core_buf(d: !Doc, src: !Buf, n: int): void =
  doc_insert_core(d, buf_ptr(src), n)

fun restore_snapshot(d: !Doc, snap_b: Buf, snap_c: int): void = let
  val sn = buf_len(snap_b)
  val () = replace_raw_buf(d, snap_b, sn)
  val () = doc_set_caret_move(d, snap_c)
  val () = buf_free(snap_b)
in
end

implement doc_undo(d) = let
  var u = take_uhist(d)
in
  case+ u of
  | ~HNil() => put_uhist(d, HNil())
  | ~HCons(snap_b, snap_c, rest_u) => let
      val () = put_uhist(d, rest_u)
      val () = push_redo_current(d)
      val () = restore_snapshot(d, snap_b, snap_c)
    in
      set_last_op_and_reset_count(d, OpNone)
    end
end

implement doc_redo(d) = let
  var r = take_rhist(d)
in
  case+ r of
  | ~HNil() => put_rhist(d, HNil())
  | ~HCons(snap_b, snap_c, rest_r) => let
      val () = put_rhist(d, rest_r)
      val () = push_undo_current(d)
      val () = restore_snapshot(d, snap_b, snap_c)
    in
      set_last_op_and_reset_count(d, OpNone)
    end
end

fun wrap_selection(d: !Doc, a: int, b: int, pre: string, plen: int, suf: string, suflen: int): void = let
  val slen = isub(b, a)
  var sel_buf = buf_make(iadd(slen, 1))
  val () = seen_int(doc_slice_buf(d, a, b, sel_buf, slen))
  val () = buf_set_len(sel_buf, slen)
  val () = remove_between(d, a, b)
  val () = doc_insert_core(d, c_str_ptr(pre), plen)
  val () = insert_core_buf(d, sel_buf, slen)
  val () = doc_insert_core(d, c_str_ptr(suf), suflen)
  val () = buf_free(sel_buf)
  val new_pos = iadd(a, iadd(plen, iadd(slen, suflen)))
in
  doc_set_caret_move(d, new_pos)
end

fun wrap_at_caret(d: !Doc, a: int, pre: string, plen: int, suf: string, suflen: int): void = let
  val () = doc_insert_core(d, c_str_ptr(pre), plen)
  val () = doc_insert_core(d, c_str_ptr(suf), suflen)
  val mid = iadd(a, plen)
in
  doc_set_caret_move(d, mid)
end

implement doc_wrap(d, pre, plen, suf, suflen) = let
  val () = doc_record(d, OpBreak)
  var a: int = 0
  var b: int = 0
  val () = sel_span(d, a, b)
in
  if igt(b, a) then wrap_selection(d, a, b, pre, plen, suf, suflen)
  else wrap_at_caret(d, a, pre, plen, suf, suflen)
end

fun resolve_load_path(path: string, vbuf: !Buf): string = let
  val () = fs_vfs_buf(path, vbuf, 511)
  val vp = buf_cstr(vbuf)
  val vlen = c_strlen(vp)
  val has_vfs = igt(vlen, 0) andalso ieq(fs_exists(vp), 1) andalso igt(fs_size(vp), 0)
in
  if has_vfs then vp else path
end

fun is_markdown_path(path: string): bool = let
  val plen = c_strlen(path)
in
  if plen >= 3 andalso c_str_byte(path, isub(plen, 3)) = 46 andalso (c_str_byte(path, isub(plen, 2)) = 109 orelse c_str_byte(path, isub(plen, 2)) = 77) andalso (c_str_byte(path, isub(plen, 1)) = 100 orelse c_str_byte(path, isub(plen, 1)) = 68) then true
  else if plen >= 9 andalso c_str_byte(path, isub(plen, 9)) = 46 then true
  else false
end

fun read_doc_bytes(d: !Doc, path: string, fd: int, sz: int): bool = let
  val b = buf_make(iadd(sz, 1))
  val n = fs_read_buf(fd, b, sz)
  val () = fs_close(fd)
  val () = buf_set_len(b, if n > 0 then n else 0)
  val () = doc_set_md(d, toggle_of(is_markdown_path(path)))
  val () = replace_all_buf(d, b, if n > 0 then n else 0)
  val () = buf_free(b)
in
  true
end

fun load_doc_file(d: !Doc, path: string, actual_path: string): bool = let
  val sz = fs_size(actual_path)
in
  if sz < 0 orelse sz > 50000000 then false
  else let
    val fd = fs_open_read(actual_path)
  in
    if fd < 0 then false else read_doc_bytes(d, path, fd, sz)
  end
end

implement doc_load(d, path) = let
  var vbuf = buf_make(DOC_LOAD_VBUF_INITIAL_BYTES)
  val actual_path = resolve_load_path(path, vbuf)
  val res = load_doc_file(d, path, actual_path)
  val () = if res then log_info("DOC", "load_ok", path)
           else log_warn("DOC", "load_failed", path)
  val () = buf_free(vbuf)
in
  res
end

(* Var olan bir dosya yuklenemezse bos belge kaydetmeye yol acmamak icin
   hata raporlanir ve 0 doner. Dosya yoksa (yeni belge) 1 doner. *)
