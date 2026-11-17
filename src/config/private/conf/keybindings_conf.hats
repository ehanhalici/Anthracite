macdef KEY_BIND_KEY = "\"key\""
macdef KEY_BIND_KEY_LEN = 5
macdef KEY_BIND_CMD = "\"command\""
macdef KEY_BIND_CMD_LEN = 9

implement conf_keybindings_path(dst) = let
  val () = buffer_clear(dst)
  var base = buf_make(BUF_SZ_PATH)
  val ok = conf_init_dirs(base)
in
  if ok then (
    buffer_append_all(dst, base);
    buffer_append_string(dst, "/keybindings.json");
    buf_free(base)
  ) else buf_free(base)
end

fun apply_parsed_keybinding(
  kbuf: !Buf, cbuf: !Buf, km: &Buf >> _
): void = let
  var m1: int = 0; var k1: int = 0; var m2: int = 0; var k2: int = 0
  val seq_ok = keymap_parse_sequence(kbuf, 0, buf_len(kbuf), m1, k1, m2, k2)
in
  if not(seq_ok) then ()
  else if ieq(c_strcmp(buffer_c_string(cbuf), "unbind"), 0) then keymap_unbind(km, m1, k1, m2, k2)
  else let
    val cmd = keymap_cmd_by_name(cbuf, 0, buf_len(cbuf))
  in
    if not(is_cmd(cmd, CMD_NONE)) then keymap_bind(km, m1, k1, m2, k2, cmd) else ()
  end
end

fun extract_cmd_before(
  content: !Buf, kpos: int, rbrace: int, cbuf: &Buf >> Buf
): bool = let
  val cpos = find_substr(content, KEY_BIND_CMD, kpos)
in
  if ige(cpos, 0) andalso ilt(cpos, rbrace) then
    extract_str_after(content, iadd(cpos, KEY_BIND_CMD_LEN), cbuf)
  else false
end

fun maybe_apply_parsed(
  ok_k: bool, ok_c: bool, kbuf: !Buf, cbuf: !Buf, km: &Buf >> _
): void =
  if ok_k andalso ok_c then apply_parsed_keybinding(kbuf, cbuf, km) else ()

fun parse_one_keybinding(content: !Buf, kpos: int, rbrace: int, km: &Buf >> _): void = let
  var kbuf = buf_make(BUF_SZ_NAME)
  var cbuf = buf_make(BUF_SZ_NAME)
  val ok_k = extract_str_after(content, iadd(kpos, KEY_BIND_KEY_LEN), kbuf)
  val ok_c = extract_cmd_before(content, kpos, rbrace, cbuf)
  val () = maybe_apply_parsed(ok_k, ok_c, kbuf, cbuf, km)
  val () = buf_free(kbuf)
in
  buf_free(cbuf)
end

extern fun parse_keybindings_fuel_exhausted(content: !Buf, cursor: int, km: &Buf >> _): void = "mac#anth_die_void"

fun parse_keybindings_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), content: !Buf, cursor: int, km: &Buf >> _
): void =
  if recursion_fuel_available(recfuel) then let
    val kpos = find_substr(content, KEY_BIND_KEY, cursor)
  in
    if ilt(kpos, 0) then ()
    else let
      val rbrace = skip_to_char(content, kpos, buf_len(content), CHAR_RBRACE)
      val () = parse_one_keybinding(content, kpos, rbrace, km)
    in
      parse_keybindings_with_fuel(recfuel - 1, content, iadd(kpos, KEY_BIND_KEY_LEN), km)
    end
  end else parse_keybindings_fuel_exhausted(content, cursor, km)

fun write_default_keybindings(kpath: string): void = let
  var def_json = buf_make(BUF_SZ_LARGE)
  val () = keymap_default_json(def_json)
  val () = write_checked("keybindings_init", kpath, def_json)
in
  buf_free(def_json)
end

fun load_or_init_keybindings(kpath: !Buf, content: &Buf >> Buf, km: &Buf >> _): void = let
  val kp = buffer_c_string(kpath)
  val has_path = igt(buf_len(kpath), 0)
  val r_ok = if has_path then read_file(kp, content) else false
in
  if r_ok then parse_keybindings_with_fuel(airlock_nat(MAX_REC_FUEL), content, 0, km)
  else if has_path then (if ieq(fs_exists(kp), 0) then write_default_keybindings(kp) else ())
  else ()
end

implement conf_load_keybindings(km) = let
  val () = keymap_load_defaults(km)
  var kpath = buf_make(BUF_SZ_PATH)
  val () = conf_keybindings_path(kpath)
  var content = buf_make(BUF_SZ_LARGE)
  val () = load_or_init_keybindings(kpath, content, km)
  val () = buf_free(content)
in
  buf_free(kpath)
end
