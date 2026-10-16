fun free_input_bufs(clip: Buf, promptb: Buf, query: Buf, tree: Buf, tmeta: Buf, topen: Buf): void = let
  val () = buf_free(clip)
  val () = buf_free(promptb)
  val () = buf_free(query)
  val () = buf_free(tree)
  val () = buf_free(tmeta)
in
  buf_free(topen)
end

fun free_search_bufs(hits: Buf, hmeta: Buf, scratch: Buf, imgpath: Buf): void = let
  val () = buf_free(hits)
  val () = buf_free(hmeta)
  val () = buf_free(scratch)
  val () = buf_free(imgpath)
in
end

fun free_index_bufs(ixf: Buf, ixs: Buf, ixp: Buf, ixb: Buf, ixq: Buf, hjump: Buf): void = let
  val () = buf_free(ixf)
  val () = buf_free(ixs)
  val () = buf_free(ixp)
  val () = buf_free(ixb)
  val () = buf_free(ixq)
  val () = buf_free(hjump)
in
end

fun free_font_bufs(fpaths: Buf, fnames: Buf, fmeta: Buf, font_path: Buf): void = let
  val () = buf_free(fpaths)
  val () = buf_free(fnames)
  val () = buf_free(fmeta)
  val () = buf_free(font_path)
in
end

fun free_app_state(vault: Buf, ts2: Tabs, cache: Cache, vpaths: Buf, vnames: Buf, vmeta: Buf, tab_pane: Buf, open_dirs: Buf): void = let
  val () = buf_free(vault)
  val () = tabs_free(ts2)
  val () = cache_free(cache)
  val () = buf_free(vpaths)
  val () = buf_free(vnames)
  val () = buf_free(tab_pane)
  val () = buf_free(open_dirs)
in
  buf_free(vmeta)
end

implement app_free(a) = let
  var app_val = a
  val () = case+ app_val of
  | @APP(s) => let
      val () = sync_open_dirs_from_tree(s)
      val () = sync_tab_pane(s.tab_pane, tabs_len(s.tabs), s.split, s.righti)
    in
      fold@(app_val)
    end
  val+ ~APP(s) = app_val
  val ts2 = tabs_ensure_paths(s.tabs, s.vault)
  val side_open = (if is_side_none(s.side) then 0 else 1)
  val () = save_session_impl(s.vault, s.font_path, s.fontpx, s.viewmode, s.split, s.active, s.righti, side_open, s.sidew, s.tab_pane, s.open_dirs, ts2)
  val () = free_input_bufs(s.clip, s.promptb, s.query, s.tree, s.tmeta, s.topen)
  val () = free_search_bufs(s.hits, s.hmeta, s.scratch, s.imgpath)
  val () = free_index_bufs(s.ixf, s.ixs, s.ixp, s.ixb, s.ixq, s.hjump)
  val () = free_font_bufs(s.fpaths, s.fnames, s.fmeta, s.font_path)
in
  free_app_state(s.vault, ts2, s.cache, s.vpaths, s.vnames, s.vmeta, s.tab_pane, s.open_dirs)
end

fun pane_of(sfocus: Toggle, active: int, righti: int): int =
  if is_off(sfocus) then active else righti

fun tree_open_code(state: Toggle): int =
  case+ state of
  | Off() => 0
  | On() => 1

fun tree_open_of_code(code: int): Toggle =
  if ieq(code, tree_open_code(On)) then On else Off

fun buf_span_eq_m {rem:nat} .<rem>. (
  b1: !Buf, p1: int, b2: !Buf, p2: int, rem: int(rem)
): bool =
  if rem > 0 then (
    if ine(buf_get(b1, p1), buf_get(b2, p2)) then false
    else buf_span_eq_m(b1, iadd(p1, 1), b2, iadd(p2, 1), rem - 1)
  ) else true

fun skip_to_lf_m {rem:nat} .<rem>. (b: !Buf, i: int, rem: int(rem)): int =
  if rem > 0 then (
    if ieq(buf_get(b, i), CHAR_LF) then i
    else skip_to_lf_m(b, iadd(i, 1), rem - 1)
  ) else i

fun skip_to_lf(b: !Buf, i: int, n: int): int =
  if ige(i, n) then n
  else skip_to_lf_m(b, i, airlock_span(i, n))

fun is_in_lines_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), lines: !Buf, p: !Buf, cur: int, n: int
): bool =
  if recursion_fuel_available(recfuel) then (
    if ilt(cur, n) then let
      val e = skip_to_lf(lines, cur, n)
      val len = isub(e, cur)
      val plen = buf_len(p)
      val matches = ieq(len, plen) andalso buf_span_eq_m(lines, cur, p, 0, airlock_nat(len))
    in
      if matches then true
      else is_in_lines_with_fuel(recfuel - 1, lines, p, iadd(e, 1), n)
    end else false
  ) else false

fun is_in_lines(lines: !Buf, p: !Buf): bool =
  is_in_lines_with_fuel(airlock_nat(MAX_REC_FUEL), lines, p, 0, buf_len(lines))

fun check_row_open(tree: !Buf, meta: !Buf, open_dirs: !Buf, i: int): int =
  if is_dir_mark(meta_dir(meta, i), DirYes) andalso igt(buf_len(open_dirs), 0) then let
    var tmp = buf_make(CHECK_ROW_OPEN_TMP_INITIAL_BYTES)
    val () = row_path(tree, meta, i, tmp)
    val is_open = is_in_lines(open_dirs, tmp)
    val () = buf_free(tmp)
  in
    if is_open then 1 else 0
  end else 0

fun tree_open_defaults_m {rem:nat} .<rem>. (
  tree: !Buf, meta: !Buf, open_dirs: !Buf, open_rows: &Buf >> Buf, i: int, rem: int(rem)
): void =
  if rem > 0 then let
    val code = check_row_open(tree, meta, open_dirs, i)
  in
    buffer_push_byte(open_rows, code);
    tree_open_defaults_m(tree, meta, open_dirs, open_rows, iadd(i, 1), rem - 1)
  end else buffer_preserve(open_rows)

fun tree_open_defaults(tree: !Buf, meta: !Buf, open_dirs: !Buf, open_rows: &Buf >> Buf, n: int): void =
  if igt(n, 0) then tree_open_defaults_m(tree, meta, open_dirs, open_rows, 0, airlock_nat(n))
  else buffer_preserve(open_rows)

fun tree_row_open_state(s: &App_record, row: int): Toggle =
  tree_open_of_code(buf_get(s.topen, row))

fun tree_row_is_open(s: &App_record, row: int): bool =
  is_dir_mark(meta_dir(s.tmeta, row), DirYes) andalso is_on(tree_row_open_state(s, row))

fun tree_row_hidden(depth: int, hidden_depth: int): bool =
  ige(hidden_depth, 0) andalso igt(depth, hidden_depth)

fun tree_next_hidden(s: &App_record, row: int, depth: int, hidden_depth: int): int =
  if tree_row_is_open(s, row) then hidden_depth
  else if is_dir_mark(meta_dir(s.tmeta, row), DirYes) then depth
  else hidden_depth

fun tree_source_m {rem:nat} .<rem>. (
  s: &App_record, source: int, wanted: int, visible: int, hidden_depth: int, rem: int(rem)
): int =
  if rem <= 0 then ~1
  else let
    val depth = meta_depth(s.tmeta, source)
    val hidden = tree_row_hidden(depth, hidden_depth)
    val active_hidden = if not(hidden) then ~1 else hidden_depth
    val next_hidden = tree_next_hidden(s, source, depth, active_hidden)
  in
    if hidden then tree_source_m(s, iadd(source, 1), wanted, visible, active_hidden, rem - 1)
    else if ieq(visible, wanted) then source
    else tree_source_m(s, iadd(source, 1), wanted, iadd(visible, 1),
      next_hidden, rem - 1)
  end

fun tree_source_for_view(s: &App_record, wanted: int): int =
  if ilt(wanted, 0) orelse ile(s.tn, 0) then ~1
  else tree_source_m(s, 0, wanted, 0, ~1, airlock_nat(s.tn))

fun tree_count_visible {rem:nat} .<rem>. (
  s: &App_record, source: int, visible: int, hidden_depth: int, rem: int(rem)
): int =
  if rem <= 0 then visible
  else let
    val depth = meta_depth(s.tmeta, source)
    val hidden = tree_row_hidden(depth, hidden_depth)
    val active_hidden = if not(hidden) then ~1 else hidden_depth
    val next_visible = if hidden then visible else iadd(visible, 1)
    val next_hidden = if hidden then active_hidden else tree_next_hidden(s, source, depth, active_hidden)
  in
    tree_count_visible(s, iadd(source, 1), next_visible, next_hidden, rem - 1)
  end

fun tree_visible_count(s: &App_record): int =
  tree_count_visible(s, 0, 0, ~1, airlock_nat(s.tn))

fun tree_source_at_y(s: &App_record, y: int): int =
  if ilt(y, 72) then ~1
  else tree_source_for_view(s, iadd(s.treescroll, idiv(isub(y, 72), UI_TREE_ROW_HEIGHT)))

fun tree_toggle_source(s: &App_record >> _, source: int): void =
  if ige(source, 0) andalso is_dir_mark(meta_dir(s.tmeta, source), DirYes) then let
    val current = tree_row_open_state(s, source)
    val next = case+ current of | Off() => On | On() => Off
    val () = s.drag := DragNone
    val () = s.dragi := ~1
    val () = buf_set(s.topen, source, tree_open_code(next))
    val () = sync_open_dirs_from_tree(s)
  in
    save_app_session(s)
  end else ()
