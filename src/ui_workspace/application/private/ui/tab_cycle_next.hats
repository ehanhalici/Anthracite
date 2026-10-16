fun tab_cycle_next(s: &App_record >> _, ts_inter: !Tabs): void = let
  val ntabs = tabs_len(ts_inter)
in
  if igt(ntabs, 1) then let
    val next_i = iadd(s.active, 1)
    val cur_i = if ige(next_i, ntabs) then 0 else next_i
    val () = s.active := cur_i
  in
    save_app_session(s)
  end else ()
end

fun tab_cycle_prev(s: &App_record >> _, ts_inter: !Tabs): void = let
  val ntabs = tabs_len(ts_inter)
in
  if igt(ntabs, 1) then let
    val prev_i = isub(s.active, 1)
    val cur_i = if ilt(prev_i, 0) then isub(ntabs, 1) else prev_i
    val () = s.active := cur_i
  in
    save_app_session(s)
  end else ()
end

fun handle_tab_nav_cmd(s: &App_record >> _, cmd: Cmd, ts_inter: !Tabs): void =
  if is_cmd(cmd, CMD_CLOSE_TAB) orelse is_cmd(cmd, CMD_NEW_TAB) then tab_select_close_or_new(s, cmd, ts_inter)
  else if is_cmd(cmd, CMD_NEXT_TAB) then tab_cycle_next(s, ts_inter)
  else if is_cmd(cmd, CMD_PREV_TAB) then tab_cycle_prev(s, ts_inter)
  else ()

fun run_vault_search(s: &App_record >> _): void = let
  var is_partial: int = 0
  val () = s.hscroll := 0
  val () = ix_match_search(s.query, s.vault, s.tabs, s.ixf, s.ixs, s.ixp, s.ixb, s.hits, s.hmeta, s.hjump, s.hn, s.search_nfiles, is_partial)
  val () = s.search_state := (if is_partial > 0 then 2 else 0)
in
end

fun run_query_refresh(s: &App_record >> _): void =
  if ieq(s.scope, 0) then run_vault_search(s)
  else let
    val () = buffer_clear(s.hits)
    val () = buffer_clear(s.hmeta)
    val () = buffer_clear(s.hjump)
    val () = s.hn := 0
    val () = s.hscroll := 0
  in
  end

fun search_query_edit(s: &App_record >> _, qr: EditResult): void = let
  val changed = is_on(s.qfocus) andalso (is_edit_changed(qr) orelse is_edit_none(qr))
  val () = if changed then run_query_refresh(s) else ()
  val () = if is_on(s.qfocus) andalso is_edit_cancel(qr) then s.qfocus := Off else ()
in
end

fun search_hit_focus(s: &App_record >> _): void = let
  val () = s.qfocus := Off
in
  save_app_session(s)
end

fun run_doc_find(ts: Tabs, idx: int, q: !Buf, sh: Toggle): Tabs = let
  val qlen = buf_len(q)
in
  if ieq(qlen, 0) then ts
  else let
    val from = tabs_caret(ts, idx)
    val dir = if is_on(sh) then ~1 else 1
    val start_pos = if is_on(sh) then isub(from, 1) else iadd(from, 1)
    val off = tabs_find_doc(ts, idx, q, imax(0, start_pos), dir)
    val off2 = if ilt(off, 0) then (
      if is_on(sh) then tabs_find_doc(ts, idx, q, 100000000, dir)
      else tabs_find_doc(ts, idx, q, 0, dir)
    ) else off
  in
    if ige(off2, 0) then tabs_select_range(ts, idx, off2, iadd(off2, qlen))
    else ts
  end
end

fun resolve_search_enter(s: &App_record >> _, ts0: Tabs, qr: EditResult, hit_go: Toggle, ev: &event): Tabs =
  if ieq(s.scope, 1) andalso is_on(s.qfocus) andalso is_edit_submit(qr) then
    run_doc_find(ts0, s.active, s.query, toggle_of(shift_on(ev)))
  else
    hit_open_if(s, ts0, s.hn, toggle_of(is_on(hit_go)), EditSubmit)

fun key_tabs_step(s: &App_record >> _, p: !Plat,f: !Font,r: !Rend, ev: &event, cmd: Cmd, hit_go: Toggle, qr: EditResult): void = let
  val ()=font_set_px(f,s.fontpx)
  val ts0 = s.tabs
  val () = s.tabs := TNil()
  val ts: Tabs = resolve_search_enter(s, ts0, qr, hit_go, ev)
  val idx = pane_of(s.focus, s.active, s.righti)
  var ts_inter: Tabs = apply_tab_cmd(ts, cmd, idx)
  val () = handle_tab_nav_cmd(s, cmd, ts_inter)
  val (ts_source,source_cmd)=tabs_source_edit(f,ts_inter,idx,cmd,s.scratch)
  val (ts_ready,remaining)=tabs_visual_vertical(f,r,ts_source,idx,source_cmd,s.scratch)
  val ts2 = key_dispatch(ts_ready, idx, remaining, s.vault, s.clip, s.scratch, p, s.paste, ev)
  val ph = s.tabs
  val () = s.tabs := ts2
  val () = tabs_free(ph)
  val () = if is_modifying_cmd(cmd) orelse is_cmd(cmd, CMD_TEXT_INPUT) then
    (if ieq(s.active, s.preview_tab) then s.preview_tab := ~1 else ()) else ()
in
end

fun key_editor_step(s: &App_record >> _, p: !Plat, f: !Font,r: !Rend, ev: &event): void = let
  val act = is_prompt_none(s.prompt) andalso is_off(s.qfocus)
  val pr = if not(is_prompt_none(s.prompt)) then edit_line(s.promptb, ev, s.scratch) else EditNone
  val qr = if is_on(s.qfocus) andalso is_prompt_none(s.prompt) then edit_line(s.query, ev, s.scratch) else EditNone
  val () = search_query_edit(s, qr)
  val hit_go = is_on(s.qfocus) andalso is_edit_submit(qr) andalso igt(s.hn, 0)
  val () = if hit_go then search_hit_focus(s) else ()
  val () = handle_prompt_submission(s, pr)
  val cmd = key_code(ev, toggle_of(act))
  val () = if is_cmd(cmd, CMD_ESCAPE) then app_fsm_step(s, ActEscape())
           else if is_modifying_cmd(cmd) orelse is_cmd(cmd, CMD_TEXT_INPUT) then app_fsm_step(s, ActTypeKey())
           else ()
  val () = handle_sidebar_shortcut_cmd(s, cmd, ev)
  val () = key_tabs_step(s, p,f,r, ev, cmd, toggle_of(hit_go), qr)
  val () = if is_cmd(cmd, CMD_SAVE) then let
      val () = s.treedirty := On
      val () = save_app_session(s)
    in
    end else ()
  val () = seen_int(font_line_h(f))
in
end

fun on_key(a: !App, p: !Plat, f: !Font,r: !Rend, ev: &event): void =
  case+ a of
  | @APP(s) =>
      if is_on(s.vault_select) then let
        val () = handle_vault_select_key(s, ev)
      in
        fold@(a)
      end else let
        val () = key_editor_step(s, p, f,r, ev)
      in
        fold@(a)
      end
fun select_vault_row(s: &App_record >> _, vi: int): void =
  if ige(vi, 0) andalso ilt(vi, s.vcnt) then let
    val poff = buf_get32(s.vmeta, imul(vi, 4))
    val plen = buf_get32(s.vmeta, iadd(imul(vi, 4), 1))
    var pbuf = buf_make(SELECT_VAULT_ROW_PBUF_INITIAL_BYTES)
    val () = buffer_append_range(pbuf, s.vpaths, poff, iadd(poff, plen))
    val target = buffer_c_string(pbuf)
    val () = switch_to_vault(s, target)
    val () = buf_free(pbuf)
  in
  end else ()

fun vault_open_from_prompt(s: &App_record >> _): void = let
  val target = buffer_c_string(s.promptb)
  val () = ensure_dir_report(target)
in
  switch_to_vault(s, target)
end

fun handle_vault_select_click(s: &App_record >> _, x: int, y: int, w: int, h: int): void = let
  val mw = 520
  val mh = 360
  val mx = idiv(isub(w, mw), 2)
  val my = idiv(isub(h, mh), 2)
  val in_list_y = ige(y, iadd(my, 74)) andalso ilt(y, iadd(my, iadd(74, imul(imin(s.vcnt, 6), 28))))
  val in_list_x = ige(x, iadd(mx, 16)) andalso ilt(x, isub(iadd(mx, mw), 16))
  val () = if in_list_x andalso in_list_y then select_vault_row(s, idiv(isub(y, iadd(my, 74)), 28)) else ()
  val on_open_btn = ige(x, iadd(mx, 16)) andalso ilt(x, iadd(mx, 156)) andalso ige(y, iadd(my, 312)) andalso ilt(y, iadd(my, 342))
  val () = if on_open_btn andalso igt(buf_len(s.promptb), 0) then vault_open_from_prompt(s) else ()
  val on_cancel_btn = ige(x, isub(iadd(mx, mw), 116)) andalso ilt(x, isub(iadd(mx, mw), 16)) andalso ige(y, iadd(my, 312)) andalso ilt(y, iadd(my, 342))
  val () = if on_cancel_btn andalso igt(buf_len(s.vault), 0) then let
    val () = s.vault_select := Off
  in
  end else ()
in
end

fun handle_context_menu_action(s: &App_record >> _, inside: Toggle, item: int): void =
  if is_on(inside) andalso is_menu_filetree(s.menu) then (
    if ieq(item, tree_row(TreeNewFile)) then s.prompt := PromptNewFile
    else if ieq(item, tree_row(TreeNewFolder)) then s.prompt := PromptNewFolder
    else if ieq(item, tree_row(TreeRename)) then s.prompt := PromptRename
    else if ieq(item, tree_row(TreeDelete)) andalso ige(s.sel, 0) then let
      var cur = buf_make(HANDLE_CONTEXT_MENU_ACTION_CUR_INITIAL_BYTES)
      val () = row_path(s.tree, s.tmeta, s.sel, cur)
      val () = do_delete(cur)
      val () = s.treedirty := On
    in
      buf_free(cur)
    end else ()
  ) else ()

fun topbar_toggle_view(s: &App_record >> _): void = let
  val () = s.viewmode := (if is_view_edit(s.viewmode) then ViewRead else ViewEdit)
in
  save_app_session(s)
end

fun topbar_toggle_files(s: &App_record >> _): void = let
  val () = s.side := (if is_side_files(s.side) then SideNone else SideFiles)
  val () = s.qfocus := Off
in
  save_app_session(s)
end

