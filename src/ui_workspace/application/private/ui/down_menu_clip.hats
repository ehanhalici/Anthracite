fun down_menu_clip(s: &App_record >> _, p: !Plat, ts0: !Tabs, idx: int, cut: Toggle, copy: Toggle, imgcopy: Toggle, paste: Toggle, imgrev: Toggle): void = let
  val () = copy_if(ts0, idx, s.clip, toggle_of(is_on(cut) orelse is_on(copy)))
  val () = if is_on(copy) andalso ieq(buf_len(s.clip), 0) andalso ige(s.hiti, 0) then
    copy_fallback_node_with_fuel(airlock_nat(MAX_REC_FUEL), ts0, idx, s.hiti, s.clip)
  else ()
  val () = clip_image(ts0, idx, s.hiti, s.vault, s.clip, imgcopy)
  val own = is_on(cut) orelse is_on(copy) orelse is_on(imgcopy)
  val () = if own then plat_own(p, false) else ()
  val () = if own then plat_own(p, true) else ()
  val () = if is_on(paste) then let
      val () = s.paste := On
    in
      plat_paste(p, false)
    end else ()
  val () = if is_on(imgrev) then s.side := SideFiles else ()
in
end


fun tab_pane_del_at_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), b: !Buf, i: int, n: int): void =
  if recursion_fuel_available(recfuel) then (
    if i < isub(n, 1) then let
      val () = buf_set(b, i, buf_get(b, i + 1))
    in
      tab_pane_del_at_with_fuel(recfuel - 1, b, i + 1, n)
    end else ()
  ) else ()

fun tab_pane_del_at(b: !Buf, ti: int): void = let
  val n = buf_len(b)
in
  if ti >= 0 andalso ti < n then let
    val () = tab_pane_del_at_with_fuel(airlock_nat(MAX_REC_FUEL), b, ti, n)
    val () = buf_set_len(b, isub(n, 1))
  in
  end else ()
end

fun down_menu_close(s: &App_record >> _, ts2: !Tabs, ti: int): void = let
  val () = tab_pane_del_at(s.tab_pane, ti)
  val n = tabs_len(ts2)
  val () = if ilt(s.active, 0) orelse ige(s.active, n) then s.active := 0 else ()
  val () = if ilt(s.righti, 0) orelse ige(s.righti, n) then s.righti := 0 else ()
  val () = validate_panes_len(s, n)
  val () = if ieq(ti, s.preview_tab) then s.preview_tab := ~1
           else if ilt(ti, s.preview_tab) then s.preview_tab := isub(s.preview_tab, 1)
           else ()
in
  save_app_session(s)
end

fun handle_down_context_menu(
  s: &App_record >> _, p: !Plat, ts0: Tabs, idx: int, hit: DownHit,
  ti: int, close: Toggle,
  imgdel: &Toggle >> _, clear: &Toggle >> _
): Tabs = let
  val cut = text_item_hit(s, hit, TextCut)
  val copy = text_item_hit(s, hit, TextCopy)
  val paste = text_item_hit(s, hit, TextPaste)
  val () = clear := toggle_of(text_item_hit(s, hit, TextClear))
  val imgcopy = image_item_hit(s, hit, ImageCopy)
  val imgrev = image_item_hit(s, hit, ImageReveal)
  val () = imgdel := toggle_of(image_item_hit(s, hit, ImageDelete))
  val () = down_menu_clip(s, p, ts0, idx, toggle_of(cut), toggle_of(copy), toggle_of(imgcopy), toggle_of(paste), toggle_of(imgrev))
  val ts1 = cmd_if(ts0, idx, CMD_CUT, toggle_of(cut))
  val ts2 = tab_keep_one(drop_if(ts1, ti, close), close)
  val () = if is_on(close) then down_menu_close(s, ts2, ti) else ()
in
  ts2
end

fun down_select_tree_row(s: &App_record >> _, row: int, valid_row: Toggle): void = let
  val () = s.sel := (if is_on(valid_row) then row else ~1)
  val () = s.drag := (if is_on(valid_row) then DragFile else DragNone)
  val () = s.dragi := (if is_on(valid_row) then row else ~1)
in
end

fun tree_open_existing(s: &App_record >> _, ts: Tabs, existing: int, is_double: bool): Tabs = let
  val () = if is_double then (
    if ieq(existing, s.preview_tab) then s.preview_tab := ~1 else ()
  ) else ()
  val () = if is_double then s.last_tree_row := ~1 else ()
  val pane = if ilt(existing, buf_len(s.tab_pane)) then buf_get(s.tab_pane, existing) else 0
  val () = if ieq(pane, 1) then (s.righti := existing; s.focus := On)
           else (s.active := existing; s.focus := Off)
  val () = sync_open_dirs_from_tree(s)
  val () = sync_tab_pane(s.tab_pane, tabs_len(ts), s.split, s.righti)
  val side_open = (if is_side_none(s.side) then 0 else 1)
  val () = save_session_impl(s.vault, s.font_path, s.fontpx, s.viewmode, s.split, s.active, s.righti, side_open, s.sidew, s.tab_pane, s.open_dirs, ts)
in
  ts
end

fun tree_open_new_preview(s: &App_record >> _, ts: Tabs, path: Buf): Tabs = let
  val n = tabs_len(ts)
  val has_prev = ige(s.preview_tab, 0) andalso ilt(s.preview_tab, n)
  val target = if has_prev then s.preview_tab else ~1
  val res = tabs_open_at(ts, target, path)
  val act = if has_prev then target else isub(tabs_len(res), 1)
  val () = s.active := act
  val () = s.preview_tab := act
  val () = sync_open_dirs_from_tree(s)
  val () = sync_tab_pane(s.tab_pane, tabs_len(res), s.split, s.righti)
  val side_open = (if is_side_none(s.side) then 0 else 1)
  val () = save_session_impl(s.vault, s.font_path, s.fontpx, s.viewmode, s.split, s.active, s.righti, side_open, s.sidew, s.tab_pane, s.open_dirs, res)
in
  res
end

fun tree_open_new_pinned(s: &App_record >> _, ts: Tabs, path: Buf): Tabs = let
  val res = tabs_open(ts, path)
  val act = isub(tabs_len(res), 1)
  val () = s.active := act
  val () = s.preview_tab := ~1
  val () = s.last_tree_row := ~1
  val () = sync_open_dirs_from_tree(s)
  val () = sync_tab_pane(s.tab_pane, tabs_len(res), s.split, s.righti)
  val side_open = (if is_side_none(s.side) then 0 else 1)
  val () = save_session_impl(s.vault, s.font_path, s.fontpx, s.viewmode, s.split, s.active, s.righti, side_open, s.sidew, s.tab_pane, s.open_dirs, res)
in
  res
end

fun tree_open_file(s: &App_record >> _, ts: Tabs, row: int, is_double: bool): Tabs = let
  var cur = buf_make(TREE_OPEN_FILE_CUR_INITIAL_BYTES)
  val () = row_path(s.tree, s.tmeta, row, cur)
  val existing = tabs_find_path(ts, cur)
in
  if ige(existing, 0) then let
    val () = buf_free(cur)
  in
    tree_open_existing(s, ts, existing, is_double)
  end else if is_double then
    tree_open_new_pinned(s, ts, cur)
  else
    tree_open_new_preview(s, ts, cur)
end

fun handle_tree_click(s: &App_record >> _, ts: Tabs, x: int, y: int): Tabs = let
  val row = tree_source_at_y(s, y)
  val valid_row = ige(row, 0) andalso ilt(row, s.tn)
  val on_expander = valid_row andalso tree_expander_hit(s, row, x)
  val is_file = valid_row andalso not(on_expander) andalso is_dir_mark(meta_dir(s.tmeta, row), DirNo)
  val now = mono_ns()
  val dt = now - s.last_tree_time
  val is_double = valid_row andalso ieq(row, s.last_tree_row) andalso (dt < 400000000L)
  val () = s.last_tree_row := (if valid_row then row else ~1)
  val () = s.last_tree_time := (if valid_row then now else 0L)
  val () = down_select_tree_row(s, row, toggle_of(valid_row))
  val () = if on_expander then tree_toggle_source(s, row) else ()
in
  if is_file then tree_open_file(s, ts, row, is_double) else ts
end

fun search_result_click(s: &App_record >> _,ts: Tabs,row: int): Tabs =
  if ilt(row,0) orelse ige(row,s.hn) then ts else if search_row_is_header(s.hmeta,row) then let
    val toggled=search_toggle_group(s.hmeta,s.ixq,row)
  in ts end else let val ()=s.qfocus := Off in open_hit(s,ts,row,On) end
fun handle_search_click(s: &App_record >> _, ts: Tabs, x: int, y: int): Tabs = let
  val scope=search_scope_hit(s.search_layout,x,y)
in if ige(scope,0) then let
    val ()=if ine(s.scope,scope) then (s.scope := scope; run_query_refresh(s)) else ()
  in ts end else if ige(y,s.search_layout.queryTop) andalso ilt(y,iadd(s.search_layout.queryTop,s.search_layout.queryHeight)) then
    let val ()=s.qfocus := On in ts end
  else let val visible=search_visible_hit(s.search_layout,y,s.hscroll)
    val row=search_source_row(s.hmeta,s.ixq,visible)
  in search_result_click(s,ts,row) end end

fun handle_config_click(s: &App_record >> _, f: !Font, ts: Tabs, x: int, y: int): Tabs = let
  val () = handle_sidebar_config_action(s, f, x, y)
in
  ts
end

fun handle_down_sidebar_click(
  s: &App_record >> _, f: !Font, ts: Tabs, hit: DownHit
): Tabs = case+ hit.zone of
  | DownSidebar() =>
      (case+ s.side of
       | SideNone() => ts
       | SideFiles() => (if is_btn(hit.button, BtnLeft) then handle_tree_click(s, ts, hit.x, hit.y) else ts)
       | SideSearch() => (if is_btn(hit.button,BtnLeft) then handle_search_click(s,ts,hit.x,hit.y) else ts)
       | SideConfig() => handle_config_click(s, f, ts, hit.x, hit.y))
  | DownMenu() => ts | DownResize() => ts
  | DownTopbar() => ts | DownEditor() => ts

fun open_tree_context(s: &App_record >> _, hit: DownHit): void = let
  val row = tree_source_at_y(s, hit.y)
  val valid_row = ige(row, 0) andalso ilt(row, s.tn)
  val () = s.menu := MenuFileTree
  val () = app_fsm_step(s, ActOpenMenu(MenuFileTree))
in
  s.sel := (if valid_row then row else ~1)
end

fun place_context(s: &App_record >> _, hit: DownHit): void = let
  val () = s.menux := hit.x
in
  s.menuy := hit.y
end
