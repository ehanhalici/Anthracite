fun read_file(path: string, dst: &Buf >> Buf): bool = let
  val sz = fs_size(path)
in
  if sz <= 0 orelse sz > MAX_CONF_FILE_SIZE then false
  else let
    val fd = fs_open_read(path)
  in
    if fd < 0 then false
    else let
      val () = buffer_clear(dst)
      val () = buf_ensure(dst, iadd(sz, 1))
      val n = fs_read_buf(fd, dst, sz)
      val () = fs_close(fd)
      val () = buf_set_len(dst, if igt(n, 0) then n else 0)
    in
      igt(n, 0)
    end
  end
end

fun write_file(path: string, src: !Buf): int = let
  val n = buf_len(src)
in
  fs_write_buf(path, src, n)
end

fun write_checked(event: string, path: string, src: !Buf): void =
  if ieq(write_file(path, src), 1) then () else report_failure(event, path)

fun ensure_dir(path: string): bool =
  if ine(fs_exists(path), 0) then true
  else if ieq(fs_mkdir(path), 0) then true
  else if ine(fs_exists(path), 0) then true
  else false

fun init_dirs_sub(base: &Buf >> Buf, home: string, hlen: int): bool =
  if igt(hlen, 0) then let
    val () = buffer_append_string(base, home)
    val () = buffer_append_string(base, "/.config")
    val m1 = ensure_dir(buffer_c_string(base))
    val () = buffer_append_string(base, "/anthracite")
    val m2 = ensure_dir(buffer_c_string(base))
  in
    m1 andalso m2
  end else let
    val () = buffer_append_string(base, ".config")
    val m1 = ensure_dir(buffer_c_string(base))
    val () = buffer_append_string(base, "/anthracite")
    val m2 = ensure_dir(buffer_c_string(base))
  in
    m1 andalso m2
  end

fun init_config_override(base: &Buf >> Buf, path: string): bool = let
  val ()=buffer_append_string(base,path)
in ensure_dir(buffer_c_string(base)) end

implement conf_init_dirs(base) = let
  val () = buffer_clear(base)
  val override = c_getenv("ANTHRACITE_CONFIG_DIR")
  val home = c_getenv("HOME")
  val hlen = c_strlen(home)
in
  if igt(c_strlen(override),0) then init_config_override(base,override)
  else init_dirs_sub(base, home, hlen)
end

extern fun match_at_fuel_exhausted(b: !Buf, p: int, k: int, slen: int, n: int, s: string): bool = "mac#anth_die_int"

fun match_at_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), b: !Buf, p: int, k: int, slen: int, n: int, s: string): bool =
  if recursion_fuel_available(recfuel) then (
    if ige(k, slen) then true
    else if ige(iadd(p, k), n) then false
    else if ine(buf_get(b, iadd(p, k)), c_str_byte(s, k)) then false
    else match_at_with_fuel(recfuel - 1, b, p, iadd(k, 1), slen, n, s)
  ) else match_at_fuel_exhausted(b, p, k, slen, n, s)

fun match_at(b: !Buf, p: int, k: int, slen: int, n: int, s: string): bool = match_at_with_fuel(airlock_nat(MAX_REC_FUEL), b, p, k, slen, n, s)

extern fun search_substr_fuel_exhausted(b: !Buf, p: int, slen: int, n: int, s: string): int = "mac#anth_die_int"

fun search_substr_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), b: !Buf, p: int, slen: int, n: int, s: string): int =
  if recursion_fuel_available(recfuel) then (
    if ige(iadd(p, slen), n) then ~1
    else if match_at(b, p, 0, slen, n, s) then p
    else search_substr_with_fuel(recfuel - 1, b, iadd(p, 1), slen, n, s)
  ) else search_substr_fuel_exhausted(b, p, slen, n, s)

fun search_substr(b: !Buf, p: int, slen: int, n: int, s: string): int = search_substr_with_fuel(airlock_nat(MAX_REC_FUEL), b, p, slen, n, s)

fun find_substr(b: !Buf, s: string, from_i: int): int = let
  val n = buf_len(b)
  val slen = c_strlen(s)
in
  search_substr(b, from_i, slen, n, s)
end

extern fun skip_to_char_fuel_exhausted(b: !Buf, i: int, n: int, ch: int): int = "mac#anth_die_int"

fun skip_to_char_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), b: !Buf, i: int, n: int, ch: int): int =
  if recursion_fuel_available(recfuel) then (
    if ige(i, n) orelse ieq(buf_get(b, i), ch) then i
    else skip_to_char_with_fuel(recfuel - 1, b, iadd(i, 1), n, ch)
  ) else skip_to_char_fuel_exhausted(b, i, n, ch)

fun skip_to_char(b: !Buf, i: int, n: int, ch: int): int = skip_to_char_with_fuel(airlock_nat(MAX_REC_FUEL), b, i, n, ch)

extern fun skip_spaces_fuel_exhausted(b: !Buf, i: int, n: int): int = "mac#anth_die_int"

fun skip_spaces_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), b: !Buf, i: int, n: int): int =
  if recursion_fuel_available(recfuel) then (
    if ige(i, n) then i
    else let
      val c = buf_get(b, i)
    in
      if ieq(c, CHAR_SPACE) orelse ieq(c, CHAR_TAB) orelse ieq(c, CHAR_LF) then skip_spaces_with_fuel(recfuel - 1, b, iadd(i, 1), n)
      else i
    end
  ) else skip_spaces_fuel_exhausted(b, i, n)

fun skip_spaces(b: !Buf, i: int, n: int): int = skip_spaces_with_fuel(airlock_nat(MAX_REC_FUEL), b, i, n)

extern fun parse_digits_sub_fuel_exhausted(b: !Buf, i: int, n: int, acc: int, has_digit: bool): int = "mac#anth_die_int"

fun parse_digits_sub_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), b: !Buf, i: int, n: int, acc: int, has_digit: bool): int =
  if recursion_fuel_available(recfuel) then (
    if ige(i, n) then (if has_digit then acc else 0)
    else let
      val c = buf_get(b, i)
    in
      if ige(c, CHAR_ZERO) andalso ile(c, CHAR_NINE) then
        parse_digits_sub_with_fuel(recfuel - 1, b, iadd(i, 1), n, iadd(imul(acc, 10), isub(c, CHAR_ZERO)), true)
      else
        acc
    end
  ) else parse_digits_sub_fuel_exhausted(b, i, n, acc, has_digit)

fun parse_digits_sub(b: !Buf, i: int, n: int, acc: int, has_digit: bool): int = parse_digits_sub_with_fuel(airlock_nat(MAX_REC_FUEL), b, i, n, acc, has_digit)

fun extract_str_after(b: !Buf, pos: int, dst: &Buf >> Buf): bool = let
  val n = buf_len(b)
  val i = skip_to_char(b, pos, n, CHAR_QUOTE)
in
  if ige(i, n) then false
  else let
    val start = iadd(i, 1)
    val end_i = skip_to_char(b, start, n, CHAR_QUOTE)
  in
    if ige(end_i, n) then false
    else let
      val () = buffer_clear(dst)
      val () = buffer_append_range(dst, b, start, end_i)
    in
      true
    end
  end
end

fun extract_int_after(b: !Buf, pos: int, default_val: int): int = let
  val n = buf_len(b)
  val colon = skip_to_char(b, pos, n, CHAR_COLON)
  val after_c = if ilt(colon, n) then iadd(colon, 1) else colon
  val start = skip_spaces(b, after_c, n)
in
  if ige(start, n) then default_val
  else let
    val is_neg = ieq(buf_get(b, start), CHAR_MINUS)
    val num_start = if is_neg then iadd(start, 1) else start
    val v = parse_digits_sub(b, num_start, n, 0, false)
  in
    if is_neg then isub(0, v) else v
  end
end

fun parse_active_vault(read_ok: Toggle, content: !Buf, dst: &Buf >> Buf): bool =
  if is_on(read_ok) then let
    val pos = find_substr(content, KEY_ACTIVE_VAULT, 0)
  in
    if ige(pos, 0) then extract_str_after(content, iadd(pos, KEY_ACTIVE_VAULT_LEN), dst)
    else false
  end else false

fun read_vaults_json(base: Buf, content: &Buf >> Buf): bool = let
  var vpath = buf_make(BUF_SZ_PATH)
  val () = buffer_append_all(vpath, base)
  val () = buf_free(base)
  val () = buffer_append_string(vpath, "/vaults.json")
  val read_ok = read_file(buffer_c_string(vpath), content)
  val () = buf_free(vpath)
in
  read_ok
end

implement conf_get_active_vault(dst) = let
  val () = buffer_clear(dst)
  var base = buf_make(BUF_SZ_PATH)
  val ok = conf_init_dirs(base)
in
  if not(ok) then let
    val () = buf_free(base)
  in
    false
  end else let
    var content = buf_make(BUF_SZ_CONTENT)
    val read_ok = read_vaults_json(base, content)
    val res = parse_active_vault(toggle_of(read_ok), content, dst)
    val () = buf_free(content)
  in
    res
  end
end
