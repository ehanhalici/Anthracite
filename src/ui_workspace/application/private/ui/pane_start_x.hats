fun pane_start_x(s: &App_record, w: int, pane: int): int = let
  val sidew = if not(is_side_none(s.side)) then s.sidew else 0
  val mid = iadd(sidew, idiv(isub(w, sidew), 2))
in
  if is_on(s.split) andalso ieq(pane, 1) then iadd(mid, 4)
  else topbar_tabs_x0(s)
end

fun tab_pane_count_m {rem:nat} .<rem>. (tp: !Buf, i: int, pane: int, acc: int, rem: int(rem)): int =
  if rem = 0 then acc
  else tab_pane_count_m(tp, iadd(i, 1), pane, if ieq(buf_get(tp, i), pane) then iadd(acc, 1) else acc, rem - 1)

fun tab_pane_count(tp: !Buf, pane: int): int =
  tab_pane_count_m(tp, 0, pane, 0, airlock_nat(imax(0, buf_len(tp))))

fun tab_pane_find_last_m {rem:nat} .<rem>. (tp: !Buf, i: int, pane: int, best: int, rem: int(rem)): int =
  if rem = 0 then best
  else tab_pane_find_last_m(tp, iadd(i, 1), pane, if ieq(buf_get(tp, i), pane) then i else best, rem - 1)

fun tab_pane_find_last(tp: !Buf, pane: int): int =
  tab_pane_find_last_m(tp, 0, pane, ~1, airlock_nat(imax(0, buf_len(tp))))

fun motion_tab_drag(s: &App_record >> _, x: int, y: int): void = let
  val moved = igt(iabs(isub(x, s.downx)), 5) orelse igt(iabs(isub(y, s.downy)), 5)
in
  if ige(s.downx, 0) andalso ige(s.dragi, 0) andalso moved then (
    if ilt(s.downy, s.tb_h) then s.drag := DragTab
    else if is_on(s.tree_drag_pending) then (s.drag := DragFile; s.tree_drag_pending := Off)
    else ()
  ) else ()
end

fun transfer_dragged_tab_pane(s: &App_record >> _, target_pane: int): void = let
  val ti = s.dragi
  val () = if ilt(ti, buf_len(s.tab_pane)) then buf_set(s.tab_pane, ti, target_pane) else ()
  val () = s.focus := toggle_of(ieq(target_pane, 1))
in
  if ieq(target_pane, 1) then (
    s.righti := ti;
    if ieq(s.active, ti) then (
      let val nxt = tab_pane_find_first(s.tab_pane, 0) in
        if ige(nxt, 0) then s.active := nxt else ()
      end
    ) else ()
  ) else (
    s.active := ti;
    if ieq(s.righti, ti) then (
      let val nxt = tab_pane_find_first(s.tab_pane, 1) in
        if ige(nxt, 0) then s.righti := nxt else ()
      end
    ) else ()
  )
end

fun motion_tab_reorder(s: &App_record >> _, f: !Font, r: !Rend, x: int, y: int, w: int): void =
  if ilt(y, s.tb_h) andalso ige(s.dragi, 0) andalso ilt(s.dragi, tabs_len(s.tabs)) then let
    val sidew = if not(is_side_none(s.side)) then s.sidew else 0
    val mid = iadd(sidew, idiv(isub(w, sidew), 2))
    val p0 = if s.dragi < buf_len(s.tab_pane) then buf_get(s.tab_pane, s.dragi) else 0
    val want_p = if is_on(s.split) then (if ige(x, mid) then 1 else 0) else p0
    val can_xfer = is_on(s.split) andalso ine(p0, want_p) andalso igt(tab_pane_count(s.tab_pane, p0), 1)
    val () = if can_xfer then transfer_dragged_tab_pane(s, want_p) else ()
    val p = if s.dragi < buf_len(s.tab_pane) then buf_get(s.tab_pane, s.dragi) else 0
    val flt = if is_on(s.split) then p else ~1
    val sx = pane_start_x(s, w, p)
    val bx_btn = topbar_mode_btn_x(w, s.modew)
    val avail_w = if is_on(s.split) andalso ieq(p, 1) then imax(40, isub(isub(bx_btn, 6), sx))
      else if is_on(s.split) then imax(40, isub(isub(mid, 4), sx))
      else imax(60, isub(isub(bx_btn, 6), sx))
    val hit_t = tab_find_at_x_w(f, r, s.tabs, sx, avail_w, x, flt, s.tab_pane)
    val tgt = if ige(hit_t, 0) then hit_t else if ige(x, sx) then tab_pane_find_last(s.tab_pane, p) else ~1
  in
    if ige(tgt, 0) andalso ine(tgt, s.dragi) then app_reorder_tab(s, s.dragi, tgt)
    else ()
  end else ()

fun motion_editor_drag(s: &App_record >> _, f: !Font, r: !Rend, x: int, y: int, w: int): void = let
  val () = font_set_px(f, s.doc_fontpx)
  val sidew = if not(is_side_none(s.side)) then s.sidew else 0
  val pw0 = isub(w, sidew)
  val half = if is_on(s.split) then idiv(pw0, 2) else pw0
  val ox = if is_on(s.focus) then iadd(sidew, half) else sidew
  val idx = pane_of(s.focus, s.active, s.righti)
  val lh = font_line_h(f)
  val doc_oy = doc_content_top_y(doc_top_y_of(s), lh)
  var hitk: NodeKind = KNone
  var hiti: int = ~1
  val embedded=cache_embed_selection_active(s.cache)
  val moved=ige(iabs(isub(x,s.downx)),5) orelse ige(iabs(isub(y,s.downy)),5)
  val rel_y = isub(y, isub(doc_oy, s.tb_h))
  val selected=if embedded andalso moved then tabs_embed_select(f,r,s.tabs,idx,x,rel_y,ox,half,lh,s.vault,s.cache,s.scratch,true) else false
in
  if embedded orelse not(moved) then () else s.tabs := tabs_click_oy(f,r,s.tabs,idx,x,y,ox,doc_oy,half,lh,s.scratch,On,hitk,hiti,0)
end

fun motion_drag(s: &App_record >> _, f: !Font, r: !Rend, x: int, y: int, w: int): void =
  case+ s.drag of
  | DragNone() => motion_tab_drag(s, x, y)
  | DragTab() => motion_tab_reorder(s, f, r, x, y, w)
  | DragFile() => ()
  | DragSplit() => resize_side(s, x, w)
  | DragEditor() => motion_editor_drag(s, f, r, x, y, w)
  | DragDocScroll() => motion_doc_scroll(s, y)
  | DragTreeScroll() => motion_tree_scroll(s, y)
  | DragEditorPan() => motion_editor_pan(s, y)
  | DragEditorFontSlider() => (
      s.fontpx := slider_px_from_x(x, s.sidew);
      s.btnw := 0
    )
  | DragDocFontSlider() =>
      s.doc_fontpx := slider_px_from_x(x, s.sidew)

fun hover_focus_pane(s: &App_record >> _, x: int, y: int, w: int): void =
  if is_on(s.split) andalso is_drag_none(s.drag) andalso is_menu_none(s.menu)
     andalso is_prompt_none(s.prompt) andalso is_off(s.vault_select) then let
    val sidew = if not(is_side_none(s.side)) then s.sidew else 0
    val mid = iadd(sidew, idiv(isub(w, sidew), 2))
  in
    if ige(x, sidew) andalso ige(y, 0) then s.focus := toggle_of(ige(x, mid)) else ()
  end else ()

fun on_motion(a: !App, f: !Font, r: !Rend, ev: &event, w: int): void =
  case+ a of
  | @APP(s) => let
      val x = ev_x(ev)
      val y = ev_y(ev)
      val () = s.last_w := w
      val () = s.hoverx := x
      val () = s.hovery := y
      val () = menu_hover_update(s, f, r, x, y, w, s.last_h)
      val () = hover_focus_pane(s, x, y, w)
      val () = motion_drag(s, f, r, x, y, w)
    in
      fold@(a)
    end

fun motion_changes(s: &App_record,ev: &event): bool = let
  val sidew=if is_side_none(s.side) then 0 else s.sidew
  val mid = iadd(sidew, idiv(isub(imax(s.last_w, sidew), sidew), 2))
  val nx = ev_x(ev); val ny = ev_y(ev)
  val old_editor=ige(s.hoverx,sidew) andalso ige(s.hovery,s.doc_top_y)
  val new_editor=ige(nx,sidew) andalso ige(ny,s.doc_top_y)
  val split_cross = is_on(s.split) andalso (ine(if ige(s.hoverx, mid) then 1 else 0, if ige(nx, mid) then 1 else 0))
  val near_sb = ige(s.hoverx, isub(s.last_w, 20)) orelse ige(nx, isub(s.last_w, 20))
    orelse (igt(sidew, 0) andalso (ige(iabs(isub(s.hoverx, sidew)), 0) andalso ile(iabs(isub(s.hoverx, sidew)), 20)
                                   orelse ile(iabs(isub(nx, sidew)), 20)))
    orelse (is_on(s.split) andalso (ile(iabs(isub(s.hoverx, mid)), 20) orelse ile(iabs(isub(nx, mid)), 20)))
in case+ s.drag of
  | DragNone() => is_on(s.vault_select) orelse not(is_menu_none(s.menu)) orelse ige(s.downx,0) orelse not(old_editor andalso new_editor) orelse split_cross orelse near_sb
  | DragTab() => true | DragFile() => true | DragSplit() => true | DragEditor() => true
  | DragDocScroll() => true | DragTreeScroll() => true | DragEditorPan() => true
  | DragEditorFontSlider() => true | DragDocFontSlider() => true
end

implement app_motion_changes(a,ev) = case+ a of
  | @APP(s) => let val result=motion_changes(s,ev) prval ()=fold@(a) in result end

fun on_up_move_to_right(s: &App_record >> _, ti: int): void = let
  val n = tabs_len(s.tabs)
  val () = buf_set(s.tab_pane, ti, 1)
  val () = s.righti := ti
  val () = s.focus := On
  val () = s.cursor_pane := 1
  val () = if ieq(s.active, ti) then let
    val nxt = tab_pane_find_first(s.tab_pane, 0)
    val () = if ige(nxt, 0) then s.active := nxt else ()
  in end else ()
  val () = if not(tab_pane_has(s.tab_pane, 0)) then (
    s.split := Off; s.focus := Off; s.active := s.righti; s.cursor_pane := 0
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
  val () = s.cursor_pane := 0
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
        if ieq(count,1) then split_pane_single(s) else split_pane_multi(s,tab)
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
  val drop_x = if ige(x, 0) then x else s.hoverx
  val drop_y = if ige(y, 0) then y else s.hovery
  val to_r = if is_on(s.split) then ige(drop_x, mid) else ige(drop_x, mid) andalso ige(drop_y, s.tb_h)
  val to_l = is_on(s.split) andalso ige(drop_x, sidew) andalso ilt(drop_x, mid)
in
  apply_tab_drop(s, ti, n, to_r, to_l)
end

fun report_move_failure(rn: int, src: !Buf): void =
  if ieq(rn, 0) then () else report_failure("tree_move", buffer_c_string(src))

fun drag_buf_eq(a: !Buf, b: !Buf): bool = let
  val la = buf_len(a)
  val lb = buf_len(b)
in
  ieq(la, lb) andalso ph_prefix_eq_m(a, b, 0, airlock_nat(imax(0, la)))
end

fun drag_is_self_or_desc(src: !Buf, dst: !Buf): bool = let
  val sl = buf_len(src)
  val dl = buf_len(dst)
in
  if drag_buf_eq(src, dst) then true
  else if igt(dl, sl) andalso igt(sl, 0) andalso ieq(buf_get(dst, sl), CHAR_SLASH) then
    ph_prefix_eq_m(dst, src, 0, airlock_nat(imax(0, sl)))
  else false
end

fun resolve_file_drop_dir(s: &App_record, y: int, dstp: &Buf >> _): bool = let
  val row = tree_source_at_y(s, y)
in
  if ige(row, 0) andalso ilt(row, s.tn) then (
    if ieq(row, s.dragi) then false
    else if is_dir_mark(meta_dir(s.tmeta, row), DirYes) then (row_path(s.tree, s.tmeta, row, dstp); true)
    else let
      var tmp = buf_make(256)
      val () = row_path(s.tree, s.tmeta, row, tmp)
      val () = dirname_of(tmp, dstp)
      val () = buf_free(tmp)
    in true end
  ) else (buffer_clear(dstp); buffer_append_all(dstp, s.vault); igt(buf_len(dstp), 0))
end

fun finish_move_rename(s: &App_record >> _, srcp: !Buf, final: !Buf): void = let
  val rn = fs_rename(buffer_c_string(srcp), buffer_c_string(final))
in
  if ieq(rn, 0) then let
    val ts = s.tabs; val () = s.tabs := TNil()
    val ts2 = tabs_rename_prefix(ts, srcp, final)
    val ph = s.tabs; val () = s.tabs := ts2; val () = tabs_free(ph)
    val () = app_rename_tab_hists(s, srcp, final)
    val () = save_app_session(s)
  in
    s.treedirty := On; s.search_catalog_ready := false
  end else report_move_failure(rn, srcp)
end

fun try_finish_move(s: &App_record >> _, dstp: !Buf, srcp: !Buf, final: !Buf): void = let
  val blocked = drag_is_self_or_desc(srcp, dstp) orelse drag_buf_eq(srcp, final)
in
  if not(blocked) then finish_move_rename(s, srcp, final) else ()
end

fun move_dragged_file_to_dir(s: &App_record >> _, dstp: !Buf): void = let
  var srcp = buf_make(MOVE_DRAGGED_FILE_SRCP_INITIAL_BYTES)
  var name = buf_make(MOVE_DRAGGED_FILE_NAME_INITIAL_BYTES)
  var final = buf_make(MOVE_DRAGGED_FILE_FINAL_INITIAL_BYTES)
  val () = row_path(s.tree, s.tmeta, s.dragi, srcp)
  val () = base_name(srcp, name)
  val () = child_path(dstp, name, final)
  val () = try_finish_move(s, dstp, srcp, final)
  val () = buf_free(srcp)
  val () = buf_free(name)
in
  buf_free(final)
end

fun open_dropped_file_in_pane(s: &App_record >> _, target_pane: int): void = let
  var srcp = buf_make(MOVE_DRAGGED_FILE_SRCP_INITIAL_BYTES)
  val () = row_path(s.tree, s.tmeta, s.dragi, srcp)
  val ex = tabs_find_path(s.tabs, srcp)
in
  if ige(ex, 0) then (
    buf_free(srcp);
    if is_on(s.split) andalso ieq(target_pane, 1) then (s.righti := ex; s.focus := On)
    else (s.active := ex; s.focus := Off);
    save_app_session(s)
  ) else let
    val ts = s.tabs; val () = s.tabs := TNil()
    val ts2 = tabs_open_kept(ts, srcp, s.closed)
    val ntabs = tabs_len(ts2)
    val ni = isub(ntabs, 1)
    val () = app_sync_tab_hists(s, ts2)
    val ph = s.tabs; val () = s.tabs := ts2; val () = tabs_free(ph)
    val () = sync_tab_pane(s.tab_pane, ntabs, s.split, s.righti)
    val () = if ilt(ni, buf_len(s.tab_pane)) then buf_set(s.tab_pane, ni, target_pane) else ()
    val () = if is_on(s.split) andalso ieq(target_pane, 1) then (s.righti := ni; s.focus := On)
             else (s.active := ni; s.focus := Off)
  in save_app_session(s) end
end

fun move_dragged_sidebar_buf(s: &App_record >> _, y: int, dstp: &Buf >> Buf): void =
  if resolve_file_drop_dir(s, y, dstp) then move_dragged_file_to_dir(s, dstp) else ()

fun on_up_move_file(s: &App_record >> _, x: int, y: int, w: int): void =
  if ige(s.dragi, 0) andalso ilt(s.dragi, s.tn) then let
    val sidew = if not(is_side_none(s.side)) then s.sidew else 0
    val mid = iadd(sidew, idiv(isub(w, sidew), 2))
  in
    if ige(x, sidew) then (
      if is_dir_mark(meta_dir(s.tmeta, s.dragi), DirNo) then
        open_dropped_file_in_pane(s, if is_on(s.split) andalso ige(x, mid) then 1 else 0)
      else ()
    ) else let
      var dstp = buf_make(MOVE_DRAGGED_FILE_DSTP_INITIAL_BYTES)
      val () = move_dragged_sidebar_buf(s, y, dstp)
    in buf_free(dstp) end
  end else ()

fun on_up_editor(s: &App_record >> _, x: int, y: int): void = let
  val dx = iabs(isub(x, s.downx))
  val dy = iabs(isub(y, s.downy))
  val clicked_no_drag = ige(s.downx,0) andalso ilt(dx,5) andalso ilt(dy,5)
    andalso not(cache_embed_selection_dragged(s.cache))
  val use_new = is_on(s.click_ctrl)
  val can_nav = is_view_read(s.viewmode) orelse not(is_on(s.click_was_raw)) orelse is_kind(s.hitk,KEmbed)
  val () = s.click_was_raw := Off
  val () = s.click_ctrl := Off
in
  if clicked_no_drag andalso can_nav then let
    val idx = pane_of(s.focus, s.active, s.righti)
    val origin_pane = if is_on(s.split) andalso is_on(s.focus) then 1 else 0
    val old_len = tabs_len(s.tabs)
    var target_act: int = ~1
    val ts0 = s.tabs
    val () = s.tabs := TNil()
    val ts2 = app_wiki_go(s, ts0, idx, true, use_new, target_act)
    val () = cache_clear_embed_selection(s.cache)
    val ph = s.tabs
    val () = s.tabs := ts2
    val () = tabs_free(ph)
    val cur_len = tabs_len(s.tabs)
    val () = if ige(target_act, 0) then (
      s.editor_focused := Off;
      s.last_click_ns := 0L;
      s.last_click_pos := ~1;
      editor_wiki_focus_act(s, cur_len, target_act);
      assign_new_tab_pane(s, origin_pane, old_len, cur_len, target_act);
      editor_wiki_focus_act(s, cur_len, target_act);
      s.cursor_pane := (if is_on(s.split) andalso is_on(s.focus) then 1 else 0)
    ) else ()
  in
    save_app_session(s)
  end else ()
end
