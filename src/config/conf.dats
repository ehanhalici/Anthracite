#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "mem.sats"
staload "airlock.sats"
staload "flag.sats"
staload "os/fs.sats"
staload "os/diag.sats"
staload "data_ast/doc.sats"
staload "ui_workspace/ui_common.sats"
staload "ui_workspace/ui_tab.sats"
staload "config/conf.sats"

macdef MAX_CONF_FILE_SIZE = 10000000
macdef BUF_SZ_PATH = 256
macdef BUF_SZ_NAME = 64
macdef BUF_SZ_CONTENT = 4096
macdef BUF_SZ_LARGE = 8192
macdef BUF_SZ_PATHS = 1024

macdef KEY_ACTIVE_VAULT = "\"active_vault\""
macdef KEY_ACTIVE_VAULT_LEN = 14

macdef KEY_PATH = "\"path\""
macdef KEY_PATH_LEN = 6

macdef KEY_NAME = "\"name\""
macdef KEY_NAME_LEN = 6

macdef KEY_CONF_DIR = "\"conf_dir\""
macdef KEY_CONF_DIR_LEN = 10

macdef KEY_SCROLL = "\"scroll\""
macdef KEY_SCROLL_LEN = 8

macdef KEY_FONT_PATH = "\"font_path\""
macdef KEY_FONT_PATH_LEN = 11

macdef KEY_FONT_PX = "\"font_px\""
macdef KEY_FONT_PX_LEN = 9

macdef KEY_VIEWMODE = "\"viewmode\""
macdef KEY_VIEWMODE_LEN = 10

macdef KEY_SPLIT = "\"split\""
macdef KEY_SPLIT_LEN = 7

macdef KEY_ACTIVE = "\"active\""
macdef KEY_ACTIVE_LEN = 8

macdef VAULT_META_STRIDE_BYTES = 16
macdef VAULT_META_STRIDE_WORDS = 4
macdef VAULT_META_FIELD_POFF = 0
macdef VAULT_META_FIELD_PLEN = 1
macdef VAULT_META_FIELD_NOFF = 2
macdef VAULT_META_FIELD_NLEN = 3

macdef SESSION_DEFAULT_FONT_PX = 18
macdef SESSION_DEFAULT_VIEWMODE = 0
macdef SESSION_DEFAULT_SPLIT = 0
macdef SESSION_DEFAULT_ACTIVE = 0

fun read_file(path: string, dst: &Buf >> Buf): bool = let
  val sz = fs_size(path)
in
  if sz <= 0 orelse sz > MAX_CONF_FILE_SIZE then false
  else let
    val fd = fs_open_read(path)
  in
    if fd < 0 then false
    else let
      val () = bclear(dst)
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
    val () = bstr(base, home)
    val () = bstr(base, "/.config")
    val m1 = ensure_dir(cstr(base))
    val () = bstr(base, "/anthracite")
    val m2 = ensure_dir(cstr(base))
  in
    m1 andalso m2
  end else let
    val () = bstr(base, ".config")
    val m1 = ensure_dir(cstr(base))
    val () = bstr(base, "/anthracite")
    val m2 = ensure_dir(cstr(base))
  in
    m1 andalso m2
  end

implement conf_init_dirs(base) = let
  val () = bclear(base)
  val home = c_getenv("HOME")
  val hlen = c_strlen(home)
in
  init_dirs_sub(base, home, hlen)
end

extern fun match_at_exh(b: !Buf, p: int, k: int, slen: int, n: int, s: string): bool = "mac#anth_die_int"

fun match_at_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), b: !Buf, p: int, k: int, slen: int, n: int, s: string): bool =
  if recfuel > 0 then (
    if ige(k, slen) then true
    else if ige(iadd(p, k), n) then false
    else if ine(buf_get(b, iadd(p, k)), c_str_byte(s, k)) then false
    else match_at_m(recfuel - 1, b, p, iadd(k, 1), slen, n, s)
  ) else match_at_exh(b, p, k, slen, n, s)

fun match_at(b: !Buf, p: int, k: int, slen: int, n: int, s: string): bool = match_at_m(airlock_nat(MAX_REC_FUEL), b, p, k, slen, n, s)

extern fun search_substr_exh(b: !Buf, p: int, slen: int, n: int, s: string): int = "mac#anth_die_int"

fun search_substr_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), b: !Buf, p: int, slen: int, n: int, s: string): int =
  if recfuel > 0 then (
    if ige(iadd(p, slen), n) then ~1
    else if match_at(b, p, 0, slen, n, s) then p
    else search_substr_m(recfuel - 1, b, iadd(p, 1), slen, n, s)
  ) else search_substr_exh(b, p, slen, n, s)

fun search_substr(b: !Buf, p: int, slen: int, n: int, s: string): int = search_substr_m(airlock_nat(MAX_REC_FUEL), b, p, slen, n, s)

fun find_substr(b: !Buf, s: string, from_i: int): int = let
  val n = buf_len(b)
  val slen = c_strlen(s)
in
  search_substr(b, from_i, slen, n, s)
end

extern fun skip_to_char_exh(b: !Buf, i: int, n: int, ch: int): int = "mac#anth_die_int"

fun skip_to_char_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), b: !Buf, i: int, n: int, ch: int): int =
  if recfuel > 0 then (
    if ige(i, n) orelse ieq(buf_get(b, i), ch) then i
    else skip_to_char_m(recfuel - 1, b, iadd(i, 1), n, ch)
  ) else skip_to_char_exh(b, i, n, ch)

fun skip_to_char(b: !Buf, i: int, n: int, ch: int): int = skip_to_char_m(airlock_nat(MAX_REC_FUEL), b, i, n, ch)

extern fun skip_spaces_exh(b: !Buf, i: int, n: int): int = "mac#anth_die_int"

fun skip_spaces_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), b: !Buf, i: int, n: int): int =
  if recfuel > 0 then (
    if ige(i, n) then i
    else let
      val c = buf_get(b, i)
    in
      if ieq(c, CHAR_SPACE) orelse ieq(c, CHAR_TAB) orelse ieq(c, CHAR_LF) then skip_spaces_m(recfuel - 1, b, iadd(i, 1), n)
      else i
    end
  ) else skip_spaces_exh(b, i, n)

fun skip_spaces(b: !Buf, i: int, n: int): int = skip_spaces_m(airlock_nat(MAX_REC_FUEL), b, i, n)

extern fun parse_digits_sub_exh(b: !Buf, i: int, n: int, acc: int, has_digit: bool): int = "mac#anth_die_int"

fun parse_digits_sub_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), b: !Buf, i: int, n: int, acc: int, has_digit: bool): int =
  if recfuel > 0 then (
    if ige(i, n) then (if has_digit then acc else 0)
    else let
      val c = buf_get(b, i)
    in
      if ige(c, CHAR_ZERO) andalso ile(c, CHAR_NINE) then
        parse_digits_sub_m(recfuel - 1, b, iadd(i, 1), n, iadd(imul(acc, 10), isub(c, CHAR_ZERO)), true)
      else
        acc
    end
  ) else parse_digits_sub_exh(b, i, n, acc, has_digit)

fun parse_digits_sub(b: !Buf, i: int, n: int, acc: int, has_digit: bool): int = parse_digits_sub_m(airlock_nat(MAX_REC_FUEL), b, i, n, acc, has_digit)

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
      val () = bclear(dst)
      val () = bcat(dst, b, start, end_i)
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
  val () = bcat_all(vpath, base)
  val () = buf_free(base)
  val () = bstr(vpath, "/vaults.json")
  val read_ok = read_file(cstr(vpath), content)
  val () = buf_free(vpath)
in
  read_ok
end

implement conf_get_active_vault(dst) = let
  val () = bclear(dst)
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

fun extract_vault_name(content: !Buf, p_pos: int, tmp_p: !Buf, tmp_n: &Buf >> Buf): void = let
  val n_pos = find_substr(content, KEY_NAME, p_pos)
  val () = if ige(n_pos, 0) then (if extract_str_after(content, iadd(n_pos, KEY_NAME_LEN), tmp_n) then () else ()) else base_name(tmp_p, tmp_n)
in
end

fun record_vault_meta(meta: &Buf >> Buf, cnt: &int >> int, poff: int, plen: int, noff: int, nlen: int): void = let
  val idx = cnt
  val base_word = imul(idx, VAULT_META_STRIDE_WORDS)
  val () = buf_ensure(meta, iadd(imul(idx, VAULT_META_STRIDE_BYTES), VAULT_META_STRIDE_BYTES))
  val () = buf_set32(meta, iadd(base_word, VAULT_META_FIELD_POFF), poff)
  val () = buf_set32(meta, iadd(base_word, VAULT_META_FIELD_PLEN), plen)
  val () = buf_set32(meta, iadd(base_word, VAULT_META_FIELD_NOFF), noff)
  val () = buf_set32(meta, iadd(base_word, VAULT_META_FIELD_NLEN), nlen)
  val () = cnt := iadd(cnt, 1)
in
end

extern fun scan_vaults_rec_exh(content: !Buf, cursor: int, paths: &Buf >> Buf, names: &Buf >> Buf, meta: &Buf >> Buf, cnt: &int >> int, tmp_p: &Buf >> Buf, tmp_n: &Buf >> Buf): void = "mac#anth_die_void"

fun scan_vaults_rec_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), content: !Buf, cursor: int, paths: &Buf >> Buf, names: &Buf >> Buf, meta: &Buf >> Buf, cnt: &int >> int, tmp_p: &Buf >> Buf, tmp_n: &Buf >> Buf): void =
  if recfuel > 0 then (
  let
    val p_pos = find_substr(content, KEY_PATH, cursor)
  in
    if ilt(p_pos, 0) then ()
    else let
      val ok_p = extract_str_after(content, iadd(p_pos, KEY_PATH_LEN), tmp_p)
      val () = extract_vault_name(content, p_pos, tmp_p, tmp_n)
      val poff = buf_len(paths)
      val plen = buf_len(tmp_p)
      val () = bcat(paths, tmp_p, 0, plen)
      val noff = buf_len(names)
      val nlen = buf_len(tmp_n)
      val () = bcat(names, tmp_n, 0, nlen)
      val () = record_vault_meta(meta, cnt, poff, plen, noff, nlen)
    in
      scan_vaults_rec_m(recfuel - 1, content, iadd(p_pos, KEY_PATH_LEN), paths, names, meta, cnt, tmp_p, tmp_n)
    end
  end
  ) else scan_vaults_rec_exh(content, cursor, paths, names, meta, cnt, tmp_p, tmp_n)

fun scan_vaults_rec(content: !Buf, cursor: int, paths: &Buf >> Buf, names: &Buf >> Buf, meta: &Buf >> Buf, cnt: &int >> int, tmp_p: &Buf >> Buf, tmp_n: &Buf >> Buf): void = scan_vaults_rec_m(airlock_nat(MAX_REC_FUEL), content, cursor, paths, names, meta, cnt, tmp_p, tmp_n)

fun parse_vault_list(read_ok: Toggle, content: !Buf, paths: &Buf >> Buf, names: &Buf >> Buf, meta: &Buf >> Buf, cnt: &int >> int): void =
  if is_on(read_ok) then let
    var tmp_p = buf_make(BUF_SZ_PATH)
    var tmp_n = buf_make(BUF_SZ_NAME)
    val () = scan_vaults_rec(content, 0, paths, names, meta, cnt, tmp_p, tmp_n)
    val () = buf_free(tmp_p)
    val () = buf_free(tmp_n)
  in
  end else ()

implement conf_list_vaults(paths, names, meta, cnt) = let
  val () = bclear(paths)
  val () = bclear(names)
  val () = bclear(meta)
  val () = cnt := 0
  var base = buf_make(BUF_SZ_PATH)
  val ok = conf_init_dirs(base)
in
  if not(ok) then let
    val () = buf_free(base)
  in
  end else let
    var content = buf_make(BUF_SZ_CONTENT)
    val read_ok = read_vaults_json(base, content)
    val () = parse_vault_list(toggle_of(read_ok), content, paths, names, meta, cnt)
    val () = buf_free(content)
  in
  end
end

extern fun search_conf_dir_rec_exh(content: !Buf, cur: int, vault: string, dst: &Buf >> Buf, pbuf: &Buf >> Buf): int = "mac#anth_die_int"

fun search_conf_dir_rec_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), content: !Buf, cur: int, vault: string, dst: &Buf >> Buf, pbuf: &Buf >> Buf): int =
  if recfuel > 0 then (
  let
    val p_pos = find_substr(content, KEY_PATH, cur)
  in
    if ilt(p_pos, 0) then 0
    else let
      val ok_p = extract_str_after(content, iadd(p_pos, KEY_PATH_LEN), pbuf)
      val matches = ok_p andalso ieq(c_strcmp(cstr(pbuf), vault), 0)
    in
      if matches then let
        val cd_pos = find_substr(content, KEY_CONF_DIR, p_pos)
        val ok_cd = if ige(cd_pos, 0) then extract_str_after(content, iadd(cd_pos, KEY_CONF_DIR_LEN), dst) else false
      in
        if ok_cd then 1 else 0
      end else
        search_conf_dir_rec_m(recfuel - 1, content, iadd(p_pos, KEY_PATH_LEN), vault, dst, pbuf)
    end
  end
  ) else search_conf_dir_rec_exh(content, cur, vault, dst, pbuf)

fun search_conf_dir_rec(content: !Buf, cur: int, vault: string, dst: &Buf >> Buf, pbuf: &Buf >> Buf): int = search_conf_dir_rec_m(airlock_nat(MAX_REC_FUEL), content, cur, vault, dst, pbuf)

fun find_vault_conf_dir_impl(content: !Buf, vault: string, dst: &Buf >> Buf): int = let
  var pbuf = buf_make(BUF_SZ_PATH)
  val res = search_conf_dir_rec(content, 0, vault, dst, pbuf)
  val () = buf_free(pbuf)
in
  res
end

fun load_vault_strings(paths: !Buf, names: !Buf, meta: !Buf, vi: int, p_cur: &Buf >> Buf, n_cur: &Buf >> Buf): void = let
  val base_word = imul(vi, VAULT_META_STRIDE_WORDS)
  val poff = buf_get32(meta, iadd(base_word, VAULT_META_FIELD_POFF))
  val plen = buf_get32(meta, iadd(base_word, VAULT_META_FIELD_PLEN))
  val noff = buf_get32(meta, iadd(base_word, VAULT_META_FIELD_NOFF))
  val nlen = buf_get32(meta, iadd(base_word, VAULT_META_FIELD_NLEN))
  val () = bclear(p_cur)
  val () = bcat(p_cur, paths, poff, iadd(poff, plen))
  val () = bclear(n_cur)
  val () = bcat(n_cur, names, noff, iadd(noff, nlen))
in
end

fun mark_existing_vault(p_cur: !Buf, vault: string, already_in: &int >> int): void =
  if ieq(c_strcmp(cstr(p_cur), vault), 0) then already_in := 1 else ()

fun append_vault_entry(new_json: &Buf >> Buf, vi: int, p_cur: !Buf, n_cur: !Buf): void = let
  val () = if igt(vi, 0) then bstr(new_json, ",\n") else ()
  val () = bstr(new_json, "    {\n      \"path\": \"")
  val () = bcat_all(new_json, p_cur)
  val () = bstr(new_json, "\",\n      \"name\": \"")
  val () = bcat_all(new_json, n_cur)
  val () = bstr(new_json, "\",\n      \"conf_dir\": \"v_")
  val () = b_app_int(new_json, vi)
  val () = bstr(new_json, "\"\n    }")
in
end

extern fun write_existing_vaults_rec_exh(vi: int, nvaults: int, paths: !Buf, names: !Buf, meta: !Buf, new_json: &Buf >> Buf, p_cur: &Buf >> Buf, n_cur: &Buf >> Buf, vault: string, already_in: &int >> int): void = "mac#anth_die_void"

fun write_existing_vaults_rec_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), vi: int, nvaults: int, paths: !Buf, names: !Buf, meta: !Buf, new_json: &Buf >> Buf, p_cur: &Buf >> Buf, n_cur: &Buf >> Buf, vault: string, already_in: &int >> int): void =
  if recfuel > 0 then (
    if ige(vi, nvaults) then ()
    else let
      val () = load_vault_strings(paths, names, meta, vi, p_cur, n_cur)
      val () = mark_existing_vault(p_cur, vault, already_in)
      val () = append_vault_entry(new_json, vi, p_cur, n_cur)
    in
      write_existing_vaults_rec_m(recfuel - 1, iadd(vi, 1), nvaults, paths, names, meta, new_json, p_cur, n_cur, vault, already_in)
    end
  ) else write_existing_vaults_rec_exh(vi, nvaults, paths, names, meta, new_json, p_cur, n_cur, vault, already_in)

fun write_existing_vaults_rec(vi: int, nvaults: int, paths: !Buf, names: !Buf, meta: !Buf, new_json: &Buf >> Buf, p_cur: &Buf >> Buf, n_cur: &Buf >> Buf, vault: string, already_in: &int >> int): void = write_existing_vaults_rec_m(airlock_nat(MAX_REC_FUEL), vi, nvaults, paths, names, meta, new_json, p_cur, n_cur, vault, already_in)

fun append_new_vault_entry(new_json: &Buf >> Buf, vault: string, nvaults: int): void = let
  val () = if igt(nvaults, 0) then bstr(new_json, ",\n") else ()
  val () = bstr(new_json, "    {\n      \"path\": \"")
  val () = bstr(new_json, vault)
  val () = bstr(new_json, "\",\n      \"name\": \"")
  var bname = buf_make(BUF_SZ_NAME)
  var vbuf = buf_make(iadd(c_strlen(vault), 1))
  val () = bstr(vbuf, vault)
  val () = base_name(vbuf, bname)
  val () = buf_free(vbuf)
  val () = bcat_all(new_json, bname)
  val () = buf_free(bname)
  val () = bstr(new_json, "\",\n      \"conf_dir\": \"v_")
  val () = b_app_int(new_json, nvaults)
  val () = bstr(new_json, "\"\n    }\n")
in
end

fun append_new_vault_if_needed(new_json: &Buf >> Buf, already_in: Toggle, vault: string, nvaults: int): void =
  if is_off(already_in) andalso igt(c_strlen(vault), 0) then append_new_vault_entry(new_json, vault, nvaults)
  else let
    val () = bstr(new_json, "\n")
  in
  end

fun build_vaults_json(vault: string, paths: !Buf, names: !Buf, meta: !Buf, nvaults: int): Buf = let
  var new_json = buf_make(BUF_SZ_LARGE)
  val () = bstr(new_json, "{\n  \"active_vault\": \"")
  val () = bstr(new_json, vault)
  val () = bstr(new_json, "\",\n  \"vaults\": [\n")
  var already_in: int = 0
  var p_cur = buf_make(BUF_SZ_PATH)
  var n_cur = buf_make(BUF_SZ_NAME)
  val () = write_existing_vaults_rec(0, nvaults, paths, names, meta, new_json, p_cur, n_cur, vault, already_in)
  val () = buf_free(p_cur)
  val () = buf_free(n_cur)
  val () = append_new_vault_if_needed(new_json, toggle_of(ieq(already_in, 1)), vault, nvaults)
  val () = bstr(new_json, "  ]\n}\n")
in
  new_json
end

fun save_active_vault_file(vpath: !Buf, vault: string): void = let
  var paths = buf_make(BUF_SZ_PATHS)
  var names = buf_make(BUF_SZ_PATH)
  var meta = buf_make(BUF_SZ_PATH)
  var nvaults: int = 0
  val () = conf_list_vaults(paths, names, meta, nvaults)
  val new_json = build_vaults_json(vault, paths, names, meta, nvaults)
  val () = buf_free(paths)
  val () = buf_free(names)
  val () = buf_free(meta)
  val () = write_checked("vault_config_save", cstr(vpath), new_json)
  val () = buf_free(new_json)
in
end

implement conf_set_active_vault(vault) = let
  var base = buf_make(BUF_SZ_PATH)
  val ok = conf_init_dirs(base)
in
  if not(ok) then let
    val () = buf_free(base)
  in
  end else let
    var vpath = buf_make(BUF_SZ_PATH)
    val () = bcat_all(vpath, base)
    val () = buf_free(base)
    val () = bstr(vpath, "/vaults.json")
    val () = save_active_vault_file(vpath, vault)
    val () = buf_free(vpath)
  in
  end
end

fun append_vault_dir(dst: &Buf >> Buf, found: Toggle, cdir: !Buf): void =
  if is_on(found) then bcat_all(dst, cdir)
  else bstr(dst, "v_0")

fun append_conf_dir_for_vault(vault: string, dst: &Buf >> Buf, content: !Buf): void = let
  var cdir = buf_make(BUF_SZ_NAME)
  val found = find_vault_conf_dir_impl(content, vault, cdir)
  val () = append_vault_dir(dst, toggle_of(ieq(found, 1)), cdir)
  val () = buf_free(cdir)
in
end

fun vault_conf_dir_path(vault: string, dst: &Buf >> Buf): void = let
  val () = bclear(dst)
  var base = buf_make(BUF_SZ_PATH)
  val ok = conf_init_dirs(base)
in
  if not(ok) then let
    val () = buf_free(base)
  in
  end else let
    val () = bcat_all(dst, base)
    val () = bstr(dst, "/")
    var content = buf_make(BUF_SZ_LARGE)
    val got = read_vaults_json(base, content)
    val () = if got then () else ()
    val () = append_conf_dir_for_vault(vault, dst, content)
    val () = buf_free(content)
    val () = if ensure_dir(cstr(dst)) then ()
             else report_failure("vault_dir_create", cstr(dst))
  in
  end
end

extern fun tabs_to_json_exh(ts: !Tabs, dst: &Buf >> Buf, i: int): void = "mac#anth_die_void"

fun tabs_to_json_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), ts: !Tabs, dst: &Buf >> Buf, i: int): void =
  if recfuel > 0 then (
    case+ ts of
    | TNil() => ()
    | TCons(doc, path, title, sc, rest) => let
      val () = if igt(i, 0) then bstr(dst, ",\n") else ()
      val () = bstr(dst, "    {\"path\": \"")
      val () = bcat_all(dst, path)
      val () = bstr(dst, "\", \"scroll\": ")
      val () = b_app_int(dst, sc)
      val () = bstr(dst, "}")
    in
      tabs_to_json_m(recfuel - 1, rest, dst, iadd(i, 1))
    end
  ) else tabs_to_json_exh(ts, dst, i)

fun tabs_to_json(ts: !Tabs, dst: &Buf >> Buf, i: int): void = tabs_to_json_m(airlock_nat(MAX_REC_FUEL), ts, dst, i)

fun session_path_into(vault: string, spath: &Buf >> Buf): void = let
  var vdir = buf_make(BUF_SZ_PATH)
  val () = vault_conf_dir_path(vault, vdir)
  val () = bcat_all(spath, vdir)
  val () = buf_free(vdir)
  val () = bstr(spath, "/session.json")
in
end

fun session_json_head(json: &Buf >> Buf, font_p: string, font_px: int, viewmode: int, split: int, active: int): void = let
  val () = bstr(json, "{\n  \"font_path\": \"")
  val () = bstr(json, font_p)
  val () = bstr(json, "\",\n  \"font_px\": ")
  val () = b_app_int(json, font_px)
  val () = bstr(json, ",\n  \"viewmode\": ")
  val () = b_app_int(json, viewmode)
  val () = bstr(json, ",\n  \"split\": ")
  val () = b_app_int(json, split)
  val () = bstr(json, ",\n  \"active\": ")
  val () = b_app_int(json, active)
  val () = bstr(json, ",\n  \"tabs\": [\n")
in
end

implement conf_save_session(vault, font_p, font_px, viewmode, split, active, ts) = let
  var spath = buf_make(BUF_SZ_PATH)
  val () = session_path_into(vault, spath)
  var json = buf_make(BUF_SZ_LARGE)
  val () = session_json_head(json, font_p, font_px, viewmode, split, active)
  val () = tabs_to_json(ts, json, 0)
  val () = bstr(json, "\n  ]\n}\n")
  val () = write_checked("session_save", cstr(spath), json)
  val () = buf_free(spath)
  val () = buf_free(json)
in
end

fun read_tab_scroll(content: !Buf, p_pos: int): int = let
  val sc_pos = find_substr(content, KEY_SCROLL, p_pos)
in
  if ige(sc_pos, 0) then extract_int_after(content, iadd(sc_pos, KEY_SCROLL_LEN), 0) else 0
end

fun open_tab_with(ts: Tabs, d: Doc, tmp_path: Buf, sc: int): Tabs = let
  var tbuf = buf_make(BUF_SZ_NAME)
  val () = base_name(tmp_path, tbuf)
  val powned = bcopy(tmp_path)
  val () = buf_free(tmp_path)
in
  tabs_append(ts, d, powned, tbuf, sc)
end

(* Var olan ama yuklenemeyen dosyanin sekmesi acilmaz (veri kaybi onlemi). *)
fun open_tab(ts: Tabs, tmp_path: Buf, sc: int): Tabs = let
  val d = doc_open()
  val ok = doc_load_checked(d, cstr(tmp_path))
in
  if ok then open_tab_with(ts, d, tmp_path, sc)
  else let
    val () = doc_free(d)
    val () = buf_free(tmp_path)
  in
    ts
  end
end

fun parse_one_tab(content: !Buf, p_pos: int, ts: Tabs): Tabs = let
  var tmp_path = buf_make(BUF_SZ_PATH)
  val ok_p = extract_str_after(content, iadd(p_pos, KEY_PATH_LEN), tmp_path)
  val sc = read_tab_scroll(content, p_pos)
  val p_str = cstr(tmp_path)
  val ex = fs_exists(p_str)
  val exists = ok_p andalso ieq(ex, 1)
in
  if exists then open_tab(ts, tmp_path, sc)
  else let
    val () = buf_free(tmp_path)
  in
    ts
  end
end

extern fun parse_tabs_rec_exh(content: !Buf, cursor: int, ts: Tabs): Tabs = "mac#anth_die_box"

fun parse_tabs_rec_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), content: !Buf, cursor: int, ts: Tabs): Tabs =
  if recfuel > 0 then (
  let
    val p_pos = find_substr(content, KEY_PATH, cursor)
  in
    if ilt(p_pos, 0) then ts
    else let
      val ts_next = parse_one_tab(content, p_pos, ts)
    in
      parse_tabs_rec_m(recfuel - 1, content, iadd(p_pos, KEY_PATH_LEN), ts_next)
    end
  end
  ) else parse_tabs_rec_exh(content, cursor, ts)

fun parse_tabs_rec(content: !Buf, cursor: int, ts: Tabs): Tabs = parse_tabs_rec_m(airlock_nat(MAX_REC_FUEL), content, cursor, ts)

fun extract_session_fields(content: !Buf, font_p: &Buf >> Buf, font_px: &int >> int, viewmode: &int >> int, split: &int >> int, active: &int >> int): void = let
  val fp_pos = find_substr(content, KEY_FONT_PATH, 0)
  val () = if ige(fp_pos, 0) then (if extract_str_after(content, iadd(fp_pos, KEY_FONT_PATH_LEN), font_p) then () else ()) else ()
  val px_pos = find_substr(content, KEY_FONT_PX, 0)
  val () = if ige(px_pos, 0) then font_px := extract_int_after(content, iadd(px_pos, KEY_FONT_PX_LEN), SESSION_DEFAULT_FONT_PX) else ()
  val vm_pos = find_substr(content, KEY_VIEWMODE, 0)
  val () = if ige(vm_pos, 0) then viewmode := extract_int_after(content, iadd(vm_pos, KEY_VIEWMODE_LEN), SESSION_DEFAULT_VIEWMODE) else ()
  val sp_pos = find_substr(content, KEY_SPLIT, 0)
  val () = if ige(sp_pos, 0) then split := extract_int_after(content, iadd(sp_pos, KEY_SPLIT_LEN), SESSION_DEFAULT_SPLIT) else ()
  val ac_pos = find_substr(content, KEY_ACTIVE, 0)
  val () = if ige(ac_pos, 0) then active := extract_int_after(content, iadd(ac_pos, KEY_ACTIVE_LEN), SESSION_DEFAULT_ACTIVE) else ()
in
end

implement conf_load_session(vault, font_p, font_px, viewmode, split, active, ts) = let
  var spath = buf_make(BUF_SZ_PATH)
  val () = session_path_into(vault, spath)
  var content = buf_make(BUF_SZ_LARGE)
  val r_ok = read_file(cstr(spath), content)
  val () = buf_free(spath)
in
  if r_ok then let
    val () = extract_session_fields(content, font_p, font_px, viewmode, split, active)
    val res = parse_tabs_rec(content, 0, ts)
    val () = buf_free(content)
  in
    res
  end else let
    val () = buf_free(content)
  in
    ts
  end
end
