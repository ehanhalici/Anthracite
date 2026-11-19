fun open_general_context(s: &App_record >> _, f: !Font, r: !Rend, hit: DownHit): void = let
  val () = place_context(s, hit)
  val is_read = is_view_read(s.viewmode)
  val is_img = not(is_read) andalso is_kind(s.hitk, KImage)
  val m = (if is_img then MenuImage else MenuText)
  val mv = (if is_read then MenuVarReadText else if is_img then MenuVarImage else MenuVarEditText): MenuVariant
  val () = font_set_px(f, s.fontpx)
  val mw = imin(imax(40, isub(s.last_w, 8)), menu_var_measure_width(f, r, mv))
  val () = s.menuw := mw
  var mx = s.menux
  var my = s.menuy
  val () = menu_clamp_root(mv, mx, my, mw, s.last_w, s.last_h)
  val () = (s.menux := mx; s.menuy := my)
  val () = s.menu := m
  val () = s.menu_var := mv
  val () = s.menu_sub := SubNone
in
  app_fsm_step(s, ActOpenMenu(m))
end

fun handle_down_context_menu_open(s: &App_record >> _, f: !Font, r: !Rend, hit: DownHit): void =
  if not(is_btn(hit.button, BtnRight)) then ()
  else case+ hit.zone of
    | DownMenu() => ()
    | DownResize() => ()
    | DownSidebar() => open_tree_context(s, f, r, hit)
    | DownTopbar() => ()
    | DownEditor() => open_general_context(s, f, r, hit)

fun transform_down_tabs(
  s: &App_record >> _, p: !Plat, f: !Font, r: !Rend,
  ev: &event, w: int, hit: DownHit, ts0: Tabs, idx: int
): Tabs = let
  var ti: int = ~1
  var close: bool = false
  val tx0 = topbar_tabs_x0(s)
  val mode_bx = topbar_mode_btn_x(w, s.modew)
  val () = handle_down_tab_bar_selection(s, ts0, f, r, hit, tx0, mode_bx, w, ti, close)
  val ts1 = close_clicked_tab_step(s, ts0, ti, toggle_of(close))
  val ts2 = handle_down_sidebar_click(s, f, ts1, ctrl_on(ev), hit)
  val ts3 = handle_editor_click(s, f, r, ts2, ev, w, hit, idx, Off, Off)
  val () = handle_down_context_menu_open(s, f, r, hit)
in
  ts3
end

fun on_down_tabs(s: &App_record >> _, p: !Plat, f: !Font, r: !Rend, ev: &event, w: int, hit: DownHit): void = let
  val ts0 = s.tabs
  val () = s.tabs := TNil()
  val idx = pane_of(s.focus, s.active, s.righti)
  val ts3 = transform_down_tabs(s, p, f, r, ev, w, hit, ts0, idx)
  val ph = s.tabs
  val () = s.tabs := ts3
  val () = tabs_free(ph)
in
  save_app_session(s)
end

fun side_split_hit(s: &App_record, button: Btn, x: int, y: int): bool =
  not(is_side_none(s.side)) andalso is_btn(button, BtnLeft)
    andalso ige(y, s.tb_h)
    andalso ige(x, isub(s.sidew, idiv(UI_SIDEBAR_GRAB_WIDTH, 2)))
    andalso ilt(x, iadd(s.sidew, idiv(UI_SIDEBAR_GRAB_WIDTH, 2)))

fun begin_side_split(s: &App_record >> _, x: int, y: int): void = let
  val () = s.drag := DragSplit
  val () = s.dragi := ~1
  val () = s.downx := x
  val () = app_fsm_step(s, ActStartSplitDrag(x))
in
  s.downy := y
end

fun down_zone(s: &App_record, button: Btn, x: int, y: int, sidew: int): DownZone =
  if not(is_menu_none(s.menu)) then DownMenu
  else if side_split_hit(s, button, x, y) then DownResize
  else if ilt(y, s.tb_h) then DownTopbar
  else if igt(sidew, 0) andalso ilt(x, sidew) then DownSidebar
  else DownEditor

fun down_hit(s: &App_record, ev: &event): DownHit = let
  val x = ev_x(ev)
  val y = ev_y(ev)
  val sidew = if not(is_side_none(s.side)) then s.sidew else 0
  val button = button_of(ev_button(ev))
  val item = idiv(isub(y, s.menuy), UI_MENU_ITEM_HEIGHT)
  val mw = if igt(s.menuw, 0) then s.menuw else UI_MENU_WIDTH
  val inside = ige(x, s.menux) andalso ilt(x, iadd(s.menux, mw)) andalso ige(y, s.menuy)
in
  @{x=x, y=y, sidew=sidew, button=button,
    zone=down_zone(s, button, x, y, sidew), inside=toggle_of(inside), item=item}
end

fun dispatch_menu_down(
  s: &App_record >> _, p: !Plat, f: !Font, r: !Rend,
  ev: &event, w: int, hit: DownHit
): void = let
  val () = seen_int(ev_x(ev)); val () = seen_int(w)
  val ts0 = s.tabs
  val () = s.tabs := TNil()
  val idx = pane_of(s.focus, s.active, s.righti)
  var keep_open: bool = false
  val ts1 = handle_menu_click_v2(s, p, f, r, ts0, idx, hit.x, hit.y, keep_open)
  val ph = s.tabs
  val () = s.tabs := ts1
  val () = tabs_free(ph)
  val () = if not(keep_open) then (
    s.menu := MenuNone; s.menu_sub := SubNone; s.menu_tree_idx := ~1;
    app_fsm_step(s, ActDismissMenu())
  ) else ()
  val () = (s.drag := DragNone; s.downx := ~1; s.downy := ~1)
in
  save_app_session(s)
end

fun dispatch_topbar_down(
  s: &App_record >> _, p: !Plat, f: !Font, r: !Rend,
  ev: &event, w: int, hit: DownHit
): void = let
  val () = handle_topbar_action(s, w, hit.x)
in
  on_down_tabs(s, p, f, r, ev, w, hit)
end

fun dispatch_down_hit(
  s: &App_record >> _, p: !Plat, f: !Font, r: !Rend,
  ev: &event, w: int, hit: DownHit
): void = let
  val () = font_set_px(f, s.fontpx)
in
  case+ hit.zone of
  | DownResize() => begin_side_split(s, hit.x, hit.y)
  | DownMenu() => dispatch_menu_down(s, p, f, r, ev, w, hit)
  | DownTopbar() => dispatch_topbar_down(s, p, f, r, ev, w, hit)
  | DownSidebar() => on_down_tabs(s, p, f, r, ev, w, hit)
  | DownEditor() => on_down_tabs(s, p, f, r, ev, w, hit)
end

fun click_on_rename_row(s: &App_record, x: int, y: int): bool =
  is_prompt_rename(s.prompt) andalso is_side_files(s.side)
    andalso ilt(x, s.sidew) andalso ige(y, tree_top_y_of(s))
    andalso ige(s.sel, 0) andalso ieq(tree_source_at_y(s, y), s.sel)

fun on_down_panes(s: &App_record >> _, p: !Plat, f: !Font, r: !Rend, ev: &event, w: int): void = let
  val hit = down_hit(s, ev)
in
  if click_on_rename_row(s, hit.x, hit.y) andalso is_btn(hit.button, BtnLeft) then ()
  else let
    val () = if is_prompt_rename(s.prompt) then prompt_reset(s) else ()
    val () = s.downx := hit.x
    val () = s.downy := hit.y
  in
    dispatch_down_hit(s, p, f, r, ev, w, hit)
  end
end

fun on_down(a: !App, p: !Plat, f: !Font, r: !Rend, ev: &event, w: int, h: int): void =
  case+ a of
  | @APP(s) =>
      if is_on(s.vault_select) then let
        val () = handle_vault_select_click(s, f, r, ev_x(ev), ev_y(ev), w, h)
      in
        fold@(a)
      end else let
        val () = s.last_w := w
        val () = s.last_h := h
        val () = cache_clear_embed_selection(s.cache)
        val () = on_down_panes(s, p, f, r, ev, w)
      in
        fold@(a)
      end

fun resize_side(s: &App_record >> _, x: int, w: int): void = let
  val max_width = imax(UI_SIDEBAR_MIN_WIDTH, imin(idiv(w, 2), isub(w, 260)))
in
  s.sidew := imax(UI_SIDEBAR_MIN_WIDTH, imin(max_width, x))
end

fun tab_pane_shift_l_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), b: !Buf, cur: int, target: int): void =
  if recursion_fuel_available(recfuel) then (
    if cur < target then let
      val () = buf_set(b, cur, buf_get(b, cur + 1))
    in
      tab_pane_shift_l_with_fuel(recfuel - 1, b, cur + 1, target)
    end else ()
  ) else ()

fun tab_pane_shift_r_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), b: !Buf, cur: int, target: int): void =
  if recursion_fuel_available(recfuel) then (
    if cur > target then let
      val () = buf_set(b, cur, buf_get(b, cur - 1))
    in
      tab_pane_shift_r_with_fuel(recfuel - 1, b, cur - 1, target)
    end else ()
  ) else ()

fun tab_pane_move(b: !Buf, from_i: int, to_i: int): void = let
  val n = buf_len(b)
in
  if from_i >= 0 andalso from_i < n andalso to_i >= 0 andalso to_i < n andalso ine(from_i, to_i) then let
    val p = buf_get(b, from_i)
    val () = if from_i < to_i then tab_pane_shift_l_with_fuel(airlock_nat(MAX_REC_FUEL), b, from_i, to_i)
             else tab_pane_shift_r_with_fuel(airlock_nat(MAX_REC_FUEL), b, from_i, to_i)
    val () = buf_set(b, to_i, p)
  in
  end else ()
end

fun reorder_index(idx: int, from_i: int, to_i: int): int =
  if ieq(idx, from_i) then to_i
  else if from_i < to_i then (
    if idx > from_i andalso idx <= to_i then isub(idx, 1) else idx
  ) else (
    if idx >= to_i andalso idx < from_i then iadd(idx, 1) else idx
  )

fun app_reorder_tab(s: &App_record >> _, from_i: int, to_i: int): void = let
  val ts = s.tabs
  val () = s.tabs := TNil()
  val ts2 = tabs_move(ts, from_i, to_i)
  val ph = s.tabs
  val () = s.tabs := ts2
  val () = tabs_free(ph)
  val () = tab_pane_move(s.tab_pane, from_i, to_i)
  val () = app_move_tab_hist(s, from_i, to_i)
  val () = s.active := reorder_index(s.active, from_i, to_i)
  val () = s.righti := reorder_index(s.righti, from_i, to_i)
  val () = s.dragi := to_i
in
  save_app_session(s)
end
