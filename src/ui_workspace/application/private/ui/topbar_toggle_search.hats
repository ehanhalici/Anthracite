fun topbar_toggle_search(s: &App_record >> _): void = let
  val () = s.side := (if is_side_search(s.side) then SideNone else SideSearch)
  val () = s.qfocus := toggle_of(is_side_search(s.side))
  val () = if is_side_search(s.side) then s.scope := 0 else ()
  val () = if is_side_search(s.side) then search_job_begin(s) else search_job_clear(s)
in
  save_app_session(s)
end

fun topbar_toggle_config(s: &App_record >> _): void = let
  val () = s.side := (if is_side_config(s.side) then SideNone else SideConfig)
  val () = s.settings_open := Off
  val () = s.settings_scroll := 0
  val () = s.qfocus := Off
in
  save_app_session(s)
end

fun handle_topbar_action(s: &App_record >> _, w: int, x: int): void = let
  val bw = s.btnw
  val x1 = topbar_btn_x(0, bw)
  val x2 = topbar_btn_x(1, bw)
  val x3 = topbar_btn_x(2, bw)
  val bx = topbar_mode_btn_x(w, s.modew)
  val () = s.editor_focused := Off
in
  if ige(x, bx) andalso ilt(x, iadd(bx, s.modew)) then topbar_toggle_view(s)
  else if ige(x, x1) andalso ilt(x, iadd(x1, bw)) then topbar_toggle_files(s)
  else if ige(x, x2) andalso ilt(x, iadd(x2, bw)) then topbar_toggle_search(s)
  else if ige(x, x3) andalso ilt(x, iadd(x3, bw)) then topbar_toggle_config(s)
  else ()
end

fun config_select_font(s: &App_record >> _, f: !Font, sel_fi: int): void =
  if ige(sel_fi, 0) andalso ilt(sel_fi, s.fcnt) then let
    val poff = buf_get32(s.fmeta, imul(sel_fi, 4))
    val plen = buf_get32(s.fmeta, iadd(imul(sel_fi, 4), 1))
    val () = buffer_clear(s.font_path)
    val () = buffer_append_range(s.font_path, s.fpaths, poff, iadd(poff, plen))
    val () = font_load_report(f, buffer_c_string(s.font_path))
    val () = font_set_px(f, s.fontpx)
    val () = s.font_idx := 1
    val () = s.btnw := 0
    val () = save_app_session(s)
  in
    ()
  end else ()

fun config_click_dispatch(
  s: &App_record >> _, f: !Font, lay: CfgLayout, x: int, y: int, on_kasa: bool, on_fonts: bool, on_kb: bool
): void =
  if on_kasa then (conf_list_vaults(s.vpaths, s.vnames, s.vmeta, s.vcnt); s.vault_select := On)
  else if slider_hit(x, y, s.sidew, lay.ed_sldr_y) then (
    s.drag := DragEditorFontSlider; s.fontpx := slider_px_from_x(x, s.sidew); s.btnw := 0
  ) else if slider_hit(x, y, s.sidew, lay.doc_sldr_y) then (
    s.drag := DragDocFontSlider; s.doc_fontpx := slider_px_from_x(x, s.sidew)
  ) else if on_fonts then config_select_font(s, f, idiv(isub(y, lay.font_list_y), lay.frow_h))
  else if on_kb then conf_load_keybindings(s.keymap)
  else ()

fun handle_sidebar_config_action(s: &App_record >> _, f: !Font, x: int, y: int): void = let
  val () = s.editor_focused := Off
  val () = font_set_px(f, s.fontpx)
  val lay = config_layout(f, s)
  val on_kasa = ige(x, 12) andalso ilt(x, iadd(12, lay.vault_btn_w))
    andalso ige(y, lay.vault_btn_y) andalso ilt(y, iadd(lay.vault_btn_y, lay.btn_h))
  val on_fonts = ige(x, 10) andalso ilt(x, isub(s.sidew, 10))
    andalso ige(y, lay.font_list_y) andalso ilt(y, iadd(lay.font_list_y, imul(s.fcnt, lay.frow_h)))
  val on_kb = ige(x, lay.kb_btn_x) andalso ilt(x, iadd(lay.kb_btn_x, lay.kb_btn_w))
    andalso ige(y, lay.kb_y) andalso ilt(y, iadd(lay.kb_y, lay.btn_h))
in
  if ilt(y, doc_top_y_of(s)) then ()
  else config_click_dispatch(s, f, lay, x, y, on_kasa, on_fonts, on_kb)
end

fun editor_wiki_focus_act(s: &App_record >> _, cur_len: int, target_act: int): void = let
  val () = s.flash_until_ns := mono_ns()+UI_NAVIGATION_FLASH_NS
  val () = sync_open_dirs_from_tree(s)
  val () = sync_tab_pane(s.tab_pane, cur_len, s.split, s.righti)
  val pane = if ilt(target_act, buf_len(s.tab_pane)) then buf_get(s.tab_pane, target_act) else 0
  val () = if ieq(pane, 1) then (s.righti := target_act; s.focus := On)
           else (s.active := target_act; s.focus := Off)
in
end

fun editor_wiki_focus(s: &App_record >> _, ts: !Tabs, old_len: int): void = let
  val cur_len = tabs_len(ts)
  val target_act = if igt(cur_len, old_len) then isub(cur_len, 1) else s.active
  val () = editor_wiki_focus_act(s, cur_len, target_act)
  val side_open = (if is_side_none(s.side) then 0 else 1)
in
  save_session_impl(s.vault, s.font_path, s.fontpx, s.doc_fontpx, s.viewmode, s.split, s.active, s.righti, side_open, s.sidew, s.tab_pane, s.open_dirs, ts)
end

fun editor_click_hit(f: !Font, r: !Rend, s: &App_record >> _, ts: Tabs, ev: &event, x: int, y: int, ox: int, oy: int, half: int, idx2: int, editor: Toggle): Tabs = let
  val keep = iand(ev_mods(ev), mod_shift()) <> 0
  val is_alt = iand(ev_mods(ev), mod_alt()) <> 0
  val () = font_set_px(f, s.doc_fontpx)
  val doc_lh = font_line_h(f)
  val ts4 = click_go(f, r, ts, idx2, x, y, ox, oy, half, doc_lh, s.scratch, toggle_of(keep), s.hitk, s.hiti, editor)
  val colx_hit = editor_colx(f, r, ox, half)
  val arr_min = gutter_num_end_x(f, r, colx_hit)
  val on_arrow = is_on(editor) andalso ige(x, arr_min) andalso ilt(x, colx_hit) andalso ige(s.hiti, 0)
  val on_task = is_on(editor) andalso is_kind(s.hitk, KTask) andalso ige(x, colx_hit) andalso ilt(x, iadd(colx_hit, 36)) andalso ige(s.hiti, 0)
  val ts4_a = toggle_go(ts4, idx2, s.hiti, is_alt, toggle_of(on_arrow))
  val ts4_b = toggle_task_go(ts4_a, idx2, s.hiti, toggle_of(on_task))
in
  ts4_b
end

fun app_wiki_go(
  s: &App_record >> _, ts: Tabs, idx: int, gowiki: bool, new_tab: bool, target_act: &int >> _
): Tabs =
  if not(gowiki) then (target_act := ~1; ts)
  else if new_tab then app_embedded_navigation(ts, idx, s.vault, s.cache, target_act, s.closed)
  else app_embedded_nav_in_place(s, ts, idx, target_act)

fun assign_new_tab_pane(s: &App_record >> _, origin_pane: int, old_len: int, cur_len: int, target_act: int): void =
  if igt(cur_len, old_len) andalso ige(target_act, old_len) andalso ilt(target_act, buf_len(s.tab_pane)) then
    buf_set(s.tab_pane, target_act, origin_pane)
  else ()

fun editor_post_click(
  s: &App_record >> _, ts4: Tabs, idx: int, idx2: int, imgdel: Toggle, clear: Toggle, gowiki: bool, new_tab: bool
): Tabs = let
  var target_act: int = ~1
  val old_len = tabs_len(ts4)
  val origin_pane = if is_on(s.split) andalso is_on(s.focus) then 1 else 0
  val ts5 = app_wiki_go(s, ts4, idx2, gowiki, new_tab, target_act)
  val ts6 = del_go(ts5, idx, s.hiti, toggle_of(is_on(imgdel)))
  val ts7 = clear_go(ts6, idx, toggle_of(is_on(clear)))
  val cur_len = tabs_len(ts7)
  val () = if gowiki andalso ige(target_act, 0) then (
    editor_wiki_focus_act(s, cur_len, target_act);
    assign_new_tab_pane(s, origin_pane, old_len, cur_len, target_act);
    editor_wiki_focus_act(s, cur_len, target_act)
  ) else ()
in
  ts7
end

fun is_zone_editor(z: DownZone): bool = case+ z of
  | DownEditor() => true
  | DownMenu() => false | DownResize() => false
  | DownTopbar() => false | DownSidebar() => false

fun is_zone_topbar(z: DownZone): bool = case+ z of
  | DownTopbar() => true
  | DownMenu() => false | DownResize() => false
  | DownSidebar() => false | DownEditor() => false

fun begin_embedded_selection(s: &App_record >> _,f: !Font,r: !Rend,tabs: !Tabs,index: int,
  hit: DownHit,ox: int,oy: int,width: int,editor: bool,control: bool): void =
  if editor then let
    val rel_y = isub(hit.y, isub(oy, s.tb_h))
    val selected=tabs_embed_select(f,r,tabs,index,hit.x,rel_y,ox,width,font_line_h(f),s.vault,s.cache,s.scratch,false)
  in () end else ()

#define UI_DOUBLE_CLICK_NS 500000000L

fun reset_click_track(s: &App_record >> _): void = let
  val () = s.last_click_ns := 0L
  val () = s.last_click_pos := ~1
in
end

fun record_single_click(s: &App_record >> _, idx: int, x: int, y: int, pos: int, now: lint): void = let
  val () = s.last_click_ns := now
  val () = s.last_click_x := x
  val () = s.last_click_y := y
  val () = s.last_click_pos := pos
  val () = s.last_click_tab := idx
in
end

fun select_double_click_word(s: &App_record >> _, ts: Tabs, idx: int, cur_pos: int): Tabs = let
  val target_pos = if ige(s.last_click_pos, 0) then s.last_click_pos else cur_pos
  val ts1 = tabs_select_word_at(ts, idx, target_pos)
  val ts2 = (if ieq(tabs_caret(ts1, idx), tabs_anchor(ts1, idx)) then tabs_select_word_at(ts1, idx, cur_pos) else ts1) : Tabs
  val () = reset_click_track(s)
  val () = s.drag := DragNone
  val () = s.downx := ~1
  val () = s.downy := ~1
in
  ts2
end

fun apply_editor_double_click(s: &App_record >> _, ts: Tabs, idx: int, x: int, y: int, keep: bool, editor: bool): Tabs =
  if not(editor) orelse keep then (reset_click_track(s); ts)
  else let
    val now = mono_ns()
    val cur_pos = tabs_caret(ts, idx)
    val is_dbl = s.last_click_ns > 0L andalso now - s.last_click_ns <= UI_DOUBLE_CLICK_NS
      andalso ieq(idx, s.last_click_tab) andalso ile(iabs(isub(x, s.last_click_x)), 8) andalso ile(iabs(isub(y, s.last_click_y)), 8)
  in
    if is_dbl then select_double_click_word(s, ts, idx, cur_pos)
    else (record_single_click(s, idx, x, y, cur_pos, now); ts)
  end

fun handle_editor_normal_click(s: &App_record >> _, f: !Font, r: !Rend, ts: Tabs, ev: &event,
                               hit: DownHit, idx: int, ox: int, oy: int, half: int, imgdel: Toggle, clear: Toggle, editor: bool): Tabs = let
  val () = if editor then (s.drag := DragEditor; s.downx := hit.x; s.downy := hit.y) else ()
  val keep = ine(iand(ev_mods(ev), mod_shift()), 0)
  val idx2 = pane_of(s.focus, s.active, s.righti)
  val ts4 = editor_click_hit(f, r, s, ts, ev, hit.x, hit.y, ox, oy, half, idx2, toggle_of(editor))
  val () = begin_embedded_selection(s, f, r, ts4, idx2, hit, ox, oy, half, editor, ctrl_on(ev))
  val res = editor_post_click(s, ts4, idx, idx2, imgdel, clear, false, false)
in
  apply_editor_double_click(s, res, idx2, hit.x, hit.y, keep, editor)
end

fun begin_editor_body_click(
  s: &App_record >> _, ts: !Tabs, idx2: int, pane: int, doc_oy: int, doc_lh: int, hit_y: int, is_ctrl: bool
): void = let
  val was_raw = is_on(s.editor_focused) andalso ieq(pane, s.cursor_pane) andalso
    tabs_point_was_raw(ts, idx2, hit_y, doc_oy, doc_lh, s.viewmode)
  val () = s.click_was_raw := toggle_of(was_raw)
  val () = s.click_ctrl := toggle_of(is_ctrl)
  val () = s.editor_focused := On
  val () = s.cursor_pane := pane
in
  tabs_sync_cursor_focus(ts, true, idx2)
end

fun handle_editor_body_click(
  s: &App_record >> _, f: !Font, r: !Rend, ts: Tabs, ev: &event,
  hit: DownHit, idx: int, ox: int, half: int, pane: int,
  is_left: bool, is_pan: bool, imgdel: Toggle, clear: Toggle
): Tabs = let
  val () = font_set_px(f, s.doc_fontpx)
  val doc_lh = font_line_h(f)
  val doc_oy = doc_content_top_y(doc_top_y_of(s), doc_lh)
  val () = s.doc_top_y := doc_oy
  val sb_hit = is_left andalso ige(hit.y, doc_oy) andalso ige(hit.x, isub(iadd(ox, half), UI_SCROLLBAR_HIT_WIDTH)) andalso igt(doc_pane_total_h(s, pane), s.doc_vh)
  val idx2 = pane_of(s.focus, s.active, s.righti)
in
  if is_left andalso ilt(hit.y, doc_oy) then (s.editor_focused := Off; ts)
  else if is_pan then (begin_editor_pan_tabs(s, ts, pane, hit.y); ts)
  else if sb_hit then begin_doc_scroll_drag_tabs(s, ts, pane, hit.y, s.last_h)
  else let
    val () = if is_left then begin_editor_body_click(s, ts, idx2, pane, doc_oy, doc_lh, hit.y, ctrl_on(ev)) else ()
  in
    handle_editor_normal_click(s, f, r, ts, ev, hit, idx, ox, doc_oy, half, imgdel, clear, is_left)
  end
end

fun handle_editor_click(s: &App_record >> _, f: !Font, r: !Rend, ts: Tabs, ev: &event,
                        w: int, hit: DownHit, idx: int, imgdel: Toggle, clear: Toggle): Tabs = let
  val zone_ed = is_zone_editor(hit.zone)
  val is_left = zone_ed andalso is_btn(hit.button, BtnLeft)
  val is_pan = zone_ed andalso (is_btn(hit.button, BtnMiddle) orelse (is_left andalso alt_on(ev)))
  val pw0 = isub(w, hit.sidew)
  val half = if is_on(s.split) then idiv(pw0, 2) else pw0
  val foc = (is_left orelse is_pan) andalso is_on(s.split) andalso ige(hit.x, iadd(hit.sidew, half))
  val () = if is_left orelse is_pan then (s.focus := toggle_of(foc); s.qfocus := Off) else ()
  val ox = if is_on(s.focus) then iadd(hit.sidew, half) else hit.sidew
  val pane = if is_on(s.focus) then 1 else 0
  val pw = if is_on(s.split) andalso is_on(s.focus) then isub(pw0, half) else half
in
  if is_left andalso ilt(hit.y, doc_top_y_of(s)) then
    handle_pane_header_click(f, r, s, ts, pane, hit.x, ox, pw)
  else
    handle_editor_body_click(s, f, r, ts, ev, hit, idx, ox, pw, pane, is_left, is_pan, imgdel, clear)
end

fun down_pick_tab(s: &App_record >> _, x: int, ti: int, pane: int): void = let
  val () = s.drag := DragNone
  val () = s.dragi := ti
  val () = s.downx := x
  val () = s.downy := s.downy
  val () = s.editor_focused := Off
  val () = s.cursor_pane := pane
  val () = if ieq(pane, 1) then (s.righti := ti; s.focus := On)
           else (s.active := ti; s.focus := Off)
in
  save_app_session(s)
end

fun handle_down_tab_bar_selection(
  s: &App_record >> _, ts: !Tabs, f: !Font, r: !Rend,
  hit: DownHit, tab_x0: int, bx: int, w: int,
  ti: &int >> _, close: &bool >> _
): void = let
  val onbar = is_zone_topbar(hit.zone)
  val sidew = if not(is_side_none(s.side)) then s.sidew else 0
  val mid = iadd(sidew, idiv(isub(w, sidew), 2))
  val is_r = is_on(s.split) andalso ige(hit.x, mid)
  val pane = (if is_r then 1 else 0)
  val sx = (if is_r then iadd(mid, 4) else tab_x0)
  val avail_w = if is_r then imax(40, isub(isub(bx, 6), sx))
    else if is_on(s.split) then imax(40, isub(isub(mid, 4), sx))
    else imax(60, isub(isub(bx, 6), sx))
  val filter = (if is_on(s.split) then pane else ~1)
  val () = if onbar andalso ige(hit.x, tab_x0) andalso ilt(hit.x, bx) then
    tab_hit_test_pane_w(f, r, ts, sx, avail_w, hit.x, filter, s.tab_pane, ti, close)
  else ()
  val ntabs = tabs_len(ts)
  val pick = onbar andalso ige(ti, 0) andalso ilt(ti, ntabs) andalso not(close)
in
  if pick then down_pick_tab(s, hit.x, ti, pane) else ()
end

fun text_item_hit(s: &App_record, hit: DownHit, which: TextItem): bool =
  case+ hit.zone of
  | DownMenu() => is_on(hit.inside) andalso is_menu_text(s.menu) andalso ieq(hit.item, text_row(which))
  | DownResize() => false | DownTopbar() => false
  | DownSidebar() => false | DownEditor() => false

fun image_item_hit(s: &App_record, hit: DownHit, which: ImageItem): bool =
  case+ hit.zone of
  | DownMenu() => is_on(hit.inside) andalso is_menu_image(s.menu) andalso ieq(hit.item, image_row(which))
  | DownResize() => false | DownTopbar() => false
  | DownSidebar() => false | DownEditor() => false

fun copy_node_span_here(doc: !Doc, ni: int, dst: &Buf >> _): void =
  if ige(ni, 0) then let
    val st = doc_node_start(doc, ni)
    val en = doc_node_end(doc, ni)
    val () = buf_ensure(dst, iadd(isub(en, st), 2))
    val cap = buf_cap(dst)
    val n = doc_slice_buf(doc, st, en, dst, cap)
  in
    buf_set_len(dst, if n > 0 then n else 0)
  end else ()

fun copy_fallback_node_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), ts: !Tabs, idx: int, ni: int, dst: &Buf >> _): void =
  if recursion_fuel_available(recfuel) then (
    case+ ts of
    | @TNil() => fold@(ts)
    | @TCons(doc, path, title, sc, rest) => let
        val () = if ieq(idx, 0) then copy_node_span_here(doc, ni, dst)
                 else copy_fallback_node_with_fuel(recfuel - 1, rest, isub(idx, 1), ni, dst)
        val () = seen_buf(path)
        val () = seen_buf(title)
        val () = seen_int(sc)
      in
        fold@(ts)
      end
  ) else ()
