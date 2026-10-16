fun selftest_gutter_arrow(r: !Rend): int = let
  val f = font_open()
  val () = font_set_px(f, 16)
  val aw = font_arrow_w(f, r)
  val colx = editor_colx(f, r, 0, 800)
  val arr_x = arrow_pos_x(f, r, colx)
  val num_end = gutter_num_end_x(f, r, colx)
  val ok1 = if igt(aw, 0) andalso ilt(num_end, arr_x) then 1 else 0
  val ok2 = if ilt(iadd(arr_x, aw), colx) andalso ige(isub(arr_x, num_end), 6) then 1 else 0
  val ok = if ieq(ok1, 1) andalso ieq(ok2, 1) then 1 else 0
  val () = font_free(f)
in
  ok
end

fun selftest_visual_wrap(r: !Rend): int = let
  val doc = doc_open()
  val s = "Intro [[folder/nested/sub/note.md|Very Long Alias Title Here]] outro\n"
  val () = doc_insert(doc, c_str_ptr(s), c_strlen(s))
  val f = font_open()
  val () = font_set_px(f, 16)
  var cache = CNil()
  var vault = buf_make(8)
  var scratch = buf_make(256)
  val h = prepare_document_layout(f,doc, cache, r, vault, 18, 800, ViewRead)
  var py: int = 0; var pa: int = 0
  val () = draw_nodes(f, r, doc, 0, 0, 800, 600, 0, 18, vault, cache, scratch, 0, py, pa, ViewRead)
  val ok = if igt(h, 0) then 1 else 0
  val () = cache_free(cache)
  val () = buf_free(vault)
  val () = buf_free(scratch)
  val () = font_free(f)
  val () = doc_free(doc)
in
  ok
end

fun selftest_error_render(f: !Font, r: !Rend, doc: !Doc): int = let
  var cache = CNil()
  var vault = buf_make(8)
  var scratch = buf_make(256)
  val h1 = prepare_document_layout(f,doc, cache, r, vault, 18, 800, ViewEdit)
  var py: int = 0; var pa: int = 0
  val () = draw_nodes(f, r, doc, 0, 0, 800, 600, 0, 18, vault, cache, scratch, 0, py, pa, ViewEdit)
  val h2 = prepare_document_layout(f,doc, cache, r, vault, 18, 800, ViewRead)
  val () = draw_nodes(f, r, doc, 0, 0, 800, 600, 0, 18, vault, cache, scratch, 0, py, pa, ViewRead)
  val ok = if igt(h1, 0) andalso igt(h2, 0) then 1 else 0
  val () = cache_free(cache)
  val () = buf_free(vault)
  val () = buf_free(scratch)
in
  ok
end

fun selftest_error_has_err(doc: !Doc): int = let
  val n = doc_nnodes(doc)
in
  if igt(n, 1) andalso iand(ast_style(doc, 1), STYLE_ERROR) != 0 then 1 else 0
end

fun selftest_ast_error_tolerance(r: !Rend): int = let
  val doc = doc_open()
  val s = "```\ncode\n`inline [[wiki $$math [link](url\n"
  val () = doc_insert(doc, c_str_ptr(s), c_strlen(s))
  val f = font_open()
  val () = font_set_px(f, 16)
  val rend_ok = selftest_error_render(f, r, doc)
  val err_ok = selftest_error_has_err(doc)
  val () = font_free(f)
  val () = doc_free(doc)
in
  if ieq(rend_ok, 1) andalso ieq(err_ok, 1) then 1 else 0
end

fun selftest_math_render(f: !Font, r: !Rend, doc: !Doc): int = let
  var cache = CNil()
  var vault = buf_make(8)
  var scratch = buf_make(256)
  val h1 = prepare_document_layout(f,doc, cache, r, vault, 18, 800, ViewRead)
  var py: int = 0; var pa: int = 0
  val () = draw_nodes(f, r, doc, 0, 0, 800, 600, 0, 18, vault, cache, scratch, 0, py, pa, ViewRead)
  val h2 = prepare_document_layout(f,doc, cache, r, vault, 18, 800, ViewEdit)
  val () = draw_nodes(f, r, doc, 0, 0, 800, 600, 0, 18, vault, cache, scratch, 0, py, pa, ViewEdit)
  val ok = if igt(h1, 0) andalso igt(h2, 0) then 1 else 0
  val () = cache_free(cache)
  val () = buf_free(vault)
  val () = buf_free(scratch)
in
  ok
end

fun selftest_math_visualizer(r: !Rend): int = let
  val doc = doc_open()
  val s = "Math test\n\n$$ s = \\sqrt{ { \\Sigma (x_i - \\bar x)^2 } \\over n } $$\n\n$E = mc^2$ and $\\sqrt{a^2 + b^2}$\n"
  val () = doc_insert(doc, c_str_ptr(s), c_strlen(s))
  val f = font_open()
  val () = font_set_px(f, 16)
  val rend_ok = selftest_math_render(f, r, doc)
  val () = font_free(f)
  val () = doc_free(doc)
in
  rend_ok
end

fun selftest_named_tab(tabs: Tabs,path: string,title: string): Tabs = let
  val document=doc_open()
  var path_buffer: Buf=buf_make(16)
  var title_buffer: Buf=buf_make(16)
  val ()=buffer_append_string(path_buffer,path)
  val ()=buffer_append_string(title_buffer,title)
in tabs_append(tabs,document,path_buffer,title_buffer,0) end

fun selftest_tab_drag_split_reorder(): int = let
  val ts0=selftest_named_tab(TNil(),"note1.md","note1")
  val ts1 = tabs_clone_tab(ts0, 0)
  val l1 = tabs_len(ts1)
  val ts2=selftest_named_tab(ts1,"note2.md","note2")
  val l2 = tabs_len(ts2)
  val ts3 = tabs_move(ts2, 0, 2)
  val () = tabs_free(ts3)
  var tp = buf_make(4)
  val () = tab_pane_init_split(tp, 3, 1)
  val g0 = buf_get(tp, 0)
  val g1 = buf_get(tp, 1)
  val g2 = buf_get(tp, 2)
  val p_ok = ieq(g0, 0) andalso ieq(g1, 1) andalso ieq(g2, 0)
  val () = buf_free(tp)
in
  if ieq(l1, 2) andalso ieq(l2, 3) andalso p_ok then 1 else 0
end

fun selftest_flow_checks(r: !Rend, root: string): int = let
  val rz_ok = selftest_img_resize(r, root)
  val ext_ok = selftest_external_link()
  val pfx_ok = selftest_quote_prefix()
  val ga_ok = selftest_gutter_arrow(r)
  val vw_ok = selftest_visual_wrap(r)
  val err_ok = selftest_ast_error_tolerance(r)
  val math_ok = selftest_math_visualizer(r)
  val drag_ok = selftest_tab_drag_split_reorder()
in
  if ieq(rz_ok, 1) andalso ieq(ext_ok, 1) andalso ieq(pfx_ok, 1) andalso ieq(ga_ok, 1)
     andalso ieq(vw_ok, 1) andalso ieq(err_ok, 1) andalso ieq(math_ok, 1) andalso ieq(drag_ok, 1) then 1 else 0
end

fun selftest_flow(r: !Rend, root: string): @(int, int, Doc, Cache, Buf, Buf) = let
  val f=font_open()
  val doc = doc_open()
  val () = doc_insert(doc, c_str_ptr("hello\n\n![](anth-t.png)\n\nworld\n"), c_strlen("hello\n\n![](anth-t.png)\n\nworld\n"))
  var cache = CNil()
  var vault = buf_make(8)
  val () = buffer_append_string(vault, root)
  var scratch = buf_make(256)
  val height = prepare_document_layout(f,doc, cache, r, vault, 18, 720, ViewEdit)
  val ()=font_free(f)
  val ii = find_img(doc, 0)
  val iy = if ige(ii, 0) then doc_node_y(doc, ii) else ~1
  val ih = if ige(ii, 0) then doc_node_height(doc, ii) else 0
  val checks = selftest_flow_checks(r, root)
  val flow_ok = if ige(ii, 0) andalso igt(ih, 8) andalso ige(height, iadd(iy, ih)) andalso ieq(checks, 1) then 1 else 0
in
  @(flow_ok, ih, doc, cache, vault, scratch)
end

fun selftest_pane_search(): bool = let
  var panes: Buf=buf_make(8)
  val ()=buf_push(panes,0)
  val ()=buf_push(panes,1)
  val ()=buf_push(panes,1)
  val first=tab_pane_find_first(panes,1)
  val last=buf_get(panes,2)
  val ()=buf_free(panes)
in ieq(first,1) andalso ieq(last,1) end

fun selftest_tabs(d1: !Buf): int = let
  val docA = doc_open()
  val () = doc_insert(docA, c_str_ptr("[[b]]\n"), 6)
  val () = doc_set_caret_move(docA, 2)
  var ta = buf_make(4); var pa = buf_make(4)
  val tsA = tabs_add(TNil(), docA, pa, ta)
  val docB = doc_open()
  var tb = buf_make(4); var pb = buf_make(4)
  val tsB = tabs_add(tsA, docB, pb, tb)
  val n2 = tabs_len(tsB)
  val tsC = tabs_drop(tsB, 1)
  val n1 = tabs_len(tsC)
  val tsD = wiki_open(tsC, 0, d1, 0)
  val nw = tabs_len(tsD)
  val tsE = wiki_open(tsD, 0, d1, 0)
  val nw2 = tabs_len(tsE)
  val dedup_ok = (if ieq(nw2, 2) then 1 else 0)
  val () = tabs_free(tsE)
  val sp_ok=if selftest_pane_search() then 1 else 0
in
  (if ieq(n2, 2) andalso ieq(n1, 1) andalso ieq(nw, 2) andalso ieq(dedup_ok, 1) andalso ieq(sp_ok, 1) then 1 else 0)
end

fun selftest_move_ops(sub: !Buf, src: !Buf, dstp: !Buf): int = let
  val mv = fs_rename(buffer_c_string(src), buffer_c_string(dstp))
  val moved = fs_exists(buffer_c_string(dstp))
  val () = seen_int(fs_unlink(buffer_c_string(dstp)))
  val gone = fs_exists(buffer_c_string(dstp))
  val () = seen_int(fs_rmdir(buffer_c_string(sub)))
in
  (if ieq(mv, 0) andalso ieq(moved, 1) andalso ieq(gone, 0) then 1 else 0)
end

fun selftest_session_check_tree(): int = let
  var meta = buf_make(16)
  var tree = buf_make(16)
  var open_dirs = buf_make(16)
  val () = buf_ensure(meta, 16)
  val () = buf_set32(meta, 0, 0)
  val () = buf_set32(meta, 1, 1)
  val () = buf_set32(meta, 2, 0)
  val () = buf_set32(meta, 3, 3)
  val () = buffer_append_string(tree, "dir")
  val c0 = check_row_open(tree, meta, open_dirs, 0)
  val () = buffer_append_string(open_dirs, "dir\n")
  val c1 = check_row_open(tree, meta, open_dirs, 0)
  val () = buf_free(meta)
  val () = buf_free(tree)
  val () = buf_free(open_dirs)
in
  (if ieq(c0, 0) andalso ieq(c1, 1) then 1 else 0)
end
