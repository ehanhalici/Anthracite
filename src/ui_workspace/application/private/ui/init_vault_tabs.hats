fun init_vault_tabs(
  vb: !Buf, f_vsel: Toggle, font_path: &Buf >> Buf,
  out_fpx: &int >> int, out_vm: &int >> int, out_sp: &int >> int,
  out_act: &int >> int, out_righti: &int >> int,
  out_side_open: &int >> int, out_sidew: &int >> int,
  out_tab_pane: &Buf >> Buf, out_open_dirs: &Buf >> Buf
): Tabs =
  if ieq(buf_len(vb), 0) orelse is_on(f_vsel) then
    init_vault_tabs_empty(out_fpx, out_vm, out_sp, out_act, out_righti, out_side_open, out_sidew, out_tab_pane, out_open_dirs)
  else let
    val () = conf_set_active_vault(buffer_c_string(vb))
  in
    load_vault_tabs(buffer_c_string(vb), font_path, out_fpx, out_vm, out_sp, out_act, out_righti, out_side_open, out_sidew, out_tab_pane, out_open_dirs)
  end

fun switch_vault_tabs(
  old_tabs: Tabs, target: string, font_path: &Buf >> Buf,
  out_fpx: &int >> int, out_vm: &int >> int, out_sp: &int >> int,
  out_act: &int >> int, out_righti: &int >> int,
  out_side_open: &int >> int, out_sidew: &int >> int,
  out_tab_pane: &Buf >> Buf, out_open_dirs: &Buf >> Buf
): Tabs = let
  val () = tabs_save_all_physical(old_tabs)
  val () = tabs_free(old_tabs)
in
  load_vault_tabs(target, font_path, out_fpx, out_vm, out_sp, out_act, out_righti, out_side_open, out_sidew, out_tab_pane, out_open_dirs)
end

fun vault_switch_begin(s: &App_record >> _, target: string): void = let
  val () = save_app_session(s)
  val () = buffer_clear(s.vault)
  val () = buffer_append_string(s.vault, target)
  val () = conf_set_active_vault(target)
in
end

fun reset_index_state(s: &App_record >> _): void = let
  val () = buffer_clear(s.ixf); val () = buffer_clear(s.ixs); val () = buffer_clear(s.ixp)
  val () = buffer_clear(s.ixb); val () = buffer_clear(s.ixq); val () = buffer_clear(s.hjump)
  val () = s.jump_line := ~1; val () = s.jump_col := ~1; val () = s.jump_fid := ~1
  val () = s.scope := 0; val () = s.hscroll := 0; val () = s.search_state := 0
in
  s.search_nfiles := 0
end

fun vault_switch_finish(
  s: &App_record >> _, new_t: Tabs, fpx: int, vm: int, sp: int,
  act: int, righti: int, side_open: int, sidew: int
): void = let
  val ph = s.tabs
  val () = s.tabs := new_t
  val () = tabs_free(ph)
  val () = s.fontpx := fpx
  val () = s.btnw := 0
  val () = s.viewmode := view_mode_of_code(vm)
  val () = s.split := toggle_of(ieq(sp, 1))
  val () = s.active := act
  val () = s.righti := righti
  val () = s.side := (if ieq(side_open, 1) then SideFiles else SideNone)
  val () = s.sidew := sidew
  val () = s.treedirty := On
  val () = buffer_clear(s.promptb)
  val () = s.vault_select := Off
  val () = reset_index_state(s)
in
end

fun switch_to_vault(s: &App_record >> _, target: string): void = let
  val () = log_info("APP", "switch_to_vault", target)
  val () = vault_switch_begin(s, target)
  val old_t = s.tabs
  val () = s.tabs := TNil()
  var n_fpx: int = 18
  var n_vm: int = 0
  var n_sp: int = 0
  var n_act: int = 0
  var n_righti: int = 0
  var n_side_open: int = 1
  var n_sidew: int = UI_SIDEBAR_WIDTH
  val new_t = switch_vault_tabs(old_t, target, s.font_path, n_fpx, n_vm, n_sp, n_act, n_righti, n_side_open, n_sidew, s.tab_pane, s.open_dirs)
  val () = vault_switch_finish(s, new_t, n_fpx, n_vm, n_sp, n_act, n_righti, n_side_open, n_sidew)
in
end

fun set_vault_from_active(vb: &Buf >> Buf, out_vsel: &int >> int, s_act: string): void = let
  val () = buffer_append_string(vb, s_act)
  val () = out_vsel := 0
in
end

fun set_vault_from_picker(out_vsel: &int >> int): void = let
  val () = out_vsel := 1
in
end

fun resolve_vault_buffer(vb: &Buf >> Buf, out_vsel: &int >> int): void =
  if ieq(buf_len(vb), 0) then let
    var act = buf_make(RESOLVE_VAULT_BUFFER_ACT_INITIAL_BYTES)
    val found = conf_get_active_vault(act)
    val s_act = buffer_c_string(act)
    val act_ex = if igt(buf_len(act), 0) then fs_exists(s_act) else 0
    val () = if found andalso ieq(act_ex, 1) then set_vault_from_active(vb, out_vsel, s_act)
      else set_vault_from_picker(out_vsel)
    val () = buf_free(act)
  in
    ()
  end else let
    val () = conf_set_active_vault(buffer_c_string(vb))
    val () = out_vsel := 0
  in
    ()
  end

fun pick_first_font(fpath: &Buf >> Buf, fpaths: !Buf, fmeta: !Buf, fcnt: int): void =
  if ieq(buf_len(fpath), 0) andalso igt(fcnt, 0) then let
    val poff = buf_get32(fmeta, 0)
    val plen = buf_get32(fmeta, 1)
    val () = buffer_append_range(fpath, fpaths, poff, iadd(poff, plen))
  in
    ()
  end else ()

fun open_resolve_vault(vault: string): @(Buf, int) = let
  var vb = buf_make(OPEN_RESOLVE_VAULT_BUFFER_INITIAL_BYTES)
  val () = buffer_append_string(vb, vault)
  var f_vsel: int = 0
  val () = resolve_vault_buffer(vb, f_vsel)
in
  @(vb, f_vsel)
end

fun open_scan_fonts(): @(Buf, Buf, Buf, int) = let
  var fpaths = buf_make(OPEN_SCAN_FONTS_FPATHS_INITIAL_BYTES)
  var fnames = buf_make(OPEN_SCAN_FONTS_FNAMES_INITIAL_BYTES)
  var fmeta = buf_make(OPEN_SCAN_FONTS_FMETA_INITIAL_BYTES)
  var fcnt: int = 0
  val () = font_scan_fonts("fonts", fpaths, fnames, fmeta, fcnt)
in
  @(fpaths, fnames, fmeta, fcnt)
end

fun open_scan_vaults(): @(Buf, Buf, Buf, int) = let
  var vpaths = buf_make(OPEN_SCAN_VAULTS_VPATHS_INITIAL_BYTES)
  var vnames = buf_make(OPEN_SCAN_VAULTS_VNAMES_INITIAL_BYTES)
  var vmeta = buf_make(OPEN_SCAN_VAULTS_VMETA_INITIAL_BYTES)
  var vcnt: int = 0
  val () = conf_list_vaults(vpaths, vnames, vmeta, vcnt)
in
  @(vpaths, vnames, vmeta, vcnt)
end

fun open_init_session(
  vb: !Buf, f_vsel: Toggle, fpaths: !Buf, fmeta: !Buf, fcnt: int,
  tab_pane: &Buf >> Buf, open_dirs: &Buf >> Buf
): @(Tabs, Buf, int, int, int, int, int, int, int) = let
  var fpath = buf_make(OPEN_INIT_SESSION_FPATH_INITIAL_BYTES)
  var fpx: int = 18
  var vmode: int = 0
  var sp: int = 0
  var act_idx: int = 0
  var right_idx: int = 0
  var side_open: int = 1
  var sidew: int = UI_SIDEBAR_WIDTH
  val tabs = init_vault_tabs(vb, f_vsel, fpath, fpx, vmode, sp, act_idx, right_idx, side_open, sidew, tab_pane, open_dirs)
  val () = pick_first_font(fpath, fpaths, fmeta, fcnt)
in
  @(tabs, fpath, fpx, vmode, sp, act_idx, right_idx, side_open, sidew)
end

fun app_record_make(
  vb: Buf, tabs: Tabs, fpaths: Buf, fnames: Buf, fmeta: Buf, fcnt: int,
  vpaths: Buf, vnames: Buf, vmeta: Buf, vcnt: int, tab_pane: Buf, open_dirs: Buf,
  fpath: Buf, fpx: int, vmode: int, sp: int, act_idx: int, right_idx: int,
  side_open: int, sidew: int, f_vsel: int
): App_record = @{
  vault= vb, tabs= tabs, cache= CNil(), active= act_idx, righti= right_idx, split= toggle_of(ieq(sp, 1)),
  focus= Off, side= (if ieq(side_open, 1) then SideFiles else SideNone), fontpx= fpx, clip= buf_make(APP_RECORD_MAKE_CLIP_INITIAL_BYTES), menu= MenuNone, menux= 0, menuy= 0,
  drag= DragNone, dragi= ~1, prompt= PromptNone, promptb= buf_make(APP_RECORD_MAKE_PROMPTB_INITIAL_BYTES), query= buf_make(APP_RECORD_MAKE_QUERY_INITIAL_BYTES), qfocus= Off,
  tree= buf_make(APP_RECORD_MAKE_TREE_INITIAL_BYTES), tmeta= buf_make(APP_RECORD_MAKE_TMETA_INITIAL_BYTES), topen= buf_make(APP_RECORD_MAKE_TOPEN_INITIAL_BYTES), tn= 0, treescroll= 0, hits= buf_make(APP_RECORD_MAKE_HITS_INITIAL_BYTES),
  hmeta= buf_make(APP_RECORD_MAKE_HMETA_INITIAL_BYTES), hn= 0, ixf= buf_make(APP_RECORD_MAKE_IXF_INITIAL_BYTES), ixs= buf_make(APP_RECORD_MAKE_IXS_INITIAL_BYTES), ixp= buf_make(APP_RECORD_MAKE_IXP_INITIAL_BYTES), ixb= buf_make(APP_RECORD_MAKE_IXB_INITIAL_BYTES),
  ixq= buf_make(APP_RECORD_MAKE_IXQ_INITIAL_BYTES), hjump= buf_make(APP_RECORD_MAKE_HJUMP_INITIAL_BYTES), jump_line= ~1, jump_col= ~1, jump_fid= ~1, scope= 0,
  hscroll= 0, search_state= 0, search_nfiles= 0, sel= ~1, treedirty= On, paste= Off, hitk= KNone,
  hiti= ~1, downx= ~1, downy= ~1, scratch= buf_make(APP_RECORD_MAKE_SCRATCH_INITIAL_BYTES), imgpath= buf_make(APP_RECORD_MAKE_IMGPATH_INITIAL_BYTES),
  viewmode= view_mode_of_code(vmode), font_idx= 0, fpaths= fpaths, fnames= fnames, fmeta= fmeta,
  fcnt= fcnt, font_path= fpath, vault_select= toggle_of(ieq(f_vsel, 1)), vpaths= vpaths, vnames= vnames,
  vmeta= vmeta, vcnt= vcnt, hoverx= ~1, hovery= ~1, sidew= (if igt(sidew, 0) then sidew else UI_SIDEBAR_WIDTH), btnw= 0, modew= 0,
  menuw= 0, preview_tab= ~1, last_tree_row= ~1, last_tree_time= 0L, tab_pane= tab_pane,
  open_dirs= open_dirs, flash_line= ~1, flash_until_ns= 0L,
  fsm= StateIdle()
}

fun app_fsm_step(s: &App_record >> _, act: EditorAction): void = let
  val next_st = editor_fsm_step(s.fsm, act)
  val () = log_debug("FSM", "transition", editor_fsm_name(next_st))
in
  s.fsm := next_st
end


implement app_open(vault) = let
  val @(vb, f_vsel) = open_resolve_vault(vault)
  val @(fpaths, fnames, fmeta, fcnt) = open_scan_fonts()
  val @(vpaths, vnames, vmeta, vcnt) = open_scan_vaults()
  var tab_pane = buf_make(APP_OPEN_TAB_PANE_INITIAL_BYTES)
  var open_dirs = buf_make(APP_OPEN_OPEN_DIRS_INITIAL_BYTES)
  val @(tabs, fpath, fpx, vmode, sp, act_idx, right_idx, side_open, sidew) =
    open_init_session(vb, toggle_of(ieq(f_vsel, 1)), fpaths, fmeta, fcnt, tab_pane, open_dirs)
  val r = app_record_make(
    vb, tabs, fpaths, fnames, fmeta, fcnt, vpaths, vnames, vmeta, vcnt,
    tab_pane, open_dirs, fpath, fpx, vmode, sp, act_idx, right_idx,
    side_open, sidew, f_vsel
  )
in
  APP(r)
end

