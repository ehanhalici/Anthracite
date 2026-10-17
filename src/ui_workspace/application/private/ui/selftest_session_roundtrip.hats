fun selftest_session_roundtrip(root: string): int = let
  var tp = buf_make(8); val () = buf_push(tp, 0); val () = buf_push(tp, 1)
  var od = buf_make(16); val () = buffer_append_string(od, "folder\n")
  var dummy = TNil()
  val () = conf_save_session(root, "f.ttf", 18, 0, 1, 0, 1, 1, 260, tp, od, dummy)
  var fp = buf_make(32); var fpx: int = 0; var vm: int = 0; var sp: int = 0
  var act: int = 0; var righti: int = 0; var side_open: int = 0; var sidew: int = 0
  var ltp = buf_make(8); var lod = buf_make(16)
  val ts = conf_load_session(root, fp, fpx, vm, sp, act, righti, side_open, sidew, ltp, lod, dummy)
  val () = tabs_free(ts)
  val od_len = buf_len(lod)
  val ok = (if ieq(sp, 1) andalso ieq(righti, 1) andalso ieq(side_open, 1) andalso ieq(sidew, 260) andalso igt(od_len, 0) then 1 else 0)
  val () = buf_free(tp); val () = buf_free(od); val () = buf_free(fp)
  val () = buf_free(ltp); val () = buf_free(lod)
in
  ok
end

fun selftest_files(root: string): int = let
  val sub = selftest_fixture_path(root, "sub")
  val () = seen_int(fs_mkdir(buffer_c_string(sub)))
  val src = selftest_fixture_path(root, "move.md")
  var one = buf_make(4)
  val () = buffer_append_string(one, "x\n")
  val () = seen_int(write_text(src, one))
  val dstp = selftest_fixture_path(root, "sub/move.md")
  val move_ok = selftest_move_ops(sub, src, dstp)
  val tree_ok = selftest_session_check_tree()
  val sess_ok = selftest_session_roundtrip(root)
  val () = buf_free(sub); val () = buf_free(src)
  val () = buf_free(one); val () = buf_free(dstp)
in
  (if ieq(move_ok, 1) andalso ieq(tree_ok, 1) andalso ieq(sess_ok, 1) then 1 else 0)
end

fun selftest_draw_doc(fnt: !Font, r: !Rend, doc: !Doc, vault: !Buf, cache: &Cache >> _, scratch: &Buf >> _): void = let
  var py: int = 0
  var pa: int = 0
  val () = draw_nodes(fnt, r, doc, 0, 0, 800, 600, 0, 18, vault, cache, scratch, 0, py, pa, ViewEdit)
  val () = draw_nodes(fnt, r, doc, 0, 0, 800, 600, 0, 18, vault, cache, scratch, 0, py, pa, ViewRead)
  val () = draw_doc(fnt, r, doc, 0, 0, 800, 600, 0, 18, vault, cache, scratch, ViewRead)
in
end

fun selftest_widgets_a(fnt: !Font, r: !Rend, scratch: !Buf): void = let
  val () = ui_draw_border(r, 10, 10, 100, 50, 1, col_line())
  val () = ui_draw_shadow(r, 10, 10, 100, 50, 4)
  val () = ui_draw_icon(fnt, r, UI_ICON_FOLDER, 12, 12, 12, col_accent())
  val () = ui_divider(r, 0, 0, 100, Horizontal)
  val () = ui_badge(fnt, r, 20, 50, "badge", col_bar(), col_accent())
  val () = ui_button(fnt, r, 20, 70, 80, 24, "button", Off, Off)
  val () = ui_hover_label(fnt, r, 20, 100, 80, 20, "hover", Off)
  val () = ui_expander(fnt, r, 20, 125, On, Off)
  val () = ui_scroll_bar(r, 20, 210, 8, 100, Vertical, 500, 100, 50, Off, Off)
  val () = ui_line_edit_draw(fnt, r, 20, 320, 120, 24, scratch, 0, 0, On, "test")
in
end

fun selftest_widgets_b(fnt: !Font, r: !Rend): void = let
  val () = ui_pane_begin(r, 150, 10, 200, 150, col_bg())
  val () = ui_pane_draw_header(fnt, r, 150, 10, 200, "Pane Header", On)
  val () = ui_menu_bar_button(fnt, r, 150, 200, 60, 24, "Menu", On, Off)
  val () = ui_icon_button(fnt, r, UI_ICON_SETTINGS, "Options", 150, 230, 80, 24, Off, Off)
  val () = ui_cell(fnt, r, 150, 260, 160, 20, 0, On, On, UI_ICON_FOLDER, "Doc", "5 kb", On, Off)
  val () = ui_loading_overlay(fnt, r, 800, 600, 50, "Loading", "Please wait...")
  val () = ui_code_slice(fnt, r, 150, 290, 200, 20, 42, "val x = 1", On, On, Off)
  val () = ui_error_label(fnt, r, 150, 315, "Error")
  val () = ui_help_label(fnt, r, 150, 335, "Help")
in
end

fun selftest_draw(r: !Rend, doc: Doc, cache0: Cache, vault: Buf, scratch0: Buf): void = let
  val fnt = font_open()
  val () = rend_begin(r, 800, 600)
  var cache = cache0
  var scratch = scratch0
  val () = selftest_draw_doc(fnt, r, doc, vault, cache, scratch)
  val () = selftest_widgets_a(fnt, r, scratch)
  val () = selftest_widgets_b(fnt, r)
  val () = font_free(fnt)
  val () = doc_free(doc)
  val () = cache_free(cache)
  val () = buf_free(vault)
  val () = buf_free(scratch)
in
end

fun selftest_report(search_ok: Toggle, flow_ok: Toggle, ih: int, chrome_ok: Toggle, files_ok: Toggle): int = let
  val () = print("ui search=")
  val () = print_int(toggle_int(search_ok))
  val () = print(" flow=")
  val () = print_int(toggle_int(flow_ok))
  val () = print(" h=")
  val () = print_int(ih)
  val () = print(" chrome=")
  val () = print_int(toggle_int(chrome_ok))
  val () = print(" files=")
  val () = print_int(toggle_int(files_ok))
  val () = print_newline()
in
  (if is_on(search_ok) andalso is_on(flow_ok) andalso is_on(chrome_ok) andalso is_on(files_ok) then 1 else 0)
end

implement app_selftest(r, root) = let
  var d1 = buf_make(32)
  val () = buffer_append_string(d1, root)
  val search_ok = if ieq(selftest_search(d1),1) andalso ieq(ix_selftest(root),1)
    andalso ieq(selftest_search_ui(r,root),1) then 1 else 0
  val @(flow_ok, ih, doc, cache, vault, scratch) = selftest_flow(r, root)
  val chrome_ok = selftest_tabs(d1)
  val files_ok = if ieq(selftest_files(root),1) andalso ieq(editor_fsm_selftest(),1)
    andalso ieq(selftest_embed_navigation(root),1) then 1 else 0
  val () = selftest_draw(r, doc, cache, vault, scratch)
  val () = buf_free(d1)
in
  selftest_report(toggle_of(ieq(search_ok, 1)), toggle_of(ieq(flow_ok, 1)), ih, toggle_of(ieq(chrome_ok, 1)), toggle_of(ieq(files_ok, 1)))
end
