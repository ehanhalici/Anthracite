fun draw_side_body(f: !Font, r: !Rend, s: &App_record, h: int): void =
  if is_side_search(s.side) then draw_sidebar_search(f, r, s, s.sidew,h)
  else if is_side_files(s.side) then draw_sidebar_files(f, r, s, s.sidew, h)
  else draw_sidebar_config(f, r, s)

fun draw_side(f: !Font, r: !Rend, a: !App, h: int): void =
  case+ a of
  | @APP(s) => let
      val () = font_set_px(f, s.fontpx)
      val () = draw_side_frame(r, s, h)
      val () = if is_side_search(s.side) then () else draw_side_title(f, r, s)
      val () = ensure_tree_fresh(s)
      val () = draw_side_body(f, r, s, h)
      val () = rend_clip_pop(r)
    in
      fold@(a)
    end

fun ui_draw_menu(f: !Font, r: !Rend, a: !App): void =
  case+ a of
  | @APP(s) => let
      val () = draw_menu(f, r, s.menu, s.menux, s.menuy, s.menuw)
    in
      fold@(a)
    end

fun label_px(f: !Font, r: !Rend, text: string): int =
  font_width(f, r, c_str_ptr(text), c_strlen(text))

fun wider(a: int, b: int): int =
  if igt(a, b) then a else b

fun icon_slot(f: !Font, r: !Rend, text: string): int =
  iadd(label_px(f, r, text), 44)

fun side_btn_width(f: !Font, r: !Rend): int =
  wider(icon_slot(f, r, "Ayarlar"), wider(icon_slot(f, r, "Gezgin"), icon_slot(f, r, "Arama")))

fun mode_slot(f: !Font, r: !Rend, text: string): int =
  iadd(label_px(f, r, text), 28)

fun mode_btn_width(f: !Font, r: !Rend): int =
  wider(mode_slot(f, r, "Düzenle"), mode_slot(f, r, "Okuma"))

fun menu_slot(f: !Font, r: !Rend, text: string): int =
  iadd(label_px(f, r, text), 36)

fun menu_w_pair(f: !Font, r: !Rend, a: string, b: string): int =
  wider(menu_slot(f, r, a), menu_slot(f, r, b))

fun menu_w_text(f: !Font, r: !Rend): int =
  wider(menu_slot(f, r, "Biçimlendirmeyi Temizle"), menu_w_pair(f, r, "Yapıştır", "Kopyala"))

fun menu_w_image(f: !Font, r: !Rend): int =
  wider(menu_slot(f, r, "Dokümandan Kaldır"), menu_w_pair(f, r, "Dosya Konumunu Aç", "Görseli Kopyala"))

fun menu_w_tree(f: !Font, r: !Rend): int =
  wider(menu_w_pair(f, r, "Yeni Klasör Oluştur", "Yeni Dosya Oluştur"), menu_w_pair(f, r, "Yeniden Adlandır", "Sil"))

fun menu_width(f: !Font, r: !Rend): int =
  wider(UI_MENU_WIDTH, wider(menu_w_text(f, r), wider(menu_w_image(f, r), menu_w_tree(f, r))))

fun ensure_chrome(f: !Font, r: !Rend, s: &App_record >> _): void =
  if igt(s.btnw, 0) then ()
  else let
    val () = font_set_px(f, s.fontpx)
    val lh = font_line_h(f)
    val () = s.tb_h := chrome_topbar_h(lh)
    val () = s.hdr_h := chrome_hdr_h(lh)
    val () = s.btnw := side_btn_width(f, r)
    val () = s.modew := mode_btn_width(f, r)
  in
    s.menuw := menu_width(f, r)
  end

fun topbar_btn_x(idx: int, btnw: int): int =
  imul(idx, btnw)

fun topbar_tab_start_x(btnw: int): int =
  iadd(imul(3, btnw), 8)

fun topbar_mode_btn_x(w: int, modew: int): int =
  isub(w, iadd(modew, 10))

fun bar_hovered(s: &App_record, x: int, bw: int): bool =
  ige(s.hoverx, x) andalso ilt(s.hoverx, iadd(x, bw)) andalso ige(s.hovery, 0) andalso ilt(s.hovery, s.tb_h)

fun draw_topbar_side_buttons(f: !Font, r: !Rend, s: &App_record): void = let
  val bw = s.btnw
  val th = s.tb_h
  val x1 = topbar_btn_x(0, bw)
  val x2 = topbar_btn_x(1, bw)
  val x3 = topbar_btn_x(2, bw)
  val () = ui_icon_button(f, r, UI_ICON_FOLDER, "Gezgin", x1, 0, bw, th, toggle_of(is_side_files(s.side)), toggle_of(bar_hovered(s, x1, bw)))
  val () = ui_icon_button(f, r, UI_ICON_SEARCH, "Arama", x2, 0, bw, th, toggle_of(is_side_search(s.side)), toggle_of(bar_hovered(s, x2, bw)))
  val () = ui_icon_button(f, r, UI_ICON_SETTINGS, "Ayarlar", x3, 0, bw, th, toggle_of(is_side_config(s.side)), toggle_of(bar_hovered(s, x3, bw)))
in
end

fun draw_topbar_chrome(f: !Font, r: !Rend, s: &App_record, w: int): void = let
  val tab_sep_x = imul(3, s.btnw)
  val th = s.tb_h
  val () = rend_rect(r, 0, 0, w, th, col_bar())
  val () = ui_divider(r, 0, isub(th, 1), w, Horizontal)
  val () = draw_topbar_side_buttons(f, r, s)
  val () = ui_divider(r, tab_sep_x, 0, th, Vertical)
  val () = if not(is_side_none(s.side)) andalso igt(s.sidew, tab_sep_x) then
    ui_divider(r, isub(s.sidew, 1), 0, th, Vertical)
  else ()
in
  seen_int(w)
end

fun draw_chord_badge_buf(f: !Font, r: !Rend, th: int, bx: int, cb: !Buf): void = let
  val cblen = buf_len(cb)
  val cw = iadd(font_width_buf(f, r, cb, cblen), 14)
  val cx = isub(bx, iadd(cw, 8))
  val cy = imax(2, idiv(isub(th, imax(16, font_line_h(f))), 2))
in
  ui_badge(f, r, cx, cy, buffer_c_string(cb), col_side(), col_accent())
end

fun draw_chord_badge(f: !Font, r: !Rend, th: int, bx: int, mods: int, key: int): void = let
  var cb = buf_make(32)
  val () = keymap_format_chord(mods, key, cb)
  val () = buffer_append_string(cb, " ...")
  val () = draw_chord_badge_buf(f, r, th, bx, cb)
in
  buf_free(cb)
end

fun draw_topbar_mode(f: !Font, r: !Rend, s: &App_record, w: int): void = let
  val text = if is_view_edit(s.viewmode) then "Düzenle" else "Okuma"
  val bx = topbar_mode_btn_x(w, s.modew)
  val hover = bar_hovered(s, bx, s.modew)
  val () = if is_on(s.chord_active) then draw_chord_badge(f, r, s.tb_h, bx, s.chord_mods, s.chord_key) else ()
in
  ui_button(f, r, bx, 4, s.modew, isub(s.tb_h, 8), text,
    toggle_of(hover), toggle_of(is_view_edit(s.viewmode)))
end

fun apply_jump_if(ts: Tabs, act: int, jline: int, jcol: int): Tabs =
  if ige(jline, 0) then tabs_jump(ts, act, jline, jcol) else ts

fun draw_split_tabs(f: !Font, r: !Rend, ts: Tabs, th: int, tab_x0: int, mid: int, bx: int, act: int, righti: int, tab_pane: !Buf): Tabs = let
  val left_w = imax(40, isub(isub(mid, 4), tab_x0))
  val () = rend_clip_push(r, tab_x0, 0, left_w, th)
  val ts_l = draw_tabrow_pane_w(f, r, ts, tab_x0, left_w, act, 0, 0, tab_pane)
  val () = rend_clip_pop(r)
  val right_x0 = iadd(mid, 4)
  val right_w = imax(40, isub(isub(bx, 6), right_x0))
  val () = rend_clip_push(r, right_x0, 0, right_w, th)
  val ts_r = draw_tabrow_pane_w(f, r, ts_l, right_x0, right_w, righti, 0, 1, tab_pane)
  val () = rend_clip_pop(r)
in
  ts_r
end

fun choose_tabrow(f: !Font, r: !Rend, ts: Tabs, tab_x0: int, mid: int, bx: int, s: &App_record): Tabs =
  if is_on(s.split) then draw_split_tabs(f, r, ts, s.tb_h, tab_x0, mid, bx, s.active, s.righti, s.tab_pane)
  else let
    val avail_w = imax(60, isub(isub(bx, 6), tab_x0))
    val () = rend_clip_push(r, tab_x0, 0, avail_w, s.tb_h)
    val ts_out = draw_tabrow_pane_w(f, r, ts, tab_x0, avail_w, pane_of(s.focus, s.active, s.righti), 0, ~1, s.tab_pane)
    val () = rend_clip_pop(r)
  in
    ts_out
  end

fun draw_pane_scroll_hover(s: &App_record, ox: int, pw: int): bool =
  ige(s.hoverx, isub(iadd(ox, pw), UI_SCROLLBAR_HIT_WIDTH)) andalso ilt(s.hoverx, iadd(ox, pw))
    andalso ige(s.hovery, s.doc_top_y)

fun draw_editor_right_pane(
  f: !Font, r: !Rend, s: &App_record >> _, ts: Tabs, mid: int, rw: int, h: int
): Tabs =
  if is_on(s.split) then let
    val () = font_set_px(f, s.fontpx)
    val () = draw_pane_header(f, r, s, ts, mid, rw, s.righti, s.focus)
    val () = font_set_px(f, s.doc_fontpx)
    val doc_lh = font_line_h(f)
    val doc_oy = doc_content_top_y(doc_top_y_of(s), doc_lh)
    val doc_ph = imax(1, isub(h, doc_oy))
    val () = draw_pane_doc_title(f, r, s, ts, mid, rw, s.righti, doc_lh)
    val r_hov = draw_pane_scroll_hover(s, mid, rw)
    val r_drag = is_drag_doc_scroll(s.drag) andalso ieq(s.scroll_drag_pane, 1)
    var rh: int = 0
    val ts_out = draw_focus_pane(f, r, ts, s.righti, mid, doc_oy, rw, doc_ph, doc_lh, s.vault, s.cache, s.scratch, 0, s.viewmode, toggle_of(r_hov), toggle_of(r_drag), rh)
    val () = s.doc_h_right := rh
  in
    ts_out
  end else (s.doc_h_right := 0; ts)

fun draw_editor_left_pane(
  f: !Font, r: !Rend, s: &App_record >> _, ts2: Tabs, ox: int, half: int, h: int
): Tabs = let
  val active_left = toggle_of(not(is_on(s.split)) orelse is_off(s.focus))
  val () = font_set_px(f, s.fontpx)
  val () = draw_pane_header(f, r, s, ts2, ox, half, s.active, active_left)
  val () = font_set_px(f, s.doc_fontpx)
  val doc_lh = font_line_h(f)
  val doc_oy = doc_content_top_y(doc_top_y_of(s), doc_lh)
  val doc_ph = imax(1, isub(h, doc_oy))
  val () = s.doc_top_y := doc_oy
  val () = s.doc_vh := doc_ph
  val () = draw_pane_doc_title(f, r, s, ts2, ox, half, s.active, doc_lh)
  val l_hov = draw_pane_scroll_hover(s, ox, half)
  val l_drag = is_drag_doc_scroll(s.drag) andalso ieq(s.scroll_drag_pane, 0)
  var lh_total: int = 0
  val ts3 = draw_focus_pane(f, r, ts2, s.active, ox, doc_oy, half, doc_ph, doc_lh, s.vault, s.cache, s.scratch, 0, s.viewmode, toggle_of(l_hov), toggle_of(l_drag), lh_total)
  val () = s.doc_h_left := lh_total
in
  ts3
end

fun consume_editor_jump(s: &App_record >> _, ts0: Tabs): Tabs = let
  val ts = apply_jump_if(ts0, pane_of(s.focus, s.active, s.righti), s.jump_line, s.jump_col)
  val () = if ige(s.jump_line, 0) then (
    s.flash_until_ns := mono_ns() + UI_NAVIGATION_FLASH_NS;
    s.editor_focused := On;
    s.cursor_pane := (if is_on(s.split) andalso is_on(s.focus) then 1 else 0)
  ) else ()
  val () = if ige(s.jump_line, 0) then (s.jump_line := ~1; s.jump_col := ~1) else ()
in
  ts
end

fun draw_editor_panes(f: !Font, r: !Rend, s: &App_record >> _, ox: int, half: int, w: int, h: int, lh: int): void = let
  val () = seen_int(lh)
  val ts0 = s.tabs; val () = s.tabs := TNil()
  val ts = consume_editor_jump(s, ts0)
  val mid = iadd(ox, half)
  val right_w = imax(1, isub(w, mid))
  val () = sync_tab_pane(s.tab_pane, tabs_len(ts), s.split, s.righti)
  val () = validate_panes_len(s, tabs_len(ts))
  val () = app_sync_tab_hists(s, ts)
  val c_idx = if is_on(s.editor_focused) then (if is_on(s.split) andalso ieq(s.cursor_pane, 1) then s.righti else s.active) else ~1
  val () = tabs_sync_cursor_focus(ts, is_on(s.editor_focused), c_idx)
  val ts2 = choose_tabrow(f, r, ts, topbar_tabs_x0(s), mid, topbar_mode_btn_x(w, s.modew), s)
  val ts3 = draw_editor_left_pane(f, r, s, ts2, ox, half, h)
  val ts4 = draw_editor_right_pane(f, r, s, ts3, mid, right_w, h)
  val ph = s.tabs; val () = s.tabs := ts4; val () = tabs_free(ph)
  val () = font_set_px(f, s.fontpx)
in
  if is_on(s.split) then ui_divider(r, mid, 0, h, Vertical) else ()
end

fun font_load_report(f: !Font, path: string): void =
  if font_use_file(f, path) then () else report_failure("font_load", path)

(* Klasor zaten varsa basarilidir; mkdir hatasi yalnizca klasor yoksa raporlanir. *)
fun ensure_dir_report(path: string): void =
  if path_is_dir(path) then ()
  else if ieq(fs_mkdir(path), 0) then ()
  else report_failure("vault_dir_create", path)

fun load_font_if_needed(f: !Font, s: &App_record): void =
  if ieq(s.font_idx, 0) andalso igt(buf_len(s.font_path), 0) then let
    val () = if not(ends(s.font_path, "SourceCodePro-Regular.ttf")) then
      font_load_report(f, buffer_c_string(s.font_path))
    else ()
    val () = font_set_px(f, s.fontpx)
    val () = s.font_idx := 1
    val () = s.btnw := 0
  in
    ()
  end else ()
