fun iand(a: int, n: int): int = anth_iand(a, n)

fun plat_read_buf(p: !Plat, ev: &event, dst: !Buf, cap: int): int =
  plat_read(p, ev, buf_ptr(dst), cap)

fun plat_reply_buf(p: !Plat, ev: &event, data: !Buf, n: int): void =
  plat_reply(p, ev, buf_ptr(data), n)

fun ev_text_buf(ev: &event, dst: !Buf, n: int): int =
  ev_text(ev, buf_ptr(dst), n)

typedef SearchDocumentStamp = @{document=ptr,generation=int}
vtypedef App_record = @{
  vault= Buf, tabs= Tabs, cache= Cache,
  active= int, righti= int, split= Toggle, focus= Toggle, side= Sidebar, fontpx= int, doc_fontpx= int,
  clip= Buf, menu= MenuKind, menux= int, menuy= int, drag= DragKind, dragi= int,
  prompt= PromptKind, promptb= Buf, query= Buf, qfocus= Toggle,
  tree= Buf, tmeta= Buf, topen= Buf, tn= int, treescroll= int,
  hits= Buf, hmeta= Buf, hn= int,
  ixf= Buf, ixs= Buf, ixp= Buf, ixb= Buf, ixq= Buf, hjump= Buf,
  jump_line= int, jump_col= int, jump_fid= int,
  scope= int, hscroll= int, search_state= int, search_nfiles= int,
  search_pattern= Option_vt(LiteralPattern), search_cursor= int, search_document= int,
  search_source= SearchDocumentStamp,
  search_skipped= bool, search_catalog_ready= bool, search_layout= SearchGeometry,
  sel= int, treedirty= Toggle, paste= Toggle, hitk= NodeKind, hiti= int, downx= int, downy= int,
  scratch= Buf, imgpath= Buf, viewmode= ViewMode, font_idx= int,
  fpaths= Buf, fnames= Buf, fmeta= Buf, fcnt= int, font_path= Buf,
  vault_select= Toggle, vpaths= Buf, vnames= Buf, vmeta= Buf, vcnt= int,
  hoverx= int, hovery= int, sidew= int, btnw= int, modew= int, menuw= int,
  tb_h= int, hdr_h= int,
  editor_focused= Toggle, cursor_pane= int, click_was_raw= Toggle, click_ctrl= Toggle,
  tree_flash_row= int, tree_flash_until_ns= lint,
  tab_pane= Buf, open_dirs= Buf, selected_search_row= int, flash_until_ns= lint,
  fsm= EditorState,
  tab_hists= TabHistList, keymap= Buf,
  chord_active= Toggle, chord_mods= int, chord_key= int,
  doc_h_left= int, doc_h_right= int, doc_vh= int, doc_top_y= int,
  scroll_drag_pane= int, scroll_drag_grab_y= int,
  pan_start_y= int, pan_start_scroll= int,
  tree_drag_pending= Toggle, last_w= int, last_h= int
}
datavtype App_ = APP of App_record
(* skill.md 1. kural istisnasi: ATS2 soyut tip gerceklemesi (sats'taki absviewtype). Kanit disi cast veya ham C yoktur. *)
assume App = App_
extern fun search_job_clear(s: &App_record >> _): void

datatype DownZone = DownMenu | DownResize | DownTopbar | DownSidebar | DownEditor

typedef DownHit = @{
  x= int, y= int, sidew= int, button= Btn,
  zone= DownZone, inside= Toggle, item= int
}

fun tab_pane_has_val_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), b: !Buf, pane: int, i: int): bool =
  if recursion_fuel_available(recfuel) then (
    if i >= buf_len(b) then false
    else if buf_get(b, i) = pane then true
    else tab_pane_has_val_with_fuel(recfuel - 1, b, pane, i + 1)
  ) else false

fun tab_pane_has(b: !Buf, pane: int): bool =
  tab_pane_has_val_with_fuel(airlock_nat(MAX_REC_FUEL), b, pane, 0)

fun sync_tab_pane_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), tab_pane: &Buf >> _, n: int, sp: Toggle, righti: int): void =
  if recursion_fuel_available(recfuel) then (
    if buf_len(tab_pane) < n then let
      val () = buf_push(tab_pane, 0)
    in
      sync_tab_pane_with_fuel(recfuel - 1, tab_pane, n, sp, righti)
    end else if buf_len(tab_pane) > n then buf_set_len(tab_pane, n)
    else ()
  ) else ()

fun sync_tab_pane(tab_pane: &Buf >> _, n: int, sp: Toggle, righti: int): void =
  sync_tab_pane_with_fuel(airlock_nat(MAX_REC_FUEL), tab_pane, n, sp, righti)

fun tab_pane_find_first_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), b: !Buf, pane: int, i: int): int =
  if recursion_fuel_available(recfuel) then (
    if i >= buf_len(b) then ~1
    else if buf_get(b, i) = pane then i
    else tab_pane_find_first_with_fuel(recfuel - 1, b, pane, i + 1)
  ) else ~1

fun tab_pane_find_first(b: !Buf, pane: int): int =
  tab_pane_find_first_with_fuel(airlock_nat(MAX_REC_FUEL), b, pane, 0)

fun tab_pane_fill_all_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), b: !Buf, n: int, v: int, i: int
): void =
  if recursion_fuel_available(recfuel) then (
    if i < n andalso i < buf_len(b) then let
      val () = buf_set(b, i, v)
    in
      tab_pane_fill_all_with_fuel(recfuel - 1, b, n, v, i + 1)
    end else ()
  ) else ()

fun tab_pane_fill_all(b: !Buf, n: int, v: int): void =
  tab_pane_fill_all_with_fuel(airlock_nat(MAX_REC_FUEL), b, n, v, 0)

fun tab_pane_init_split(b: &Buf >> _, n: int, right_i: int): void = let
  val () = sync_tab_pane(b, n, On, right_i)
  val () = tab_pane_fill_all(b, n, 0)
  val () = if right_i >= 0 andalso right_i < buf_len(b) then buf_set(b, right_i, 1) else ()
in
end

fun save_session_impl(
  vault: !Buf, font_p: !Buf, font_px: int, doc_font_px: int, viewmode: ViewMode,
  split: Toggle, active: int, righti: int, side_open: int, sidew: int,
  tab_pane: !Buf, open_dirs: !Buf, ts: !Tabs
): void =
  if igt(buf_len(vault), 0) then
    conf_save_session_ex(buffer_c_string(vault), buffer_c_string(font_p), font_px, doc_font_px, view_mode_code(viewmode), toggle_int(split), active, righti, side_open, sidew, tab_pane, open_dirs, ts)
  else ()

fun collect_open_dirs_m {rem:nat} .<rem>. (
  tree: !Buf, meta: !Buf, topen: !Buf, open_dirs: &Buf >> Buf, i: int, rem: int(rem)
): void =
  if rem > 0 then let
    val is_dir = is_dir_mark(meta_dir(meta, i), DirYes)
    val is_open = ieq(buf_get(topen, i), 1)
    val () = if is_dir andalso is_open then let
      val off = buf_get32(meta, iadd(imul(i, 4), 2))
      val n = buf_get32(meta, iadd(imul(i, 4), 3))
    in
      buffer_append_range(open_dirs, tree, off, iadd(off, n));
      buf_push(open_dirs, CHAR_LF)
    end else ()
  in
    collect_open_dirs_m(tree, meta, topen, open_dirs, iadd(i, 1), rem - 1)
  end else buffer_preserve(open_dirs)

fun collect_open_dirs(tree: !Buf, meta: !Buf, topen: !Buf, n: int, open_dirs: &Buf >> Buf): void = let
  val () = buffer_clear(open_dirs)
in
  if igt(n, 0) then collect_open_dirs_m(tree, meta, topen, open_dirs, 0, airlock_nat(n))
  else buffer_preserve(open_dirs)
end

fun sync_open_dirs_from_tree(s: &App_record >> _): void =
  if igt(s.tn, 0) then
    collect_open_dirs(s.tree, s.tmeta, s.topen, s.tn, s.open_dirs)
  else ()

fun save_app_prefs(s: &App_record): void =
  conf_save_prefs(buffer_c_string(s.font_path), s.fontpx, s.doc_fontpx, s.sidew)

fun save_app_session(s: &App_record >> _): void = let
  val () = save_app_prefs(s)
  val n = tabs_len(s.tabs)
in
  if n > 0 then let
    val () = sync_open_dirs_from_tree(s)
    val () = sync_tab_pane(s.tab_pane, n, s.split, s.righti)
    val side_open = (if is_side_none(s.side) then 0 else 1)
  in
    save_session_impl(s.vault, s.font_path, s.fontpx, s.doc_fontpx, s.viewmode, s.split, s.active, s.righti, side_open, s.sidew, s.tab_pane, s.open_dirs, s.tabs)
  end else ()
end

fun make_empty_tabs(): Tabs = let
  var title = buf_make(MAKE_EMPTY_TABS_TITLE_INITIAL_BYTES)
  val () = buffer_append_string(title, "Isimsiz")
  var path = buf_make(MAKE_EMPTY_TABS_PATH_INITIAL_BYTES)
  val doc = doc_open()
in
  tabs_add(TNil(), doc, path, title)
end

fun tabs_fallback(ts: Tabs): Tabs =
  case+ ts of
  | ~TNil() => make_empty_tabs()
  | ~TCons(d, p, t, s, rest) => TCons(d, p, t, s, rest)

fun apply_tab_indices(
  n_tabs: int, act_idx: int, right_idx: int, out_act: &int >> int, out_righti: &int >> int
): void = let
  val () = out_act := imax(0, imin(isub(n_tabs, 1), act_idx))
  val () = out_righti := imax(0, imin(isub(n_tabs, 1), right_idx))
in
end

fun load_vault_tabs(
  target: string, font_path: &Buf >> Buf, out_fpx: &int >> int, out_dfpx: &int >> int,
  out_vm: &int >> int, out_sp: &int >> int, out_act: &int >> int,
  out_righti: &int >> int, out_side_open: &int >> int, out_sidew: &int >> int,
  out_tab_pane: &Buf >> Buf, out_open_dirs: &Buf >> Buf
): Tabs = let
  var fpx: int = 18; var dfpx: int = 18; var vmode: int = 0; var sp: int = 0; var act_idx: int = 0; var right_idx: int = 0
  var side_open: int = 1; var sidew: int = UI_SIDEBAR_WIDTH
  val loaded_tabs = conf_load_session_ex(target, font_path, fpx, dfpx, vmode, sp, act_idx, right_idx, side_open, sidew, out_tab_pane, out_open_dirs, TNil())
  val has_prefs = conf_load_prefs(font_path, fpx, dfpx, sidew)
  val () = if not(has_prefs) andalso igt(buf_len(font_path), 0) then conf_save_prefs(buffer_c_string(font_path), fpx, dfpx, sidew) else ()
  val new_tabs = tabs_fallback(loaded_tabs)
  val () = if ieq(buf_len(out_tab_pane), 0) then buf_push(out_tab_pane, 0) else ()
  val n_tabs = tabs_len(new_tabs)
  val () = out_fpx := (if igt(fpx, 0) then fpx else 18)
  val () = out_dfpx := (if igt(dfpx, 0) then dfpx else out_fpx)
  val () = out_vm := vmode
  val () = out_sp := (if is_on(toggle_of(ieq(sp, 1))) andalso tab_pane_has(out_tab_pane, 1) then 1 else 0)
  val tp_len = buf_len(out_tab_pane)
  val () = if ieq(out_sp, 0) then tab_pane_fill_all(out_tab_pane, tp_len, 0) else ()
  val () = out_side_open := side_open
  val () = out_sidew := imax(UI_SIDEBAR_MIN_WIDTH, sidew)
  val () = apply_tab_indices(n_tabs, act_idx, right_idx, out_act, out_righti)
in
  new_tabs
end

fun init_vault_tabs_empty(
  out_fpx: &int >> int, out_dfpx: &int >> int, out_vm: &int >> int, out_sp: &int >> int,
  out_act: &int >> int, out_righti: &int >> int,
  out_side_open: &int >> int, out_sidew: &int >> int,
  out_tab_pane: &Buf >> Buf, out_open_dirs: &Buf >> Buf
): Tabs = let
  val () = out_fpx := 18; val () = out_dfpx := 18; val () = out_vm := 0; val () = out_sp := 0
  val () = out_act := 0; val () = out_righti := 0
  val () = out_side_open := 1; val () = out_sidew := UI_SIDEBAR_WIDTH
  val () = buffer_clear(out_tab_pane); val () = buf_push(out_tab_pane, 0)
  val () = buffer_clear(out_open_dirs)
in
  make_empty_tabs()
end

fun doc_top_y_of(s: &App_record): int =
  iadd(s.tb_h, s.hdr_h)

fun tree_top_y_of(s: &App_record): int =
  iadd(doc_top_y_of(s), 8)

fun tree_row_h(fontpx: int): int =
  imax(UI_TREE_ROW_HEIGHT, iadd(fontpx, 8))

fun topbar_tabs_x0(s: &App_record): int = let
  val ox = if not(is_side_none(s.side)) then s.sidew else 0
in
  imax(iadd(imul(3, s.btnw), 8), if igt(ox, 0) then iadd(ox, 6) else 0)
end

fun side_divider_hovered(s: &App_record): bool =
  not(is_side_none(s.side)) andalso ige(s.hovery, s.tb_h)
    andalso ige(s.hoverx, isub(s.sidew, idiv(UI_SIDEBAR_GRAB_WIDTH, 2)))
    andalso ilt(s.hoverx, iadd(s.sidew, idiv(UI_SIDEBAR_GRAB_WIDTH, 2)))

typedef CfgLayout = @{
  lh= int, btn_h= int, frow_h= int,
  vault_lbl_y= int, vault_path_y= int, vault_btn_y= int, vault_btn_w= int,
  ed_lbl_y= int, ed_sldr_y= int,
  doc_lbl_y= int, doc_sldr_y= int,
  eng_title_y= int, font_list_y= int,
  kb_y= int, kb_rows_y= int, kb_btn_x= int, kb_btn_w= int
}

fun config_layout_tail(
  top_y: int, lh: int, btn_h: int, frow_h: int, vb_y: int, vb_w: int, kb_w: int, sidew: int, fcnt: int
): CfgLayout = let
  val ed_ly = iadd(vb_y, iadd(btn_h, 12))
  val ed_sy = iadd(ed_ly, iadd(lh, 10))
  val doc_ly = iadd(ed_sy, 20)
  val doc_sy = iadd(doc_ly, iadd(lh, 10))
  val eng_y = iadd(doc_sy, 22)
  val fl_y = iadd(eng_y, iadd(lh, 4))
  val kb_y = iadd(fl_y, iadd(imul(imin(fcnt, 12), frow_h), 10))
in @{
  lh= lh, btn_h= btn_h, frow_h= frow_h,
  vault_lbl_y= top_y, vault_path_y= iadd(top_y, iadd(lh, 2)), vault_btn_y= vb_y, vault_btn_w= vb_w,
  ed_lbl_y= ed_ly, ed_sldr_y= ed_sy, doc_lbl_y= doc_ly, doc_sldr_y= doc_sy,
  eng_title_y= eng_y, font_list_y= fl_y, kb_y= kb_y, kb_rows_y= iadd(kb_y, iadd(btn_h, 6)),
  kb_btn_x= imax(12, isub(sidew, iadd(kb_w, 12))), kb_btn_w= kb_w
} end

fun config_layout_step(top_y: int, lh: int, fontpx: int, sidew: int, fcnt: int): CfgLayout = let
  val btn_h = imax(22, iadd(lh, 6))
  val frow_h = imax(22, iadd(lh, 4))
  val vb_y = iadd(iadd(top_y, iadd(lh, 2)), iadd(lh, 6))
  val max_bw = imax(80, isub(sidew, 24))
  val vb_w = imin(max_bw, imax(150, iadd(imul(fontpx, 10), 24)))
  val kb_w = imin(max_bw, imax(88, iadd(imul(fontpx, 4), 24)))
in
  config_layout_tail(top_y, lh, btn_h, frow_h, vb_y, vb_w, kb_w, sidew, fcnt)
end

fun config_layout(f: !Font, s: &App_record): CfgLayout =
  config_layout_step(iadd(doc_top_y_of(s), 12), imax(18, font_line_h(f)), s.fontpx, s.sidew, s.fcnt)
