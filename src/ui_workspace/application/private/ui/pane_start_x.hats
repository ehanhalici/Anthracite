fun pane_start_x(s: &App_record, w: int, pane: int): int = let
  val sidew = if not(is_side_none(s.side)) then s.sidew else 0
  val mid = iadd(sidew, idiv(isub(w, sidew), 2))
in
  if is_on(s.split) andalso ieq(pane, 1) then iadd(mid, 4)
  else topbar_tab_start_x(s.btnw)
end

fun motion_tab_drag(s: &App_record >> _, x: int, y: int): void =
  if ige(s.downx, 0) andalso ige(s.dragi, 0) andalso ilt(s.downy, UI_TOPBAR_HEIGHT) then
    if igt(iabs(isub(x, s.downx)), 8) orelse igt(iabs(isub(y, s.downy)), 8) then s.drag := DragTab else ()
  else ()

fun motion_tab_reorder(s: &App_record >> _, f: !Font, r: !Rend, x: int, y: int, w: int): void =
  if ilt(y, UI_TOPBAR_HEIGHT) andalso ige(s.dragi, 0) andalso ilt(s.dragi, tabs_len(s.tabs)) then let
    val p = if s.dragi < buf_len(s.tab_pane) then buf_get(s.tab_pane, s.dragi) else 0
    val flt = if is_on(s.split) then p else ~1
    val sx = pane_start_x(s, w, p)
    val tgt = tab_find_at_x(f, r, s.tabs, sx, x, flt, s.tab_pane)
  in
    if ige(tgt, 0) andalso ine(tgt, s.dragi) then app_reorder_tab(s, s.dragi, tgt)
    else ()
  end else ()

fun motion_editor_drag(s: &App_record >> _, f: !Font, r: !Rend, x: int, y: int, w: int): void = let
  val sidew = if not(is_side_none(s.side)) then s.sidew else 0
  val pw0 = isub(w, sidew)
  val half = if is_on(s.split) then idiv(pw0, 2) else pw0
  val ox = if is_on(s.focus) then iadd(sidew, half) else sidew
  val idx = pane_of(s.focus, s.active, s.righti)
  val lh = font_line_h(f)
  var hitk: NodeKind = KNone
  var hiti: int = ~1
  val ts = tabs_click(f, r, s.tabs, idx, x, y, ox, half, 0, lh, s.scratch, On, hitk, hiti, 0)
in
  s.tabs := ts
end

fun motion_drag(s: &App_record >> _, f: !Font, r: !Rend, x: int, y: int, w: int): void =
  case+ s.drag of
  | DragNone() => motion_tab_drag(s, x, y)
  | DragTab() => motion_tab_reorder(s, f, r, x, y, w)
  | DragFile() => ()
  | DragSplit() => resize_side(s, x, w)
  | DragEditor() => motion_editor_drag(s, f, r, x, y, w)

fun on_motion(a: !App, f: !Font, r: !Rend, ev: &event, w: int): void =
  case+ a of
  | @APP(s) => let
      val x = ev_x(ev)
      val y = ev_y(ev)
      val () = s.hoverx := x
      val () = s.hovery := y
      val () = motion_drag(s, f, r, x, y, w)
    in
      fold@(a)
    end

fun motion_changes(s: &App_record,ev: &event): bool = let
  val sidew=if is_side_none(s.side) then 0 else s.sidew
  val old_editor=ige(s.hoverx,sidew) andalso ige(s.hovery,UI_TOPBAR_HEIGHT)
  val new_editor=ige(ev_x(ev),sidew) andalso ige(ev_y(ev),UI_TOPBAR_HEIGHT)
in case+ s.drag of
  | DragNone() => is_on(s.vault_select) orelse ige(s.downx,0) orelse not(old_editor andalso new_editor)
  | DragTab() => true | DragFile() => true | DragSplit() => true | DragEditor() => true
end

implement app_motion_changes(a,ev) = case+ a of
  | @APP(s) => let val result=motion_changes(s,ev) prval ()=fold@(a) in result end

fun on_up_split_single(s: &App_record >> _): void = let
  val ts = s.tabs
  val () = s.tabs := TNil()
  val ts2 = tabs_clone_tab(ts, 0)
  val ph = s.tabs
  val () = s.tabs := ts2
  val () = tabs_free(ph)
  val () = buf_ensure(s.tab_pane, 2)
  val () = buf_set_len(s.tab_pane, 2)
  val () = buf_set(s.tab_pane, 0, 0)
  val () = buf_set(s.tab_pane, 1, 1)
  val () = s.active := 0
  val () = s.righti := 1
  val () = s.split := On
  val () = s.focus := On
  val () = validate_panes_len(s, 2)
in
  save_app_session(s)
end

fun on_up_split_multi(s: &App_record >> _, ti: int): void = let
  val n = tabs_len(s.tabs)
  val () = tab_pane_init_split(s.tab_pane, n, ti)
  val () = s.split := On
  val () = s.righti := ti
  val () = s.focus := On
  val () = if ieq(s.active, ti) then let
    val nxt = tab_pane_find_first(s.tab_pane, 0)
    val () = if ige(nxt, 0) then s.active := nxt else ()
  in end else ()
  val () = validate_panes_len(s, n)
in
  save_app_session(s)
end

fun on_up_move_to_right(s: &App_record >> _, ti: int): void = let
  val n = tabs_len(s.tabs)
  val () = buf_set(s.tab_pane, ti, 1)
  val () = s.righti := ti
  val () = s.focus := On
  val () = if ieq(s.active, ti) then let
    val nxt = tab_pane_find_first(s.tab_pane, 0)
    val () = if ige(nxt, 0) then s.active := nxt else ()
  in end else ()
  val () = if not(tab_pane_has(s.tab_pane, 0)) then (
    s.split := Off; s.focus := Off; s.active := s.righti
  ) else ()
  val () = validate_panes_len(s, n)
in
  save_app_session(s)
end

fun on_up_move_to_left(s: &App_record >> _, ti: int): void = let
  val n = tabs_len(s.tabs)
  val () = buf_set(s.tab_pane, ti, 0)
  val () = s.active := ti
  val () = s.focus := Off
  val () = if ieq(s.righti, ti) then let
    val nxt = tab_pane_find_first(s.tab_pane, 1)
    val () = if ige(nxt, 0) then s.righti := nxt else ()
  in end else ()
  val () = if not(tab_pane_has(s.tab_pane, 1)) then (
    s.split := Off; s.focus := Off
  ) else ()
  val () = validate_panes_len(s, n)
in
  save_app_session(s)
end

fun apply_tab_drop(s: &App_record >> _,tab: int,count: int,to_right: bool,to_left: bool): void =
  if ige(tab,0) andalso ilt(tab,count) then let
    val pane=if tab < buf_len(s.tab_pane) then buf_get(s.tab_pane,tab) else 0
  in
    if not(is_on(s.split)) then (
      if to_right then (
        if ieq(count,1) then on_up_split_single(s) else on_up_split_multi(s,tab)
      ) else save_app_session(s)
    ) else (
      if ieq(pane,0) andalso to_right then on_up_move_to_right(s,tab)
      else if ieq(pane,1) andalso to_left then on_up_move_to_left(s,tab)
      else save_app_session(s)
    )
  end else ()

fun on_up_drag_tab(s: &App_record >> _, w: int, x: int, y: int): void = let
  val sidew = if not(is_side_none(s.side)) then s.sidew else 0
  val mid = iadd(sidew, idiv(isub(w, sidew), 2))
  val ti = s.dragi
  val n = tabs_len(s.tabs)
  val drop_x = if ige(x, mid) then x else s.hoverx
  val drop_y = if ige(y, UI_TOPBAR_HEIGHT) then y else s.hovery
  val to_r = ige(drop_x, mid) andalso ige(drop_y, UI_TOPBAR_HEIGHT)
  val to_l = ilt(drop_x, mid) andalso ige(drop_y, UI_TOPBAR_HEIGHT)
in
  apply_tab_drop(s,ti,n,to_r,to_l)
end

fun report_move_failure(rn: int, src: !Buf): void =
  if ieq(rn, 0) then () else report_failure("tree_move", buffer_c_string(src))

fun move_dragged_file(s: &App_record >> _, row: int): void = let
  var srcp = buf_make(MOVE_DRAGGED_FILE_SRCP_INITIAL_BYTES)
  var dstp = buf_make(MOVE_DRAGGED_FILE_DSTP_INITIAL_BYTES)
  var name = buf_make(MOVE_DRAGGED_FILE_NAME_INITIAL_BYTES)
  var final = buf_make(MOVE_DRAGGED_FILE_FINAL_INITIAL_BYTES)
  val () = row_path(s.tree, s.tmeta, s.dragi, srcp)
  val () = row_path(s.tree, s.tmeta, row, dstp)
  val () = base_name(srcp, name)
  val () = child_path(dstp, name, final)
  val rn = fs_rename(buffer_c_string(srcp), buffer_c_string(final))
  val () = report_move_failure(rn, srcp)
  val () = s.treedirty := On
  val () = buf_free(srcp)
  val () = buf_free(dstp)
  val () = buf_free(name)
in
  buf_free(final)
end

fun on_up_move_file(s: &App_record >> _, y: int): void = let
  val row = tree_source_at_y(s, y)
in
  if ige(row, 0) andalso ilt(row, s.tn) andalso ine(row, s.dragi) andalso is_dir_mark(meta_dir(s.tmeta, row), DirYes) then move_dragged_file(s, row)
  else ()
end

fun on_up_editor(s: &App_record >> _, x: int, y: int): void = let
  val dx = iabs(isub(x, s.downx))
  val dy = iabs(isub(y, s.downy))
  val clicked_no_drag = ige(s.downx,0) andalso ilt(dx,5) andalso ilt(dy,5)
  val is_read = is_view_read(s.viewmode) orelse is_kind(s.hitk,KEmbed)
in
  if clicked_no_drag andalso is_read then let
    val idx = pane_of(s.focus, s.active, s.righti)
    var target_act: int = ~1
    val ts2 = app_wiki_open(s.tabs, idx, s.vault, target_act)
    val () = s.tabs := ts2
    val cur_len = tabs_len(s.tabs)
    val () = if ige(target_act, 0) then editor_wiki_focus_act(s, cur_len, target_act) else ()
  in
    save_app_session(s)
  end else ()
end
