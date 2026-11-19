fun menu_hover_update(s: &App_record >> _, f: !Font, r: !Rend, x: int, y: int, w: int, h: int): void =
  if is_menu_none(s.menu) then ()
  else let
    val mw = if igt(s.menuw, 0) then s.menuw else UI_MENU_WIDTH
    val in_sub = not(is_sub_none(s.menu_sub)) andalso ige(menu_hit_sub(s.menu_sub, s.menu_sub_x, s.menu_sub_y, s.menu_sub_w, x, y), 0)
  in
    if in_sub then ()
    else let
      val hit_r = menu_hit_root(s.menu_var, s.menux, s.menuy, mw, x, y)
    in
      if ige(hit_r, 0) then let
        val next_sub = menu_var_submenu(s.menu_var, hit_r)
      in
        if not(is_sub_none(next_sub)) then let
          val () = font_set_px(f, s.fontpx)
          val sw = menu_sub_measure_width(f, r, next_sub)
        in
          s.menu_sub := next_sub;
          menu_sub_pos(s.menu_var, next_sub, s.menux, s.menuy, mw, sw, w, h, s.menu_sub_x, s.menu_sub_y, s.menu_sub_w)
        end else s.menu_sub := SubNone
      end else ()
    end
  end

fun seen_bool(b: bool): void =
  if b then () else ()

fun exec_format_action(ts: Tabs, idx: int, act: ContextAction, done: &bool >> _): Tabs =
  case+ act of
  | CtxWikiLink() => (done := true; tabs_wrap(ts, idx, "[[", 2, "]]", 2))
  | CtxExtLink() => (done := true; tabs_wrap(ts, idx, "[", 1, "](https://)", 11))
  | CtxBold() => (done := true; tabs_wrap(ts, idx, "**", 2, "**", 2))
  | CtxItalic() => (done := true; tabs_wrap(ts, idx, "*", 1, "*", 1))
  | CtxStrike() => (done := true; tabs_wrap(ts, idx, "~~", 2, "~~", 2))
  | CtxHighlight() => (done := true; tabs_wrap(ts, idx, "==", 2, "==", 2))
  | _ => ts

fun exec_heading_action(ts: Tabs, idx: int, act: ContextAction, done: &bool >> _): Tabs =
  case+ act of
  | CtxHeading1() => (done := true; tabs_set_line_prefix(ts, idx, "# ", 2))
  | CtxHeading2() => (done := true; tabs_set_line_prefix(ts, idx, "## ", 3))
  | CtxHeading3() => (done := true; tabs_set_line_prefix(ts, idx, "### ", 4))
  | CtxHeading4() => (done := true; tabs_set_line_prefix(ts, idx, "#### ", 5))
  | CtxHeading5() => (done := true; tabs_set_line_prefix(ts, idx, "##### ", 6))
  | CtxHeading6() => (done := true; tabs_set_line_prefix(ts, idx, "###### ", 7))
  | _ => ts

fun exec_para_action(ts: Tabs, idx: int, act: ContextAction, done: &bool >> _): Tabs =
  case+ act of
  | CtxBulletList() => (done := true; tabs_set_line_prefix(ts, idx, "- ", 2))
  | CtxNumberList() => (done := true; tabs_set_line_prefix(ts, idx, "1. ", 3))
  | CtxTaskList() => (done := true; tabs_set_line_prefix(ts, idx, "- [ ] ", 6))
  | _ => exec_heading_action(ts, idx, act, done)

fun tabs_ins_lit(ts: Tabs, idx: int, s: string): Tabs =
  tabs_ins(ts, idx, c_str_ptr(s), c_strlen(s))

fun exec_insert_action(ts: Tabs, idx: int, act: ContextAction, done: &bool >> _): Tabs =
  case+ act of
  | CtxFootnote() => (done := true; tabs_wrap(ts, idx, "[^", 2, "]", 1))
  | CtxTable() => (done := true; tabs_ins_lit(ts, idx, "| Sütun 1 | Sütun 2 |\n| --- | --- |\n|  |  |\n"))
  | CtxCallout() => (done := true; tabs_ins_lit(ts, idx, "\n> [!note] Başlık\n> "))
  | CtxHr() => (done := true; tabs_ins_lit(ts, idx, "\n---\n"))
  | CtxCodeBlock() => (done := true; tabs_wrap(ts, idx, "```\n", 4, "\n```", 4))
  | CtxMathBlock() => (done := true; tabs_wrap(ts, idx, "$$\n", 3, "\n$$", 3))
  | _ => ts

fun exec_clip_action(s: &App_record >> _, p: !Plat, ts: Tabs, idx: int, act: ContextAction): Tabs =
  case+ act of
  | CtxCut() => let
      val () = copy_if(ts, idx, s.clip, On)
      val () = (plat_own(p, false); plat_own(p, true))
      val ts2 = tabs_cmd(ts, idx, CMD_CUT)
      val () = tabs_sync_vfs(ts2, idx)
    in ts2 end
  | CtxCopy() => let
      val () = copy_if(ts, idx, s.clip, On)
      val () = if ieq(buf_len(s.clip), 0) andalso ige(s.hiti, 0) then
        copy_fallback_node_with_fuel(airlock_nat(MAX_REC_FUEL), ts, idx, s.hiti, s.clip)
      else ()
      val () = (plat_own(p, false); plat_own(p, true))
    in ts end
  | CtxPaste() => (s.paste_plain := Off; s.paste := On; plat_paste(p, false); ts)
  | CtxPastePlain() => (s.paste_plain := On; s.paste := On; plat_paste(p, false); ts)
  | CtxSelectAll() => tabs_cmd(ts, idx, CMD_SELECT_ALL)
  | CtxImgCopy() => (clip_image(ts, idx, s.hiti, s.vault, s.clip, On); plat_own(p, false); plat_own(p, true); ts)
  | CtxImgReveal() => (s.side := SideFiles; ts)
  | CtxImgRemove() => del_go(ts, idx, s.hiti, On)
  | _ => ts

fun prefill_rename_prompt(s: &App_record >> _): void = let
  val row = s.menu_tree_idx
  val () = s.side := SideFiles
  val () = s.qfocus := Off
  val () = s.editor_focused := Off
  val () = if ige(row, 0) then s.sel := row else ()
  val () = begin_prompt(s, PromptRename)
in
  if ige(row, 0) andalso ilt(row, s.tn) then let
    var cur = buf_make(256)
    val () = row_path(s.tree, s.tmeta, row, cur)
    val () = base_name(cur, s.promptb)
    val () = if is_dir_mark(meta_dir(s.tmeta, row), DirNo) then strip_md_ext(s.promptb) else ()
  in
    buf_free(cur)
  end else ()
end

fun exec_tree_duplicate(s: &App_record >> _): void = let
  val row = s.menu_tree_idx
in
  if ige(row, 0) andalso ilt(row, s.tn) then let
    var cur = buf_make(256)
    var outp = buf_make(256)
    val () = row_path(s.tree, s.tmeta, row, cur)
    val is_d = is_dir_mark(meta_dir(s.tmeta, row), DirYes)
    val () = if do_duplicate(cur, is_d, outp) then (s.treedirty := On; s.search_catalog_ready := false) else ()
    val () = buf_free(cur)
  in
    buf_free(outp)
  end else ()
end

fun exec_tree_delete(s: &App_record >> _, ts0: Tabs): Tabs = let
  val row = s.menu_tree_idx
in
  if ige(row, 0) andalso ilt(row, s.tn) then let
    var cur = buf_make(256)
    val () = row_path(s.tree, s.tmeta, row, cur)
    val is_d = is_dir_mark(meta_dir(s.tmeta, row), DirYes)
    val ts1 = tab_keep_one(tabs_discard_matching(ts0, cur, is_d), On)
    val n = tabs_len(ts1)
    val () = if ilt(s.active, 0) orelse ige(s.active, n) then s.active := 0 else ()
    val () = if ilt(s.righti, 0) orelse ige(s.righti, n) then s.righti := 0 else ()
    val () = validate_panes_len(s, n)
    val () = seen_bool(do_delete_in_vault(s.vault, cur, is_d))
    val () = (s.sel := ~1; s.menu_tree_idx := ~1; s.treedirty := On; s.search_catalog_ready := false)
    val () = buf_free(cur)
  in
    ts1
  end else ts0
end

fun exec_md_step(ts: Tabs, idx: int, act: ContextAction, done: &bool >> _): Tabs = let
  val t1: Tabs = exec_format_action(ts, idx, act, done)
  val t2: Tabs = (if done then t1 else exec_para_action(t1, idx, act, done)): Tabs
in
  (if done then t2 else exec_insert_action(t2, idx, act, done)): Tabs
end

fun execute_context_action(s: &App_record >> _, p: !Plat, ts0: Tabs, idx: int, act: ContextAction): Tabs =
  case+ act of
  | CtxTreeNewNote() => (begin_prompt(s, PromptNewFile); ts0)
  | CtxTreeNewDir() => (begin_prompt(s, PromptNewFolder); ts0)
  | CtxTreeDuplicate() => (exec_tree_duplicate(s); ts0)
  | CtxTreeRename() => (prefill_rename_prompt(s); ts0)
  | CtxTreeDelete() => exec_tree_delete(s, ts0)
  | _ => let
      var done: bool = false
      val t3: Tabs = exec_md_step(ts0, idx, act, done)
    in
      if done then (tabs_sync_vfs(t3, idx); t3)
      else exec_clip_action(s, p, t3, idx, act)
    end

fun handle_menu_click_v2(
  s: &App_record >> _, p: !Plat, f: !Font, r: !Rend, ts0: Tabs, idx: int, x: int, y: int, keep_open: &bool >> _
): Tabs = let
  val hit_s = if is_sub_none(s.menu_sub) then ~1 else menu_hit_sub(s.menu_sub, s.menu_sub_x, s.menu_sub_y, s.menu_sub_w, x, y)
in
  if ige(hit_s, 0) then (
    keep_open := false;
    execute_context_action(s, p, ts0, idx, menu_sub_action(s.menu_sub, hit_s))
  ) else let
    val mw = if igt(s.menuw, 0) then s.menuw else UI_MENU_WIDTH
    val hit_r = menu_hit_root(s.menu_var, s.menux, s.menuy, mw, x, y)
  in
    if ige(hit_r, 0) then let
      val sub_hit = menu_var_submenu(s.menu_var, hit_r)
    in
      if not(is_sub_none(sub_hit)) then let
        val () = font_set_px(f, s.fontpx)
        val sw = menu_sub_measure_width(f, r, sub_hit)
      in
        keep_open := true;
        s.menu_sub := sub_hit;
        menu_sub_pos(s.menu_var, sub_hit, s.menux, s.menuy, mw, sw, s.last_w, s.last_h, s.menu_sub_x, s.menu_sub_y, s.menu_sub_w);
        ts0
      end else (
        keep_open := false;
        execute_context_action(s, p, ts0, idx, menu_var_action(s.menu_var, hit_r))
      )
    end else (keep_open := false; ts0)
  end
end
