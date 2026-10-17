extern fun clear_node_fuel_exhausted(ts: Tabs, idx: int): Tabs = "mac#anth_die_box"

fun clear_node_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), ts: Tabs, idx: int): Tabs =
  if recursion_fuel_available(recfuel) then (
    case+ ts of
    | ~TNil() => TNil()
    | ~TCons(doc, path, title, sc, rest) => let
        val () = if ieq(idx, 0) then clear_doc(doc) else let
          val () = doc_touch(doc)
        in
          ()
        end
      in
        if ieq(idx, 0) then TCons(doc, path, title, sc, rest) else TCons(doc, path, title, sc, clear_node_with_fuel(recfuel - 1, rest, isub(idx, 1)))
      end
  ) else clear_node_fuel_exhausted(ts, idx)

fun clear_node(ts: Tabs, idx: int): Tabs = clear_node_with_fuel(airlock_nat(MAX_REC_FUEL), ts, idx)

fun clear_go(ts: Tabs, idx: int, go: Toggle): Tabs =
  if is_on(go) then clear_node(ts, idx) else ts

fun toggle_go(ts: Tabs, idx: int, ni: int, is_alt: bool, go: Toggle): Tabs =
  if is_on(go) then (
    if is_alt then tabs_toggle_deep(ts, idx, ni)
    else tabs_toggle(ts, idx, ni)
  ) else ts

fun toggle_task_go(ts: Tabs, idx: int, ni: int, go: Toggle): Tabs =
  if is_on(go) then let
    val ts2 = tabs_toggle_task(ts, idx, ni)
    val () = tabs_sync_vfs(ts2, idx)
  in
    ts2
  end else ts

fun open_hit_jump(s: &App_record >> _, srow: int): void = let
  val nwords = idiv(buf_len(s.hjump), WORD32_BYTES)
  val base = imul(srow, SEARCH_JUMP_WORDS)
in
  if ilt(iadd(base, 2), nwords) then let
    val () = s.jump_fid := buf_get32(s.hjump, iadd(base,SEARCH_JUMP_FILE))
    val () = s.jump_line := buf_get32(s.hjump, iadd(base,SEARCH_JUMP_LINE))
    val () = s.jump_col := buf_get32(s.hjump, iadd(base,SEARCH_JUMP_COLUMN))
  in
  end else let
    val () = s.jump_fid := ~1
    val () = s.jump_line := 0
    val () = s.jump_col := 0
  in
  end
end

fun open_hit_file(ts: Tabs, path: !Buf, act: &int >> _): Tabs = let
  val existing = tabs_find_path(ts, path)
in
  if ige(existing, 0) then (act := existing; ts)
  else let
    val res = tabs_open(ts, buffer_clone(path))
    val () = act := isub(tabs_len(res), 1)
  in
    res
  end
end

fun open_hit_target(ts: Tabs,path: !Buf,scope: int,active: &int >> _): Tabs =
  if ieq(scope,SEARCH_SCOPE_DOCUMENT) then ts else open_hit_file(ts,path,active)
fun open_hit(s: &App_record >> _, ts: Tabs, srow: int, go: Toggle): Tabs =
  if is_on(go) then let
    var hitfile = buf_make(OPEN_HIT_HITFILE_INITIAL_BYTES)
    val () = find_hit_file(s.hmeta, s.hits, srow, hitfile)
    val ts2 = open_hit_target(ts,hitfile,s.scope,s.active)
    val () = if ieq(s.scope,SEARCH_SCOPE_VAULT) then s.focus := Off else ()
    val () = buf_free(hitfile)
    val () = open_hit_jump(s, srow)
    val () = s.selected_search_row := srow
  in
    ts2
  end else ts

fun open_created_file(ts: Tabs, dir: !Buf, name: !Buf, kind: PromptKind): Tabs =
  if is_prompt_newfile(kind) then let
    var new_file = buf_make(OPEN_CREATED_FILE_NEW_FILE_INITIAL_BYTES)
    val () = child_path(dir, name, new_file)
    val has_dot = has_dot_char(name, 0)
    val need_md = not(has_dot)
    val () = buffer_append_string_if(new_file, toggle_of(need_md), ".md")
  in
    tabs_open(ts, new_file)
  end else ts

fun apply_tab_cmd(ts: Tabs, cmd: Cmd, idx: int): Tabs =
  if is_cmd(cmd, CMD_CLOSE_TAB) then close_active_tab(ts, idx)
  else if is_cmd(cmd, CMD_NEW_TAB) then new_empty_tab(ts)
  else ts

fun hit_open_if(s: &App_record >> _, ts: Tabs, hn: int, qf: Toggle, qr: EditResult): Tabs =
  if is_on(qf) andalso is_edit_submit(qr) andalso igt(hn, 0) then open_hit(s, ts, 0, On) else ts

fun handle_vault_select_key(s: &App_record >> _, ev: &event): void = let
  val vr = edit_line(s.promptb, ev, s.scratch)
in
  if is_edit_submit(vr) andalso igt(buf_len(s.promptb), 0) then let
    val target = buffer_c_string(s.promptb)
    val () = ensure_dir_report(target)
    val () = switch_to_vault(s, target)
  in
  end else if is_edit_cancel(vr) andalso igt(buf_len(s.vault), 0) then s.vault_select := Off
  else ()
end

fun prompt_fill_paths(s: &App_record, dir: &Buf >> _, cur: &Buf >> _): void = let
  val sel_valid = ige(s.sel, 0) andalso ilt(s.sel, s.tn)
  val () = row_if(s.tree, s.tmeta, s.sel, cur, toggle_of(sel_valid))
  val use_dir = sel_valid andalso is_dir_mark(meta_dir(s.tmeta, s.sel), DirYes)
  val () = fill_dir(dir, cur, s.vault, toggle_of(use_dir), if sel_valid then s.sel else ~1)
in
end

fun submit_open_new_file(s: &App_record >> _, dir: !Buf, prompt_kind: PromptKind): void = let
  val ts_curr = s.tabs
  val () = s.tabs := TNil()
  val ts_next = open_created_file(ts_curr, dir, s.promptb, prompt_kind)
  val ph = s.tabs
  val () = s.tabs := ts_next
  val () = tabs_free(ph)
in
end

fun prompt_reset(s: &App_record >> _): void = let
  val () = s.prompt := PromptNone
  val () = app_fsm_step(s, ActDismissPrompt())
in
  buffer_clear(s.promptb)
end

fun handle_prompt_submission(s: &App_record >> _, pr: EditResult): void =
  if is_edit_submit(pr) andalso igt(buf_len(s.promptb), 0) then let
    var dir = buf_make(HANDLE_PROMPT_SUBMISSION_DIR_INITIAL_BYTES)
    var cur = buf_make(HANDLE_PROMPT_SUBMISSION_CUR_INITIAL_BYTES)
    val () = prompt_fill_paths(s, dir, cur)
    val prompt_kind = s.prompt
    val () = act_prompt(dir, cur, s.promptb, prompt_kind)
    val () = submit_open_new_file(s, dir, prompt_kind)
    val () = if is_prompt_newfile(prompt_kind) then s.active := 0 else ()
    val () = s.prompt := PromptNone
    val () = app_fsm_step(s, ActDismissPrompt())
    val () = buffer_clear(s.promptb)
    val () = (s.treedirty := On; s.search_catalog_ready := false)
    val () = buf_free(dir)
  in
    buf_free(cur)
  end else if is_edit_submit(pr) orelse is_edit_cancel(pr) then prompt_reset(s)
  else ()

fun open_search_panel(s: &App_record >> _, sc: int): void = let
  val () = s.side := SideSearch
  val () = s.qfocus := On
  val () = s.scope := sc
  val ()=buffer_clear(s.query)
in search_job_begin(s) end

fun begin_prompt(s: &App_record >> _, kind: PromptKind): void = let
  val () = s.prompt := kind
  val () = app_fsm_step(s, ActFocusPrompt(kind))
in
  buffer_clear(s.promptb)
end

fun toggle_view_mode(s: &App_record >> _): void = let
  val vm = if is_view_edit(s.viewmode) then ViewRead else ViewEdit
  val () = s.viewmode := vm
in
  save_app_session(s)
end

fun escape_sidebar_state(s: &App_record >> _): void = let
  val () = s.menu := MenuNone
  val () = s.qfocus := Off
  val () = s.prompt := PromptNone
  val () = app_fsm_step(s, ActEscape())
in
  buffer_clear(s.promptb)
end

fun handle_sidebar_shortcut_cmd(s: &App_record >> _, cmd: Cmd, ev: &event): void =
  if is_cmd(cmd, CMD_OPEN_SEARCH) then let
    val kc = key_char(ev)
    val is_doc = ieq(kc, 102) orelse ieq(kc, 70)
  in
    open_search_panel(s, if is_doc then 1 else 0)
  end
  else if is_cmd(cmd, CMD_NEW_FILE) then begin_prompt(s, PromptNewFile)
  else if is_cmd(cmd, CMD_NEW_FOLDER) then begin_prompt(s, PromptNewFolder)
  else if is_cmd(cmd, CMD_TOGGLE_VIEW) then toggle_view_mode(s)
  else if is_cmd(cmd, CMD_ESCAPE) then escape_sidebar_state(s)
  else ()

fun tab_select_close_or_new(s: &App_record >> _, cmd: Cmd, ts_inter: !Tabs): void = let
  val max_i = isub(tabs_len(ts_inter), 1)
  val () = if is_cmd(cmd, CMD_NEW_TAB) then (s.active := max_i; s.preview_tab := ~1)
           else (
             s.active := imax(0, imin(max_i, s.active));
             if ige(s.preview_tab, tabs_len(ts_inter)) then s.preview_tab := ~1 else ()
           )
  val () = s.righti := imax(0, imin(max_i, s.righti))
in
  save_app_session(s)
end
