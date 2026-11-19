fun tabs_idx_path_eq(ts: !Tabs, idx: int, target: !Buf): bool = let
  var cp = buf_make(256)
  val () = tabs_get_path(ts, idx, cp)
  val same = ieq(c_strcmp(buffer_c_string(cp), buffer_c_string(target)), 0)
  val () = buf_free(cp)
in
  same
end

fun app_push_tab_hist(s: &App_record >> _, ts: !Tabs, target: int, next_path: !Buf): void = let
  val () = app_sync_tab_hists(s, ts)
in
  if not(tabs_idx_path_eq(ts, target, next_path)) then let
    var cp = buf_make(256)
    val () = tabs_get_path(ts, target, cp)
    val csc = tabs_get_scroll(ts, target)
    val cc = tabs_caret(ts, target)
    val hl = app_take_tab_hists(s)
    val () = app_put_tab_hists(s, tab_hist_push(hl, target, cp, csc, cc, next_path, 0, 0))
  in
    buf_free(cp)
  end else ()
end

fun wiki_open_in_place(
  s: &App_record >> _, ts: Tabs, idx: int, anchor: &Buf >> _, shown: Buf, alen: int, target_act: &int >> _
): Tabs =
  if tabs_idx_path_eq(ts, idx, shown) then let
    val () = buf_free(shown)
  in
    wiki_open_existing(ts, idx, anchor, alen, target_act)
  end else let
    val () = app_push_tab_hist(s, ts, idx, shown)
    val ts2 = tabs_open_at(ts, idx, shown)
    val ts3 = tabs_jump_anchor_if(ts2, idx, anchor, alen)
    val () = target_act := idx
  in
    ts3
  end

fun app_wiki_dispatch_in_place(
  s: &App_record >> _, ts: Tabs, idx: int, rlen: int, alen: int, anchor: &Buf >> _, shown: Buf, target_act: &int >> _
): Tabs =
  if rlen < 0 then let
    val () = buf_free(shown)
    val () = target_act := ~1
  in
    ts
  end else if ieq(rlen, 0) then let
    val () = buf_free(shown)
  in
    wiki_open_existing(ts, idx, anchor, alen, target_act)
  end else
    wiki_open_in_place(s, ts, idx, anchor, shown, alen, target_act)

fun app_wiki_open_in_place(s: &App_record >> _, ts: Tabs, idx: int, target_act: &int >> _): Tabs = let
  var anchor = buf_make(APP_WIKI_OPEN_ANCHOR_INITIAL_BYTES)
  var shown = buf_make(APP_WIKI_OPEN_SHOWN_INITIAL_BYTES)
  val rlen = tabs_wiki_prep(ts, idx, s.vault, anchor, shown)
  val alen = buf_len(anchor)
  val ts_out = app_wiki_dispatch_in_place(s, ts, idx, rlen, alen, anchor, shown, target_act)
  val () = buf_free(anchor)
in
  ts_out
end

fun app_embedded_dispatch_in_place(
  s: &App_record >> _, ts: Tabs, index: int, kind: EmbedNavigationKind, path: Buf, anchor: &Buf >> _, target: &int >> _
): Tabs = let
  val length = buf_len(anchor)
in
  case+ kind of
  | EmbedNavigationNone() => let val () = buf_free(path) in app_wiki_open_in_place(s, ts, index, target) end
  | EmbedNavigationFile() => wiki_open_in_place(s, ts, index, anchor, path, length, target)
  | EmbedNavigationExternal() => let
      val () = fs_open_url(buf_cstr(path))
      val () = buf_free(path)
      val () = target := ~1
    in ts end
end

fun app_embedded_nav_in_place(s: &App_record >> _, ts: Tabs, index: int, target: &int >> _): Tabs = let
  var anchor: Buf = buf_make(0)
  var path: Buf = buf_make(0)
  val kind = cache_embed_navigation(s.cache, s.vault, path, anchor)
  val result = app_embedded_dispatch_in_place(s, ts, index, kind, path, anchor, target)
  val () = buf_free(anchor)
in
  result
end

fun wiki_open_file(ts: Tabs, anchor: &Buf >> _, shown: Buf, alen: int, target_act: &int >> _, kept: &ClosedDocs >> _): Tabs = let
  val existing = tabs_find_path(ts, shown)
in
  if ige(existing, 0) then let
    val () = buf_free(shown)
  in
    wiki_open_existing(ts, existing, anchor, alen, target_act)
  end else
    wiki_open_new(ts, anchor, shown, alen, target_act, kept)
end

fun app_wiki_dispatch(ts: Tabs, idx: int, rlen: int, alen: int, anchor: &Buf >> _, shown: Buf, target_act: &int >> _, kept: &ClosedDocs >> _): Tabs =
  if rlen < 0 then let
    val () = buf_free(shown)
    val () = target_act := ~1
  in
    ts
  end else if ieq(rlen, 0) then let
    val () = buf_free(shown)
  in
    wiki_open_existing(ts, idx, anchor, alen, target_act)
  end else
    wiki_open_file(ts, anchor, shown, alen, target_act, kept)

fun app_wiki_open(ts: Tabs, idx: int, vault: !Buf, target_act: &int >> _, kept: &ClosedDocs >> _): Tabs = let
  var anchor = buf_make(APP_WIKI_OPEN_ANCHOR_INITIAL_BYTES)
  var shown = buf_make(APP_WIKI_OPEN_SHOWN_INITIAL_BYTES)
  val rlen = tabs_wiki_prep(ts, idx, vault, anchor, shown)
  val alen = buf_len(anchor)
  val ts_out = app_wiki_dispatch(ts, idx, rlen, alen, anchor, shown, target_act, kept)
  val () = buf_free(anchor)
in
  ts_out
end

fun wiki_open(ts: Tabs, idx: int, vault: !Buf, i: int, kept: &ClosedDocs >> _): Tabs = let
  var dummy: int = ~1
in
  app_wiki_open(ts, idx, vault, dummy, kept)
end

fun app_embedded_navigation(ts: Tabs,index: int,vault: !Buf,cache: !Cache,target: &int >> _,kept: &ClosedDocs >> _): Tabs = let
  var anchor: Buf=buf_make(0)
  var path: Buf=buf_make(0)
  val kind=cache_embed_navigation(cache,vault,path,anchor)
  val result=app_embedded_dispatch(ts,index,vault,kind,path,anchor,target,kept)
  val ()=buf_free(anchor)
in result end
and app_embedded_dispatch(ts: Tabs,index: int,vault: !Buf,kind: EmbedNavigationKind,path: Buf,
  anchor: &Buf >> _,target: &int >> _,kept: &ClosedDocs >> _): Tabs = let val length=buf_len(anchor)
in case+ kind of
  | EmbedNavigationNone() => let val ()=buf_free(path) in app_wiki_open(ts,index,vault,target,kept) end
  | EmbedNavigationFile() => wiki_open_file(ts,anchor,path,length,target,kept)
  | EmbedNavigationExternal() => let
      val ()=fs_open_url(buf_cstr(path)) val ()=buf_free(path) val ()=target := ~1
    in ts end
end

fun close_active_tab(ts: Tabs, idx: int, kept: &ClosedDocs >> _): Tabs = let
  val ts2 = tabs_drop_kept(ts, idx, kept)
in
  if ieq(tabs_len(ts2), 0) then let
    val d = doc_open()
    var p = buf_make(CLOSE_ACTIVE_TAB_BUFFER_INITIAL_BYTES)
    var t = buf_make(CLOSE_ACTIVE_TAB_BUFFER_ALTERNATE_INITIAL_BYTES)
    val () = buffer_append_string(t, "Yeni Not")
  in
    tabs_add(ts2, d, p, t)
  end else ts2
end

fun new_empty_tab(ts: Tabs): Tabs = let
  val d = doc_open()
  var p = buf_make(NEW_EMPTY_TAB_BUFFER_INITIAL_BYTES)
  var t = buf_make(NEW_EMPTY_TAB_BUFFER_ALTERNATE_INITIAL_BYTES)
  val () = buffer_append_string(t, "Yeni Not")
in
  tabs_add(ts, d, p, t)
end

fun key_code_mapped(s: &App_record >> _, ev: &event, act: Toggle): Cmd =
  keymap_resolve(s.keymap, s.chord_active, s.chord_mods, s.chord_key, keymap_event_mods(ev), keymap_event_key(ev), act)

fun is_modifying_cmd(cmd: Cmd): bool =
  is_cmd(cmd, CMD_BACKSPACE) orelse is_cmd(cmd, CMD_DELETE) orelse is_cmd(cmd, CMD_DELETE_SELECTION)
     orelse is_cmd(cmd, CMD_UNDO) orelse is_cmd(cmd, CMD_REDO) orelse is_cmd(cmd, CMD_KILL_LINE)
     orelse is_cmd(cmd, CMD_WRAP_BOLD) orelse is_cmd(cmd, CMD_WRAP_ITALIC) orelse is_cmd(cmd, CMD_WRAP_WIKILINK)
     orelse is_cmd(cmd, CMD_INDENT) orelse is_cmd(cmd, CMD_DELETE_WORD_LEFT) orelse is_cmd(cmd, CMD_DELETE_WORD_RIGHT)

fun apply_key_copy(ts: Tabs, idx: int, clip: &Buf >> _, p: !Plat): Tabs = let
  val () = tabs_copy(ts, idx, clip)
  val () = plat_own(p, false)
  val () = plat_own(p, true)
in
  ts
end

fun apply_key_cut(ts: Tabs, idx: int, clip: &Buf >> _, p: !Plat): Tabs = let
  val ts1 = apply_key_copy(ts, idx, clip, p)
  val ts2 = tabs_cmd(ts1, idx, CMD_DELETE_SELECTION)
  val () = tabs_sync_vfs(ts2, idx)
in
  ts2
end

fun apply_key_paste(ts: Tabs, paste: &Toggle >> _, p: !Plat): Tabs = let
  val () = paste := On
  val () = plat_paste(p, false)
in
  ts
end

fun apply_key_newline(ts: Tabs, idx: int, scratch: &Buf >> _): Tabs = let
  val () = buf_set(scratch, 0, 10)
  val ts2 = tabs_ins_buf(ts, idx, scratch, 1)
  val () = tabs_sync_vfs(ts2, idx)
in
  ts2
end

fun apply_key_command(ts: Tabs, idx: int, cmd: Cmd): Tabs = let
  val ts2 = tabs_cmd(ts, idx, cmd)
  val () = if is_modifying_cmd(cmd) then tabs_sync_vfs(ts2, idx) else ()
in
  ts2
end

fun apply_key(ts: Tabs, idx: int, cmd: Cmd, vault: !Buf, clip: &Buf >> _, scratch: &Buf >> _, p: !Plat, paste: &Toggle >> _): Tabs =
  if is_cmd(cmd, CMD_SAVE) then tabs_ensure_paths(ts, vault)
  else if is_cmd(cmd, CMD_COPY) then apply_key_copy(ts, idx, clip, p)
  else if is_cmd(cmd, CMD_CUT) then apply_key_cut(ts, idx, clip, p)
  else if is_cmd(cmd, CMD_PASTE) then apply_key_paste(ts, paste, p)
  else if is_cmd(cmd, CMD_NEWLINE) then apply_key_newline(ts, idx, scratch)
  else if is_cmd(cmd, CMD_ESCAPE) then tabs_cmd(ts, idx, CMD_COLLAPSE_SELECTION)
  else if not(is_cmd(cmd, CMD_NONE)) then apply_key_command(ts, idx, cmd)
  else ts

fun key_dispatch(ts: Tabs, idx: int, cmd: Cmd, vault: !Buf, clip: &Buf >> _, scratch: &Buf >> _, p: !Plat, paste: &Toggle >> _, ev: &event): Tabs =
  if is_cmd(cmd, CMD_TEXT_INPUT) then
    if ctrl_on(ev) then ts
    else let
      val cap = buf_cap(scratch)
      val raw_n = ev_text_buf(ev, scratch, cap)
      val n = filter_text(scratch, raw_n)
    in
      if igt(n, 0) then let
        val ts2 = tabs_ins_buf(ts, idx, scratch, n)
        val () = tabs_sync_vfs(ts2, idx)
      in
        ts2
      end else ts
    end
  else apply_key(ts, idx, cmd, vault, clip, scratch, p, paste)

fun row_if(tree: !Buf, meta: !Buf, sel: int, cur: &Buf >> _, go: Toggle): void =
  if is_on(go) then row_path(tree, meta, sel, cur) else buffer_preserve(cur)

fun fill_dir_cwd(dir: &Buf >> _): void = let
  var cwd_buf = buf_make(FILL_DIR_CWD_CWD_BUF_INITIAL_BYTES)
  val () = seen_int(c_cwd_buf(cwd_buf, 511))
  val () = buffer_append_string(dir, buf_cstr(cwd_buf))
in
  buf_free(cwd_buf)
end

fun fill_dir_from_dirname(dir: &Buf >> _, cur: !Buf, vault: !Buf): void = let
  val () = dirname_of(cur, dir)
  val () = if ieq(buf_len(dir), 0) andalso igt(buf_len(vault), 0) then buffer_append_range(dir, vault, 0, buf_len(vault)) else ()
in
end
