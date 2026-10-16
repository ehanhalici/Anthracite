fun draw_side_body(f: !Font, r: !Rend, s: &App_record, h: int): void =
  if is_side_search(s.side) then draw_sidebar_search(f, r, s, s.sidew)
  else if is_side_files(s.side) then draw_sidebar_files(f, r, s, s.sidew, h)
  else draw_sidebar_config(f, r, s)

fun draw_side(f: !Font, r: !Rend, a: !App, h: int): void =
  case+ a of
  | @APP(s) => let
      val () = draw_side_frame(r, s.sidew, h)
      val () = draw_side_title(f, r, s.side)
      val () = ensure_tree_fresh(s)
      val () = draw_side_body(f, r, s, h)
      val () = rend_scissor_off(r)
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
  ige(s.hoverx, x) andalso ilt(s.hoverx, iadd(x, bw)) andalso ige(s.hovery, 0) andalso ilt(s.hovery, UI_TOPBAR_HEIGHT)

fun draw_topbar_side_buttons(f: !Font, r: !Rend, s: &App_record): void = let
  val bw = s.btnw
  val x1 = topbar_btn_x(0, bw)
  val x2 = topbar_btn_x(1, bw)
  val x3 = topbar_btn_x(2, bw)
  val () = ui_icon_button(f, r, UI_ICON_FOLDER, "Gezgin", x1, 0, bw, UI_TOPBAR_HEIGHT, toggle_of(is_side_files(s.side)), toggle_of(bar_hovered(s, x1, bw)))
  val () = ui_icon_button(f, r, UI_ICON_SEARCH, "Arama", x2, 0, bw, UI_TOPBAR_HEIGHT, toggle_of(is_side_search(s.side)), toggle_of(bar_hovered(s, x2, bw)))
  val () = ui_icon_button(f, r, UI_ICON_SETTINGS, "Ayarlar", x3, 0, bw, UI_TOPBAR_HEIGHT, toggle_of(is_side_config(s.side)), toggle_of(bar_hovered(s, x3, bw)))
in
end

fun draw_topbar_chrome(f: !Font, r: !Rend, s: &App_record, w: int): void = let
  val tab_sep_x = imul(3, s.btnw)
  val () = rend_rect(r, 0, 0, w, UI_TOPBAR_HEIGHT, col_bar())
  val () = ui_divider(r, 0, 35, w, Horizontal)
  val () = draw_topbar_side_buttons(f, r, s)
  val () = ui_divider(r, tab_sep_x, 0, UI_TOPBAR_HEIGHT, Vertical)
in
  seen_int(w)
end

fun draw_topbar_mode(f: !Font, r: !Rend, s: &App_record, w: int): void = let
  val text = if is_view_edit(s.viewmode) then "Düzenle" else "Okuma"
  val bx = topbar_mode_btn_x(w, s.modew)
  val hover = bar_hovered(s, bx, s.modew)
in
  ui_button(f, r, bx, 4, s.modew, 28, text,
    toggle_of(hover), toggle_of(is_view_edit(s.viewmode)))
end

fun apply_jump_if(ts: Tabs, act: int, jline: int, jcol: int): Tabs =
  if ige(jline, 0) then tabs_jump(ts, act, jline, jcol) else ts


fun validate_pane_left(s: &App_record >> _, n: int): void = let
  val act_ok = ige(s.active, 0) andalso ilt(s.active, n) andalso ieq(buf_get(s.tab_pane, s.active), 0)
in
  if not(act_ok) then let
    val f_left = tab_pane_find_first(s.tab_pane, 0)
    val () = if ige(f_left, 0) then s.active := f_left else ()
  in end else ()
end

fun validate_pane_right(s: &App_record >> _, n: int): void = let
  val right_ok = ige(s.righti, 0) andalso ilt(s.righti, n) andalso ieq(buf_get(s.tab_pane, s.righti), 1)
in
  if not(right_ok) then let
    val f_right = tab_pane_find_first(s.tab_pane, 1)
    val () = if ige(f_right, 0) then s.righti := f_right else ()
  in end else ()
end

fun validate_panes_len(s: &App_record >> _, n: int): void = let
  val () = if buf_len(s.tab_pane) < n then sync_tab_pane(s.tab_pane, n, s.split, s.righti) else ()
  val has_right = tab_pane_has(s.tab_pane, 1)
  val has_left = tab_pane_has(s.tab_pane, 0)
in
  if is_on(s.split) then (
    if not(has_right) orelse not(has_left) then (
      s.split := Off; s.focus := Off; tab_pane_fill_all(s.tab_pane, n, 0)
    ) else (validate_pane_left(s, n); validate_pane_right(s, n))
  ) else ()
end

fun draw_split_tabs(f: !Font, r: !Rend, ts: Tabs, tab_x0: int, mid: int, bx: int, act: int, righti: int, tab_pane: !Buf): Tabs = let
  val () = rend_scissor(r, tab_x0, 0, isub(mid, tab_x0), UI_TOPBAR_HEIGHT)
  val ts_l = draw_tabrow_pane(f, r, ts, tab_x0, act, 0, 0, tab_pane)
  val () = rend_scissor_off(r)
  val () = rend_scissor(r, iadd(mid, 4), 0, isub(bx, mid), UI_TOPBAR_HEIGHT)
  val ts_r = draw_tabrow_pane(f, r, ts_l, iadd(mid, 4), righti, 0, 1, tab_pane)
  val () = rend_scissor_off(r)
in
  ts_r
end

fun choose_tabrow(f: !Font, r: !Rend, ts: Tabs, tab_x0: int, mid: int, bx: int, s: &App_record): Tabs =
  if is_on(s.split) then draw_split_tabs(f, r, ts, tab_x0, mid, bx, s.active, s.righti, s.tab_pane)
  else draw_tabrow_pane(f, r, ts, tab_x0, pane_of(s.focus, s.active, s.righti), 0, ~1, s.tab_pane)

fun draw_editor_panes(f: !Font, r: !Rend, s: &App_record >> _, ox: int, half: int, w: int, h: int, lh: int): void = let
  val tab_x0 = topbar_tab_start_x(s.btnw)
  val ts0 = s.tabs
  val () = s.tabs := TNil()
  val ts = apply_jump_if(ts0, s.active, s.jump_line, s.jump_col)
  val () = if ige(s.jump_line, 0) then (s.jump_line := ~1; s.jump_col := ~1) else ()
  val mid = iadd(ox, half)
  val bx = topbar_mode_btn_x(w, s.modew)
  val () = sync_tab_pane(s.tab_pane, tabs_len(ts), s.split, s.righti)
  val () = validate_panes_len(s, tabs_len(ts))
  val ts2 = choose_tabrow(f, r, ts, tab_x0, mid, bx, s)
  val ts3 = draw_focus(f, r, ts2, s.active, ox, UI_TOPBAR_HEIGHT, half, isub(h, UI_TOPBAR_HEIGHT), lh, s.vault, s.cache, s.scratch, 0, s.viewmode)
  val ts4 = draw_right(f, r, ts3, s.split, s.righti, mid, UI_TOPBAR_HEIGHT, half, isub(h, UI_TOPBAR_HEIGHT), lh, s.vault, s.cache, s.scratch, s.viewmode)
  val ph = s.tabs
  val () = s.tabs := ts4
  val () = tabs_free(ph)
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
    val () = font_load_report(f, buffer_c_string(s.font_path))
    val () = font_set_px(f, s.fontpx)
    val () = s.font_idx := 1
    val () = s.btnw := 0
  in
    ()
  end else ()

