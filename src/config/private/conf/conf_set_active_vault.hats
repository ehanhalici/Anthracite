implement conf_set_active_vault(vault) = let
  var base = buf_make(BUF_SZ_PATH)
  val ok = conf_init_dirs(base)
in
  if not(ok) then let
    val () = buf_free(base)
  in
  end else let
    var vpath = buf_make(BUF_SZ_PATH)
    val () = buffer_append_all(vpath, base)
    val () = buf_free(base)
    val () = buffer_append_string(vpath, "/vaults.json")
    val () = save_active_vault_file(vpath, vault)
    val () = buf_free(vpath)
  in
  end
end

fun append_vault_dir(dst: &Buf >> Buf, found: Toggle, cdir: !Buf): void =
  if is_on(found) then buffer_append_all(dst, cdir)
  else buffer_append_string(dst, "v_0")

fun append_conf_dir_for_vault(vault: string, dst: &Buf >> Buf, content: !Buf): void = let
  var cdir = buf_make(BUF_SZ_NAME)
  val found = find_vault_conf_dir_impl(content, vault, cdir)
  val () = append_vault_dir(dst, toggle_of(found), cdir)
  val () = buf_free(cdir)
in
end

fun vault_conf_dir_fill(vault: string, dst: &Buf >> Buf, base: Buf): void = let
  val () = buffer_append_all(dst, base)
  val () = buffer_append_string(dst, "/")
  var content = buf_make(BUF_SZ_LARGE)
  val got = read_vaults_json(base, content)
  val () = if got then () else ()
  val () = append_conf_dir_for_vault(vault, dst, content)
  val () = buf_free(content)
in
  if ensure_dir(buffer_c_string(dst)) then ()
  else report_failure("vault_dir_create", buffer_c_string(dst))
end

fun vault_conf_dir_path(vault: string, dst: &Buf >> Buf): void = let
  val () = buffer_clear(dst)
  var base = buf_make(BUF_SZ_PATH)
  val ok = conf_init_dirs(base)
in
  if not(ok) then buf_free(base)
  else vault_conf_dir_fill(vault, dst, base)
end

extern fun tabs_to_json_fuel_exhausted(ts: !Tabs, tab_pane: !Buf, dst: &Buf >> Buf, i: int): void = "mac#anth_die_void"

fun tabs_to_json_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), ts: !Tabs, tab_pane: !Buf, dst: &Buf >> Buf, i: int): void =
  if recursion_fuel_available(recfuel) then (
    case+ ts of
    | TNil() => ()
    | TCons(doc, path, title, sc, rest) => let
      val () = if igt(i, 0) then buffer_append_string(dst, ",\n") else ()
      val () = buffer_append_string(dst, "    {\"path\": \"")
      val () = buffer_append_all(dst, path)
      val () = buffer_append_string(dst, "\", \"scroll\": ")
      val () = buffer_append_integer(dst, sc)
      val pn = if ilt(i, buf_len(tab_pane)) then buf_get(tab_pane, i) else 0
      val () = buffer_append_string(dst, ", \"pane\": ")
      val () = buffer_append_integer(dst, pn)
      val () = buffer_append_string(dst, "}")
    in
      tabs_to_json_with_fuel(recfuel - 1, rest, tab_pane, dst, iadd(i, 1))
    end
  ) else tabs_to_json_fuel_exhausted(ts, tab_pane, dst, i)

fun tabs_to_json(ts: !Tabs, tab_pane: !Buf, dst: &Buf >> Buf, i: int): void =
  tabs_to_json_with_fuel(airlock_nat(MAX_REC_FUEL), ts, tab_pane, dst, i)

fun session_path_into(vault: string, spath: &Buf >> Buf): void = let
  var vdir = buf_make(BUF_SZ_PATH)
  val () = vault_conf_dir_path(vault, vdir)
  val () = buffer_append_all(spath, vdir)
  val () = buf_free(vdir)
  val () = buffer_append_string(spath, "/session.json")
in
end

fun session_head_base(
  json: &Buf >> Buf, font_p: string, font_px: int, viewmode: int, split: int
): void = let
  val () = buffer_append_string(json, "{\n  \"font_path\": \"")
  val () = buffer_append_string(json, font_p)
  val () = buffer_append_string(json, "\",\n  \"font_px\": ")
  val () = buffer_append_integer(json, font_px)
  val () = buffer_append_string(json, ",\n  \"viewmode\": ")
  val () = buffer_append_integer(json, viewmode)
  val () = buffer_append_string(json, ",\n  \"split\": ")
  val () = buffer_append_integer(json, split)
in
end

fun session_json_head(
  json: &Buf >> Buf, font_p: string, font_px: int, viewmode: int,
  split: int, active: int, righti: int, side_open: int, sidew: int, tab_cnt: int
): void = let
  val () = session_head_base(json, font_p, font_px, viewmode, split)
  val () = buffer_append_string(json, ",\n  \"active\": ")
  val () = buffer_append_integer(json, active)
  val () = buffer_append_string(json, ",\n  \"right_active\": ")
  val () = buffer_append_integer(json, righti)
  val () = buffer_append_string(json, ",\n  \"sidebar_open\": ")
  val () = buffer_append_integer(json, side_open)
  val () = buffer_append_string(json, ",\n  \"sidebar_width\": ")
  val () = buffer_append_integer(json, sidew)
  val () = buffer_append_string(json, ",\n  \"tab_count\": ")
  val () = buffer_append_integer(json, tab_cnt)
  val () = buffer_append_string(json, ",\n  \"tabs\": [\n")
in
end

fun open_dirs_item(dst: &Buf >> Buf, open_dirs: !Buf, cur: int, e: int, idx: int): void = let
  val () = if igt(idx, 0) then buffer_append_string(dst, ",\n") else ()
  val () = buffer_append_string(dst, "    \"")
  val () = buffer_append_range(dst, open_dirs, cur, e)
  val () = buffer_append_string(dst, "\"")
in
end

fun open_dirs_to_json_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), open_dirs: !Buf, dst: &Buf >> Buf, cur: int, n: int, idx: int
): void =
  if recursion_fuel_available(recfuel) then (
    if ilt(cur, n) then let
      val e = skip_to_char(open_dirs, cur, n, CHAR_LF)
      val len = isub(e, cur)
      val is_nonempty = igt(len, 0)
      val () = if is_nonempty then open_dirs_item(dst, open_dirs, cur, e, idx) else ()
      val nxt_idx = if is_nonempty then iadd(idx, 1) else idx
    in
      open_dirs_to_json_with_fuel(recfuel - 1, open_dirs, dst, iadd(e, 1), n, nxt_idx)
    end else ()
  ) else ()

fun open_dirs_to_json(open_dirs: !Buf, dst: &Buf >> Buf): void = let
  val n = buf_len(open_dirs)
  val () = buffer_append_string(dst, ",\n  \"open_dirs\": [")
  val () = if igt(n, 0) then (
    buffer_append_string(dst, "\n");
    open_dirs_to_json_with_fuel(airlock_nat(MAX_REC_FUEL), open_dirs, dst, 0, n, 0);
    buffer_append_string(dst, "\n  ")
  ) else ()
  val () = buffer_append_string(dst, "]\n")
in
end

implement conf_save_session(vault, font_p, font_px, viewmode, split, active, righti, side_open, sidew, tab_pane, open_dirs, ts) = let
  var spath = buf_make(BUF_SZ_PATH)
  val () = session_path_into(vault, spath)
  var json = buf_make(BUF_SZ_LARGE)
  val () = session_json_head(json, font_p, font_px, viewmode, split, active, righti, side_open, sidew, tabs_len(ts))
  val () = tabs_to_json(ts, tab_pane, json, 0)
  val () = buffer_append_string(json, "\n  ]")
  val () = open_dirs_to_json(open_dirs, json)
  val () = buffer_append_string(json, "}\n")
  val () = write_checked("session_save", buffer_c_string(spath), json)
  val () = buf_free(spath)
  val () = buf_free(json)
in
end

fun read_tab_scroll(content: !Buf, p_pos: int, rbrace: int): int = let
  val sc_pos = find_substr(content, KEY_SCROLL, p_pos)
in
  if ige(sc_pos, 0) andalso ilt(sc_pos, rbrace) then
    extract_int_after(content, iadd(sc_pos, KEY_SCROLL_LEN), 0)
  else 0
end

fun read_tab_pane(content: !Buf, p_pos: int, rbrace: int): int = let
  val pn_pos = find_substr(content, KEY_PANE, p_pos)
in
  if ige(pn_pos, 0) andalso ilt(pn_pos, rbrace) then
    extract_int_after(content, iadd(pn_pos, KEY_PANE_LEN), 0)
  else 0
end

fun open_tab_with(ts: Tabs, d: Doc, tmp_path: Buf, sc: int): Tabs = let
  var tbuf = buf_make(BUF_SZ_NAME)
  val () = base_name(tmp_path, tbuf)
  val powned = buffer_clone(tmp_path)
  val () = buf_free(tmp_path)
in
  tabs_append(ts, d, powned, tbuf, sc)
end

(* Var olan ama yuklenemeyen dosyanin sekmesi acilmaz (veri kaybi onlemi). *)
fun open_tab(ts: Tabs, tmp_path: Buf, sc: int): Tabs = let
  val d = doc_open()
  val ok = doc_load_checked(d, buffer_c_string(tmp_path))
in
  if ok then open_tab_with(ts, d, tmp_path, sc)
  else let
    val () = doc_free(d)
    val () = buf_free(tmp_path)
  in
    ts
  end
end
