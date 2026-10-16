fun fill_dir_vault_or_cwd(dir: &Buf >> _, vault: !Buf): void = let
  val n = buf_len(vault)
in
  if igt(n, 0) then buffer_append_range(dir, vault, 0, n) else fill_dir_cwd(dir)
end

fun fill_dir(dir: &Buf >> _, cur: !Buf, vault: !Buf, use_dir: Toggle, sel: int): void =
  if is_on(use_dir) andalso igt(buf_len(cur), 0) then let
    val n = buf_len(cur)
  in
    buffer_append_range(dir, cur, 0, n)
  end else if ige(sel, 0) andalso igt(buf_len(cur), 0) then fill_dir_from_dirname(dir, cur, vault)
  else let
    val () = seen_buf(cur)
  in
    fill_dir_vault_or_cwd(dir, vault)
  end

fun copy_if(ts: !Tabs, idx: int, clip: &Buf >> _, go: Toggle): void =
  if is_on(go) then tabs_copy(ts, idx, clip) else buffer_preserve(clip)

fun cmd_if(ts: Tabs, idx: int, cmd: Cmd, go: Toggle): Tabs =
  if is_on(go) then tabs_cmd(ts, idx, cmd) else ts

fun drop_if(ts: Tabs, ti: int, go: Toggle): Tabs =
  if is_on(go) then tabs_drop(ts, ti) else ts

fun tab_keep_one(ts: Tabs, close: Toggle): Tabs =
  if is_on(close) then
    if ieq(tabs_len(ts), 0) then new_empty_tab(ts) else ts
  else ts

fun open_row(ts: Tabs, tree: !Buf, meta: !Buf, row: int, go: Toggle): Tabs =
  if is_on(go) then let
    var cur = buf_make(OPEN_ROW_CUR_INITIAL_BYTES)
    val () = row_path(tree, meta, row, cur)
    val owned = buffer_clone(cur)
    val () = buf_free(cur)
  in
    tabs_open(ts, owned)
  end else ts

fun click_go(f: !Font, r: !Rend, ts: Tabs, idx: int, x: int, y: int, ox: int, pw: int, lh: int, scratch: &Buf >> _, keep: Toggle, hitk: &NodeKind >> _, hiti: &int >> _, go: Toggle): Tabs =
  if is_on(go) then tabs_click(f, r, ts, idx, x, y, ox, pw, 0, lh, scratch, keep, hitk, hiti, 0)
  else let
    val () = buffer_preserve(scratch)
  in
    ts
  end

fun wiki_go(ts: Tabs, idx: int, vault: !Buf, go: Toggle): Tabs =
  if is_on(go) then wiki_open(ts, idx, vault, 0) else ts

fun read_all(path: !Buf, dst: &Buf >> _): void = let
  val p = buffer_c_string(path)
  val sz = fs_size(p)
in
  if sz <= 0 orelse sz > 8000000 then buffer_preserve(dst)
  else let
    val fd = fs_open_read(p)
    val () = buffer_clear(dst)
    val () = buf_ensure(dst, iadd(sz, 1))
    val n = read_available_file_bytes(dst, fd, sz)
    val () = if fd >= 0 then fs_close(fd) else ()
  in
    buf_set_len(dst, if igt(n, 0) then n else 0)
  end
end

fun fill_node_path(doc: !Doc, ni: int, vault: !Buf, dst: &Buf >> _): void = let
  var rel = buf_make(FILL_NODE_PATH_REL_INITIAL_BYTES)
  var full = buf_make(FILL_NODE_PATH_FULL_INITIAL_BYTES)
  val () = take_if(doc, ni, rel, toggle_of(ige(ni, 0)))
  val () = resolve_path(vault, rel, full)
  val () = with_md(full, dst)
  val () = buf_free(rel)
in
  buf_free(full)
end

fun copy_node_here(doc: !Doc, ni: int, vault: !Buf, clip: &Buf >> _): void = let
  var shown = buf_make(COPY_NODE_HERE_SHOWN_INITIAL_BYTES)
  val () = fill_node_path(doc, ni, vault, shown)
  val () = read_all(shown, clip)
in
  buf_free(shown)
end

extern fun copy_node_file_fuel_exhausted(ts: !Tabs, idx: int, ni: int, vault: !Buf, clip: &Buf >> _, i: int): void = "mac#anth_die_void"

fun copy_node_file_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), ts: !Tabs, idx: int, ni: int, vault: !Buf, clip: &Buf >> _, i: int): void =
  if recfuel > 0 then (
    case+ ts of
    | @TNil() => let
        val () = buffer_preserve(clip)
      in
        fold@(ts)
      end
    | @TCons(doc, path, title, sc, rest) => let
        val () = if ieq(i, idx) then copy_node_here(doc, ni, vault, clip)
                 else copy_node_file_with_fuel(recfuel - 1, rest, idx, ni, vault, clip, iadd(i, 1))
        val () = seen_buf(path)
        val () = seen_buf(title)
        val () = seen_int(sc)
      in
        fold@(ts)
      end
  ) else copy_node_file_fuel_exhausted(ts, idx, ni, vault, clip, i)

fun copy_node_file(ts: !Tabs, idx: int, ni: int, vault: !Buf, clip: &Buf >> _, i: int): void = copy_node_file_with_fuel(airlock_nat(MAX_REC_FUEL), ts, idx, ni, vault, clip, i)

fun clip_image(ts: !Tabs, idx: int, ni: int, vault: !Buf, clip: &Buf >> _, go: Toggle): void =
  if is_on(go) then copy_node_file(ts, idx, ni, vault, clip, 0) else buffer_preserve(clip)

fun erase_span(doc: !Doc, a: int, b: int): void = let
  val () = doc_set_caret_move(doc, a)
  val () = doc_set_caret_extend(doc, b)
in
  doc_delete(doc)
end

fun span_if(doc: !Doc, a: int, b: int, go: Toggle): void =
  if is_on(go) then erase_span(doc, a, b)
  else let
    val () = doc_touch(doc)
  in
    ()
  end

fun node_field(doc: !Doc, ni: int, field: int): int =
  if ige(ni, 0) then doc_get(doc, ni, field)
  else let
    val () = doc_touch(doc)
  in
    0
  end

extern fun del_node_fuel_exhausted(ts: Tabs, idx: int, ni: int): Tabs = "mac#anth_die_box"

fun del_node_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), ts: Tabs, idx: int, ni: int): Tabs =
  if recfuel > 0 then (
    case+ ts of
    | ~TNil() => TNil()
    | ~TCons(doc, path, title, sc, rest) => let
        val a = node_field(doc, ni, 1)
        val b = node_field(doc, ni, 2)
        val go = ieq(idx, 0) andalso ige(ni, 0)
        val () = span_if(doc, a, b, toggle_of(go))
      in
        if ieq(idx, 0) then TCons(doc, path, title, sc, rest) else TCons(doc, path, title, sc, del_node_with_fuel(recfuel - 1, rest, isub(idx, 1), ni))
      end
  ) else del_node_fuel_exhausted(ts, idx, ni)

fun del_node(ts: Tabs, idx: int, ni: int): Tabs = del_node_with_fuel(airlock_nat(MAX_REC_FUEL), ts, idx, ni)

fun del_go(ts: Tabs, idx: int, ni: int, go: Toggle): Tabs =
  if is_on(go) then del_node(ts, idx, ni) else ts

extern fun strip_into_fuel_exhausted(src: !Buf, dst: &Buf >> _, i: int): void = "mac#anth_die_void"

fun strip_into_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), src: !Buf, dst: &Buf >> _, i: int): void =
  if recfuel > 0 then (
    if ige(i, buf_len(src)) then buffer_preserve(dst)
    else let
      val c = buf_get(src, i)
      val drop = ieq(c, 42) orelse ieq(c, 61) orelse ieq(c, 91) orelse ieq(c, 93) orelse ieq(c, 96)
      val () = push_if(dst, toggle_of(not(drop)), c)
    in
      strip_into_with_fuel(recfuel - 1, src, dst, iadd(i, 1))
    end
  ) else strip_into_fuel_exhausted(src, dst, i)

fun strip_into(src: !Buf, dst: &Buf >> _, i: int): void = strip_into_with_fuel(airlock_nat(MAX_REC_FUEL), src, dst, i)

fun clear_span_stripped(doc: !Doc, lo: int, hi: int): void = let
  var raw = buf_make(iadd(isub(hi, lo), 2))
  var out = buf_make(iadd(isub(hi, lo), 2))
  val cap = buf_cap(raw)
  val n = doc_slice_buf(doc, lo, hi, raw, cap)
  val () = buf_set_len(raw, n)
  val () = strip_into(raw, out, 0)
  val () = erase_span(doc, lo, hi)
  val m = buf_len(out)
  val () = doc_insert_buf(doc, out, m)
  val () = buf_free(raw)
in
  buf_free(out)
end

fun clear_doc(doc: !Doc): void = let
  val a0 = doc_anchor(doc)
  val c0 = doc_caret(doc)
  val lo = imin(a0, c0)
  val hi = imax(a0, c0)
in
  if ieq(lo, hi) then let
    val () = doc_touch(doc)
  in
    ()
  end else clear_span_stripped(doc, lo, hi)
end

