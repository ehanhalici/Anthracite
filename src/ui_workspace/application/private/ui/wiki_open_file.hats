fun wiki_open_file(ts: Tabs, anchor: &Buf >> _, shown: Buf, alen: int, target_act: &int >> _): Tabs = let
  val existing = tabs_find_path(ts, shown)
in
  if ige(existing, 0) then let
    val () = buf_free(shown)
  in
    wiki_open_existing(ts, existing, anchor, alen, target_act)
  end else
    wiki_open_new(ts, anchor, shown, alen, target_act)
end

fun app_wiki_dispatch(ts: Tabs, idx: int, rlen: int, alen: int, anchor: &Buf >> _, shown: Buf, target_act: &int >> _): Tabs =
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
    wiki_open_file(ts, anchor, shown, alen, target_act)

fun app_wiki_open(ts: Tabs, idx: int, vault: !Buf, target_act: &int >> _): Tabs = let
  var anchor = buf_make(APP_WIKI_OPEN_ANCHOR_INITIAL_BYTES)
  var shown = buf_make(APP_WIKI_OPEN_SHOWN_INITIAL_BYTES)
  val rlen = tabs_wiki_prep(ts, idx, vault, anchor, shown)
  val alen = buf_len(anchor)
  val ts_out = app_wiki_dispatch(ts, idx, rlen, alen, anchor, shown, target_act)
  val () = buf_free(anchor)
in
  ts_out
end

fun wiki_open(ts: Tabs, idx: int, vault: !Buf, i: int): Tabs = let
  var dummy: int = ~1
in
  app_wiki_open(ts, idx, vault, dummy)
end

fun app_embedded_navigation(ts: Tabs,index: int,vault: !Buf,cache: !Cache,target: &int >> _): Tabs = let
  var anchor: Buf=buf_make(0)
  var path: Buf=buf_make(0)
  val kind=cache_embed_navigation(cache,vault,path,anchor)
  val result=app_embedded_dispatch(ts,index,vault,kind,path,anchor,target)
  val ()=buf_free(anchor)
in result end
and app_embedded_dispatch(ts: Tabs,index: int,vault: !Buf,kind: EmbedNavigationKind,path: Buf,
  anchor: &Buf >> _,target: &int >> _): Tabs = let val length=buf_len(anchor)
in case+ kind of
  | EmbedNavigationNone() => let val ()=buf_free(path) in app_wiki_open(ts,index,vault,target) end
  | EmbedNavigationFile() => wiki_open_file(ts,anchor,path,length,target)
  | EmbedNavigationExternal() => let
      val ()=fs_open_url(buf_cstr(path)) val ()=buf_free(path) val ()=target := ~1
    in ts end
end

fun close_active_tab(ts: Tabs, idx: int): Tabs = let
  val ts2 = tabs_drop(ts, idx)
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

fun key_code_ctrl_char(c: Letter, sh: Toggle, ev: &event): Cmd =
  if is_letter(c, LZ) then (if is_on(sh) then CMD_REDO else CMD_UNDO)
  else if is_letter(c, LY) then CMD_REDO
  else if is_letter(c, LS) orelse is_letter(c, LSup) orelse ieq(x_key_is(ev, 15), 1) orelse ieq(x_key_is(ev, 20), 1) then CMD_SAVE
  else if is_letter(c, LA) then CMD_SELECT_ALL
  else if is_letter(c, LC) then CMD_COPY
  else if is_letter(c, LX) then CMD_CUT
  else if is_letter(c, LV) then CMD_PASTE
  else if is_letter(c, LF) orelse is_letter(c, LP) orelse is_letter(c, LO) then CMD_OPEN_SEARCH
  else if is_letter(c, LW) then CMD_CLOSE_TAB
  else if is_letter(c, LT) then CMD_NEW_TAB
  else if is_letter(c, LN) then (if is_on(sh) then CMD_NEW_FOLDER else CMD_NEW_FILE)
  else if is_letter(c, LE) then CMD_TOGGLE_VIEW
  else if is_letter(c, LB) then CMD_WRAP_BOLD
  else if is_letter(c, LI) then CMD_WRAP_ITALIC
  else if is_letter(c, LK) then CMD_WRAP_WIKILINK
  else CMD_NONE

fun key_code_ctrl_nav(ev: &event, sh: Toggle): Cmd =
  if key_is(ev, KeyLeft) then (if is_on(sh) then CMD_SELECT_WORD_LEFT else CMD_WORD_LEFT)
  else if key_is(ev, KeyRight) then (if is_on(sh) then CMD_SELECT_WORD_RIGHT else CMD_WORD_RIGHT)
  else if key_is(ev, KeyBackspace) then CMD_DELETE_WORD_LEFT
  else if key_is(ev, KeyDelete) then CMD_DELETE_WORD_RIGHT
  else if key_is(ev, KeyHome) then (if is_on(sh) then CMD_SELECT_DOC_START else CMD_DOC_START)
  else if key_is(ev, KeyEnd) then (if is_on(sh) then CMD_SELECT_DOC_END else CMD_DOC_END)
  else if key_is(ev, KeyTab) then (if is_on(sh) then CMD_PREV_TAB else CMD_NEXT_TAB)
  else key_code_ctrl_char(letter_of(key_char(ev)), sh, ev)

fun key_code_non_ctrl(ev: &event, sh: Toggle): Cmd =
  if key_is(ev, KeyEscape) then CMD_ESCAPE
  else if key_is(ev, KeyLeft) then (if is_on(sh) then CMD_SELECT_LEFT else CMD_CARET_LEFT)
  else if key_is(ev, KeyRight) then (if is_on(sh) then CMD_SELECT_RIGHT else CMD_CARET_RIGHT)
  else if key_is(ev, KeyUp) then (if is_on(sh) then CMD_SELECT_UP else CMD_CARET_UP)
  else if key_is(ev, KeyDown) then (if is_on(sh) then CMD_SELECT_DOWN else CMD_CARET_DOWN)
  else if key_is(ev, KeyHome) then (if is_on(sh) then CMD_SELECT_LINE_START else CMD_CARET_LINE_START)
  else if key_is(ev, KeyEnd) then (if is_on(sh) then CMD_SELECT_LINE_END else CMD_CARET_LINE_END)
  else if key_is(ev, KeyPageUp) then (if is_on(sh) then CMD_SELECT_PAGE_UP else CMD_PAGE_UP)
  else if key_is(ev, KeyPageDown) then (if is_on(sh) then CMD_SELECT_PAGE_DOWN else CMD_PAGE_DOWN)
  else if key_is(ev, KeyBackspace) then CMD_BACKSPACE
  else if key_is(ev, KeyDelete) then CMD_DELETE
  else if key_is(ev, KeyReturn) then CMD_NEWLINE
  else if key_is(ev, KeyTab) then CMD_INDENT
  else CMD_TEXT_INPUT

fun key_code(ev: &event, act: Toggle): Cmd =
  if is_off(act) then (if key_is(ev, KeyEscape) then CMD_ESCAPE else CMD_NONE)
  else if ctrl_on(ev) then key_code_ctrl_nav(ev, toggle_of(shift_on(ev)))
  else key_code_non_ctrl(ev, toggle_of(shift_on(ev)))

fun is_modifying_cmd(cmd: Cmd): bool =
  is_cmd(cmd, CMD_BACKSPACE) orelse is_cmd(cmd, CMD_DELETE) orelse is_cmd(cmd, CMD_DELETE_SELECTION)
     orelse is_cmd(cmd, CMD_UNDO) orelse is_cmd(cmd, CMD_REDO)
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
