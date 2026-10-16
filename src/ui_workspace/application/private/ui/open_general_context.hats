fun open_general_context(s: &App_record >> _, hit: DownHit): void = let
  val () = place_context(s, hit)
  val m = (if is_kind(s.hitk, KImage) then MenuImage else MenuText)
  val () = s.menu := m
  val () = app_fsm_step(s, ActOpenMenu(m))
in
end

fun handle_down_context_menu_open(s: &App_record >> _, hit: DownHit): void =
  if not(is_btn(hit.button, BtnRight)) then ()
  else case+ hit.zone of
    | DownMenu() => ()
    | DownResize() => ()
    | DownSidebar() => (
        place_context(s, hit); open_tree_context(s, hit)
      )
    | DownTopbar() => open_general_context(s, hit)
    | DownEditor() => open_general_context(s, hit)

fun transform_down_tabs(
  s: &App_record >> _, p: !Plat, f: !Font, r: !Rend,
  ev: &event, w: int, hit: DownHit, ts0: Tabs, idx: int
): Tabs = let
  var ti: int = ~1
  var close: bool = false
  val () = handle_down_tab_bar_selection(s, ts0, f, r, hit,
    topbar_tab_start_x(s.btnw), topbar_mode_btn_x(w, s.modew), w, ti, close)
  var imgdel: Toggle = Off
  var clear: Toggle = Off
  val ts1 = handle_down_context_menu(s, p, ts0, idx, hit,
    ti, toggle_of(close), imgdel, clear)
  val ts2 = handle_down_sidebar_click(s, f, ts1, hit)
  val ts3 = handle_editor_click(s, f, r, ts2, ev, w, hit, idx, imgdel, clear)
  val () = handle_down_context_menu_open(s, hit)
  val room = imax(0, isub(w, s.menuw))
  val () = if igt(s.menux, room) then s.menux := room else ()
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
  val () = case+ hit.zone of
    | DownMenu() => (s.menu := MenuNone; app_fsm_step(s, ActDismissMenu()))
    | DownResize() => () | DownTopbar() => ()
    | DownSidebar() => () | DownEditor() => ()
  val () = save_app_session(s)
in
end

fun side_split_hit(s: &App_record, button: Btn, x: int, y: int): bool =
  not(is_side_none(s.side)) andalso is_btn(button, BtnLeft)
    andalso ige(y, UI_TOPBAR_HEIGHT)
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
  else if ilt(y, UI_TOPBAR_HEIGHT) then DownTopbar
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
  val () = handle_context_menu_action(s, hit.inside, hit.item)
in
  on_down_tabs(s, p, f, r, ev, w, hit)
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

fun on_down_panes(s: &App_record >> _, p: !Plat, f: !Font, r: !Rend, ev: &event, w: int): void = let
  val hit = down_hit(s, ev)
  val () = s.downx := hit.x
  val () = s.downy := hit.y
in
  dispatch_down_hit(s, p, f, r, ev, w, hit)
end

fun on_down(a: !App, p: !Plat, f: !Font, r: !Rend, ev: &event, w: int, h: int): void =
  case+ a of
  | @APP(s) =>
      if is_on(s.vault_select) then let
        val () = handle_vault_select_click(s, ev_x(ev), ev_y(ev), w, h)
      in
        fold@(a)
      end else let
        val () = on_down_panes(s, p, f, r, ev, w)
      in
        fold@(a)
      end

fun resize_side(s: &App_record >> _, x: int, w: int): void = let
  val max_width = imax(UI_SIDEBAR_MIN_WIDTH, idiv(w, 2))
in
  s.sidew := imax(UI_SIDEBAR_MIN_WIDTH, imin(max_width, x))
end

fun tab_pane_shift_l_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), b: !Buf, cur: int, target: int): void =
  if recfuel > 0 then (
    if cur < target then let
      val () = buf_set(b, cur, buf_get(b, cur + 1))
    in
      tab_pane_shift_l_with_fuel(recfuel - 1, b, cur + 1, target)
    end else ()
  ) else ()

fun tab_pane_shift_r_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), b: !Buf, cur: int, target: int): void =
  if recfuel > 0 then (
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
  val () = s.active := reorder_index(s.active, from_i, to_i)
  val () = s.righti := reorder_index(s.righti, from_i, to_i)
  val () = s.dragi := to_i
in
  save_app_session(s)
end

