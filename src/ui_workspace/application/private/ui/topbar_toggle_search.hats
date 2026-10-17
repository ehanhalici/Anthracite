fun topbar_toggle_search(s: &App_record >> _): void = let
  val () = s.side := (if is_side_search(s.side) then SideNone else SideSearch)
  val () = s.qfocus := toggle_of(is_side_search(s.side))
  val () = if is_side_search(s.side) then s.scope := 0 else ()
in
  save_app_session(s)
end

fun topbar_toggle_config(s: &App_record >> _): void = let
  val () = s.side := (if is_side_config(s.side) then SideNone else SideConfig)
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
in
  if ige(x, bx) andalso ilt(x, iadd(bx, s.modew)) then topbar_toggle_view(s)
  else if ige(x, x1) andalso ilt(x, iadd(x1, bw)) then topbar_toggle_files(s)
  else if ige(x, x2) andalso ilt(x, iadd(x2, bw)) then topbar_toggle_search(s)
  else if ige(x, x3) andalso ilt(x, iadd(x3, bw)) then topbar_toggle_config(s)
  else ()
end

fun config_cycle_font_px(s: &App_record >> _): void = let
  val nxtpx = if ieq(s.fontpx, 16) then 18 else if ieq(s.fontpx, 18) then 20 else 16
  val () = s.fontpx := nxtpx
  val () = s.btnw := 0
in
  save_app_session(s)
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

fun handle_sidebar_config_action(s: &App_record >> _, f: !Font, x: int, y: int): void = let
  val on_kasa_btn = ige(x, 12) andalso ilt(x, 162) andalso ige(y, 122) andalso ilt(y, 144)
  val on_font_px = igt(y, 148) andalso ilt(y, 175)
  val max_fi = imin(s.fcnt, 12)
  val on_font_list = ige(y, 205) andalso ilt(y, iadd(210, imul(max_fi, 22)))
in
  if on_kasa_btn then (
    conf_list_vaults(s.vpaths, s.vnames, s.vmeta, s.vcnt);
    s.vault_select := On
  )
  else if on_font_px then config_cycle_font_px(s)
  else if on_font_list then config_select_font(s, f, idiv(isub(y, 205), 22))
  else ()
end

fun editor_wiki_focus_act(s: &App_record >> _, cur_len: int, target_act: int): void = let
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
  save_session_impl(s.vault, s.font_path, s.fontpx, s.viewmode, s.split, s.active, s.righti, side_open, s.sidew, s.tab_pane, s.open_dirs, ts)
end

fun editor_click_hit(f: !Font, r: !Rend, s: &App_record >> _, ts: Tabs, ev: &event, x: int, y: int, ox: int, half: int, idx2: int, editor: Toggle): Tabs = let
  val keep = iand(ev_mods(ev), mod_shift()) <> 0
  val is_alt = iand(ev_mods(ev), mod_alt()) <> 0
  val () = font_set_px(f, s.fontpx)
  val ts4 = click_go(f, r, ts, idx2, x, y, ox, half, font_line_h(f), s.scratch, toggle_of(keep), s.hitk, s.hiti, editor)
  val colx_hit = editor_colx(f, r, ox, half)
  val arr_min = gutter_num_end_x(f, r, colx_hit)
  val on_arrow = is_on(editor) andalso ige(x, arr_min) andalso ilt(x, colx_hit) andalso ige(s.hiti, 0)
  val on_task = is_on(editor) andalso is_kind(s.hitk, KTask) andalso ige(x, colx_hit) andalso ilt(x, iadd(colx_hit, 36)) andalso ige(s.hiti, 0)
  val ts4_a = toggle_go(ts4, idx2, s.hiti, is_alt, toggle_of(on_arrow))
  val ts4_b = toggle_task_go(ts4_a, idx2, s.hiti, toggle_of(on_task))
in
  ts4_b
end

fun app_wiki_go(ts: Tabs, idx: int, vault: !Buf,cache: !Cache, gowiki: bool, target_act: &int >> _): Tabs =
  if gowiki then app_embedded_navigation(ts, idx, vault,cache, target_act)
  else let
    val () = target_act := ~1
  in
    ts
  end

fun editor_post_click(s: &App_record >> _, ts4: Tabs, idx: int, idx2: int, imgdel: Toggle, clear: Toggle, gowiki: bool): Tabs = let
  var target_act: int = ~1
  val ts5 = app_wiki_go(ts4, idx2, s.vault,s.cache, gowiki, target_act)
  val ts6 = del_go(ts5, idx, s.hiti, toggle_of(is_on(imgdel)))
  val ts7 = clear_go(ts6, idx, toggle_of(is_on(clear)))
  val () = if gowiki andalso ige(target_act, 0) then editor_wiki_focus_act(s, tabs_len(ts7), target_act) else ()
in
  ts7
end

fun is_zone_editor(z: DownZone): bool = case+ z of | DownEditor() => true | _ => false

fun begin_embedded_selection(s: &App_record >> _,f: !Font,r: !Rend,tabs: !Tabs,index: int,
  hit: DownHit,ox: int,width: int,editor: bool,control: bool): void =
  if editor then let
    val selected=tabs_embed_select(f,r,tabs,index,hit.x,hit.y,ox,width,font_line_h(f),s.vault,s.cache,s.scratch,false)
  in () end else ()

fun handle_editor_click(s: &App_record >> _, f: !Font, r: !Rend, ts: Tabs, ev: &event,
                        w: int, hit: DownHit, idx: int, imgdel: Toggle, clear: Toggle): Tabs = let
  val editor = is_zone_editor(hit.zone) andalso is_btn(hit.button, BtnLeft)
  val pw0 = isub(w, hit.sidew)
  val half = if is_on(s.split) then idiv(pw0, 2) else pw0
  val foc = editor andalso is_on(s.split) andalso ige(hit.x, iadd(hit.sidew, half))
  val () = if editor then (s.focus := toggle_of(foc); s.drag := DragEditor; s.downx := hit.x; s.downy := hit.y) else ()
  val ox = if is_on(s.focus) then iadd(hit.sidew, half) else hit.sidew
  val idx2 = pane_of(s.focus, s.active, s.righti)
  val ts4 = editor_click_hit(f, r, s, ts, ev, hit.x, hit.y, ox, half, idx2, toggle_of(editor))
  val ()=begin_embedded_selection(s,f,r,ts4,idx2,hit,ox,half,editor,ctrl_on(ev))
  val gowiki = editor andalso ctrl_on(ev)
  val res = editor_post_click(s, ts4, idx, idx2, imgdel, clear, gowiki)
  val () = if gowiki then s.downx := ~1 else ()
  val () = if editor then s.qfocus := Off else ()
in
  res
end

fun down_pick_tab(s: &App_record >> _, x: int, ti: int, pane: int): void = let
  val () = s.drag := DragNone
  val () = s.dragi := ti
  val () = s.downx := x
  val () = s.downy := s.downy
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
  val onbar = case+ hit.zone of | DownTopbar() => true | _ => false
  val sidew = if not(is_side_none(s.side)) then s.sidew else 0
  val mid = iadd(sidew, idiv(isub(w, sidew), 2))
  val is_r = is_on(s.split) andalso ige(hit.x, mid)
  val pane = (if is_r then 1 else 0)
  val sx = (if is_r then iadd(mid, 4) else tab_x0)
  val filter = (if is_on(s.split) then pane else ~1)
  val () = if onbar andalso ige(hit.x, tab_x0) andalso ilt(hit.x, bx) then
    tab_hit_test_pane(f, r, ts, sx, hit.x, filter, s.tab_pane, ti, close)
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
