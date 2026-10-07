#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "mem.sats"
staload "os/fs.sats"
staload "data_ast/doc.sats"
staload "ui_workspace/ui_common.sats"
staload "ui_workspace/ui_tab.sats"
staload "config/conf.sats"

fun b_app_str(b: &Buf >> Buf, s: string): void =
  bappend(b, s, 0, c_strlen(s))

fun bcat_all(dst: &Buf >> Buf, src: !Buf): void = let
  val n = buf_len(src)
in
  bcat(dst, src, 0, n)
end

fun digits_sub(b: &Buf >> Buf, v: int): void =
  if igt(v, 0) then let
    val () = digits_sub(b, idiv(v, 10))
  in
    bpush(b, iadd(48, imod(v, 10)))
  end else ()

fun b_app_int(b: &Buf >> Buf, n0: int): void = let
  val n = if ilt(n0, 0) then let val () = bpush(b, 45) in isub(0, n0) end else n0
in
  if ieq(n, 0) then bpush(b, 48)
  else digits_sub(b, n)
end

fun read_file(path: string, dst: &Buf >> Buf): int = let
  val sz = fs_size(path)
in
  if sz <= 0 orelse sz > 10000000 then 0
  else let
    val fd = fs_open_read(path)
  in
    if fd < 0 then 0
    else let
      val () = bclear(dst)
      val () = buf_ensure(dst, iadd(sz, 1))
      val n = fs_read(fd, buf_ptr(dst), sz)
      val () = fs_close(fd)
      val () = buf_set_len(dst, if igt(n, 0) then n else 0)
    in
      if igt(n, 0) then 1 else 0
    end
  end
end

fun write_file(path: string, src: !Buf): int = let
  val fd = fs_open_write(path)
in
  if fd < 0 then 0
  else let
    val n = buf_len(src)
    val w = if igt(n, 0) then fs_write(fd, buf_ptr(src), n) else 0
    val () = fs_close(fd)
  in
    if ige(w, 0) then 1 else 0
  end
end

fun init_dirs_sub(base: &Buf >> Buf, home: string, hlen: int): void =
  if igt(hlen, 0) then let
    val () = b_app_str(base, home)
    val () = b_app_str(base, "/.config")
    val _m1 = fs_mkdir(cstr(base))
    val () = b_app_str(base, "/anthracite")
    val _m2 = fs_mkdir(cstr(base))
  in
  end else let
    val () = b_app_str(base, ".config")
    val _m1 = fs_mkdir(cstr(base))
    val () = b_app_str(base, "/anthracite")
    val _m2 = fs_mkdir(cstr(base))
  in
  end

implement conf_init_dirs(base) = let
  val () = bclear(base)
  val home = c_getenv("HOME")
  val hlen = c_strlen(home)
  val () = init_dirs_sub(base, home, hlen)
in
  1
end

fun match_at(b: !Buf, p: int, k: int, slen: int, n: int, s: string): bool =
  if ige(k, slen) then true
  else if ige(iadd(p, k), n) then false
  else if ine(buf_get(b, iadd(p, k)), c_str_byte(s, k)) then false
  else match_at(b, p, iadd(k, 1), slen, n, s)

fun search_substr(b: !Buf, p: int, slen: int, n: int, s: string): int =
  if ige(iadd(p, slen), n) then ~1
  else if match_at(b, p, 0, slen, n, s) then p
  else search_substr(b, iadd(p, 1), slen, n, s)

fun find_substr(b: !Buf, s: string, from_i: int): int = let
  val n = buf_len(b)
  val slen = c_strlen(s)
in
  search_substr(b, from_i, slen, n, s)
end

fun skip_to_char(b: !Buf, i: int, n: int, ch: int): int =
  if ige(i, n) orelse ieq(buf_get(b, i), ch) then i
  else skip_to_char(b, iadd(i, 1), n, ch)

fun skip_spaces(b: !Buf, i: int, n: int): int =
  if ige(i, n) then i
  else let
    val c = buf_get(b, i)
  in
    if ieq(c, 32) orelse ieq(c, 9) orelse ieq(c, 10) then skip_spaces(b, iadd(i, 1), n)
    else i
  end

fun parse_digits_sub(b: !Buf, i: int, n: int, acc: int, has_digit: int): int =
  if ige(i, n) then (if igt(has_digit, 0) then acc else 0)
  else let
    val c = buf_get(b, i)
  in
    if ige(c, 48) andalso ile(c, 57) then
      parse_digits_sub(b, iadd(i, 1), n, iadd(imul(acc, 10), isub(c, 48)), 1)
    else
      acc
  end

fun extract_str_after(b: !Buf, pos: int, dst: &Buf >> Buf): int = let
  val n = buf_len(b)
  val i = skip_to_char(b, pos, n, 34)
in
  if ige(i, n) then 0
  else let
    val start = iadd(i, 1)
    val end_i = skip_to_char(b, start, n, 34)
  in
    if ige(end_i, n) then 0
    else let
      val () = bclear(dst)
      val () = bcat(dst, b, start, end_i)
    in
      1
    end
  end
end

fun extract_int_after(b: !Buf, pos: int, default_val: int): int = let
  val n = buf_len(b)
  val colon = skip_to_char(b, pos, n, 58)
  val after_c = if ilt(colon, n) then iadd(colon, 1) else colon
  val start = skip_spaces(b, after_c, n)
in
  if ige(start, n) then default_val
  else let
    val is_neg = if ieq(buf_get(b, start), 45) then 1 else 0
    val num_start = if ieq(is_neg, 1) then iadd(start, 1) else start
    val v = parse_digits_sub(b, num_start, n, 0, 0)
  in
    if ieq(is_neg, 1) then isub(0, v) else v
  end
end

fun parse_active_vault(read_ok: int, content: !Buf, dst: &Buf >> Buf): int =
  if ieq(read_ok, 1) then let
    val pos = find_substr(content, "\"active_vault\"", 0)
  in
    if ige(pos, 0) then extract_str_after(content, iadd(pos, 14), dst)
    else 0
  end else 0

implement conf_get_active_vault(dst) = let
  val () = bclear(dst)
  var base = buf_make(256)
  val _ok = conf_init_dirs(base)
  var vpath = buf_make(256)
  val () = bcat_all(vpath, base)
  val () = buf_free(base)
  val () = b_app_str(vpath, "/vaults.json")
  var content = buf_make(4096)
  val read_ok = read_file(cstr(vpath), content)
  val () = buf_free(vpath)
  val res = parse_active_vault(read_ok, content, dst)
  val () = buf_free(content)
in
  res
end

fun scan_vaults_rec(content: !Buf, cursor: int, paths: &Buf >> Buf, names: &Buf >> Buf, meta: &Buf >> Buf, cnt: &int >> int, tmp_p: &Buf >> Buf, tmp_n: &Buf >> Buf): void = let
  val p_pos = find_substr(content, "\"path\"", cursor)
in
  if ilt(p_pos, 0) then ()
  else let
    val ok_p = extract_str_after(content, iadd(p_pos, 6), tmp_p)
    val n_pos = find_substr(content, "\"name\"", p_pos)
    val _ok_n = if ige(n_pos, 0) then extract_str_after(content, iadd(n_pos, 6), tmp_n) else let val () = base_name(tmp_p, tmp_n) in 1 end
    val poff = buf_len(paths)
    val plen = buf_len(tmp_p)
    val () = bcat(paths, tmp_p, 0, plen)
    val noff = buf_len(names)
    val nlen = buf_len(tmp_n)
    val () = bcat(names, tmp_n, 0, nlen)
    val idx = cnt
    val () = buf_ensure(meta, iadd(imul(idx, 16), 16))
    val () = buf_set32(meta, imul(idx, 4), poff)
    val () = buf_set32(meta, iadd(imul(idx, 4), 1), plen)
    val () = buf_set32(meta, iadd(imul(idx, 4), 2), noff)
    val () = buf_set32(meta, iadd(imul(idx, 4), 3), nlen)
    val () = cnt := iadd(cnt, 1)
  in
    scan_vaults_rec(content, iadd(p_pos, 8), paths, names, meta, cnt, tmp_p, tmp_n)
  end
end

fun parse_vault_list(read_ok: int, content: !Buf, paths: &Buf >> Buf, names: &Buf >> Buf, meta: &Buf >> Buf, cnt: &int >> int): void =
  if ieq(read_ok, 1) then let
    var tmp_p = buf_make(256)
    var tmp_n = buf_make(64)
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
  var base = buf_make(256)
  val _ok = conf_init_dirs(base)
  var vpath = buf_make(256)
  val () = bcat_all(vpath, base)
  val () = buf_free(base)
  val () = b_app_str(vpath, "/vaults.json")
  var content = buf_make(4096)
  val read_ok = read_file(cstr(vpath), content)
  val () = buf_free(vpath)
  val () = parse_vault_list(read_ok, content, paths, names, meta, cnt)
  val () = buf_free(content)
in
end

fun search_conf_dir_rec(content: !Buf, cur: int, vault: string, dst: &Buf >> Buf, pbuf: &Buf >> Buf): int = let
  val p_pos = find_substr(content, "\"path\"", cur)
in
  if ilt(p_pos, 0) then 0
  else let
    val ok_p = extract_str_after(content, iadd(p_pos, 6), pbuf)
    val matches = if ieq(ok_p, 1) andalso ieq(c_strcmp(cstr(pbuf), vault), 0) then 1 else 0
  in
    if ieq(matches, 1) then let
      val cd_pos = find_substr(content, "\"conf_dir\"", p_pos)
      val ok_cd = if ige(cd_pos, 0) then extract_str_after(content, iadd(cd_pos, 10), dst) else 0
    in
      if ieq(ok_cd, 1) then 1 else 0
    end else
      search_conf_dir_rec(content, iadd(p_pos, 8), vault, dst, pbuf)
  end
end

fun find_vault_conf_dir_impl(content: !Buf, vault: string, dst: &Buf >> Buf): int = let
  var pbuf = buf_make(256)
  val res = search_conf_dir_rec(content, 0, vault, dst, pbuf)
  val () = buf_free(pbuf)
in
  res
end

fun write_existing_vaults_rec(vi: int, nvaults: int, paths: !Buf, names: !Buf, meta: !Buf, new_json: &Buf >> Buf, p_cur: &Buf >> Buf, n_cur: &Buf >> Buf, vault: string, already_in: &int >> int): void =
  if ige(vi, nvaults) then ()
  else let
    val poff = buf_get32(meta, imul(vi, 4))
    val plen = buf_get32(meta, iadd(imul(vi, 4), 1))
    val noff = buf_get32(meta, iadd(imul(vi, 4), 2))
    val nlen = buf_get32(meta, iadd(imul(vi, 4), 3))
    val () = bclear(p_cur)
    val () = bcat(p_cur, paths, poff, iadd(poff, plen))
    val () = bclear(n_cur)
    val () = bcat(n_cur, names, noff, iadd(noff, nlen))
    val same = if ieq(c_strcmp(cstr(p_cur), vault), 0) then 1 else 0
    val () = if ieq(same, 1) then already_in := 1 else ()
    val () = if igt(vi, 0) then b_app_str(new_json, ",\n") else ()
    val () = b_app_str(new_json, "    {\n      \"path\": \"")
    val () = bcat_all(new_json, p_cur)
    val () = b_app_str(new_json, "\",\n      \"name\": \"")
    val () = bcat_all(new_json, n_cur)
    val () = b_app_str(new_json, "\",\n      \"conf_dir\": \"v_")
    val () = b_app_int(new_json, vi)
    val () = b_app_str(new_json, "\"\n    }")
  in
    write_existing_vaults_rec(iadd(vi, 1), nvaults, paths, names, meta, new_json, p_cur, n_cur, vault, already_in)
  end

fun append_new_vault_if_needed(new_json: &Buf >> Buf, already_in: int, vault: string, nvaults: int): void =
  if ieq(already_in, 0) andalso igt(c_strlen(vault), 0) then let
    val () = if igt(nvaults, 0) then b_app_str(new_json, ",\n") else ()
    val () = b_app_str(new_json, "    {\n      \"path\": \"")
    val () = b_app_str(new_json, vault)
    val () = b_app_str(new_json, "\",\n      \"name\": \"")
    var bname = buf_make(64)
    var vbuf = buf_make(iadd(c_strlen(vault), 1))
    val () = b_app_str(vbuf, vault)
    val () = base_name(vbuf, bname)
    val () = buf_free(vbuf)
    val () = bcat_all(new_json, bname)
    val () = buf_free(bname)
    val () = b_app_str(new_json, "\",\n      \"conf_dir\": \"v_")
    val () = b_app_int(new_json, nvaults)
    val () = b_app_str(new_json, "\"\n    }\n")
  in
  end else let
    val () = b_app_str(new_json, "\n")
  in
  end

implement conf_set_active_vault(vault) = let
  var base = buf_make(256)
  val _ok = conf_init_dirs(base)
  var vpath = buf_make(256)
  val () = bcat_all(vpath, base)
  val () = buf_free(base)
  val () = b_app_str(vpath, "/vaults.json")
  var paths = buf_make(1024)
  var names = buf_make(256)
  var meta = buf_make(256)
  var nvaults: int = 0
  val () = conf_list_vaults(paths, names, meta, nvaults)
  var new_json = buf_make(8192)
  val () = b_app_str(new_json, "{\n  \"active_vault\": \"")
  val () = b_app_str(new_json, vault)
  val () = b_app_str(new_json, "\",\n  \"vaults\": [\n")
  var already_in: int = 0
  var p_cur = buf_make(256)
  var n_cur = buf_make(64)
  val () = write_existing_vaults_rec(0, nvaults, paths, names, meta, new_json, p_cur, n_cur, vault, already_in)
  val () = buf_free(p_cur)
  val () = buf_free(n_cur)
  val () = buf_free(paths)
  val () = buf_free(names)
  val () = buf_free(meta)
  val () = append_new_vault_if_needed(new_json, already_in, vault, nvaults)
  val () = b_app_str(new_json, "  ]\n}\n")
  val _w = write_file(cstr(vpath), new_json)
  val () = buf_free(new_json)
  val () = buf_free(vpath)
in
end

fun append_vault_dir(dst: &Buf >> Buf, found: int, cdir: !Buf): void =
  if ieq(found, 1) then bcat_all(dst, cdir)
  else b_app_str(dst, "v_0")

fun vault_conf_dir_path(vault: string, dst: &Buf >> Buf): void = let
  val () = bclear(dst)
  var base = buf_make(256)
  val _ok = conf_init_dirs(base)
  val () = bcat_all(dst, base)
  val () = b_app_str(dst, "/")
  var cdir = buf_make(64)
  var vpath = buf_make(256)
  val () = bcat_all(vpath, base)
  val () = buf_free(base)
  val () = b_app_str(vpath, "/vaults.json")
  var content = buf_make(8192)
  val _r = read_file(cstr(vpath), content)
  val () = buf_free(vpath)
  val found = find_vault_conf_dir_impl(content, vault, cdir)
  val () = buf_free(content)
  val () = append_vault_dir(dst, found, cdir)
  val () = buf_free(cdir)
  val _mk = fs_mkdir(cstr(dst))
in
end

fun tabs_to_json(ts: !Tabs, dst: &Buf >> Buf, i: int): void =
  case+ ts of
  | TNil() => ()
  | TCons(doc, path, title, sc, rest) => let
    val () = if igt(i, 0) then b_app_str(dst, ",\n") else ()
    val () = b_app_str(dst, "    {\"path\": \"")
    val () = bcat_all(dst, path)
    val () = b_app_str(dst, "\", \"scroll\": ")
    val () = b_app_int(dst, sc)
    val () = b_app_str(dst, "}")
  in
    tabs_to_json(rest, dst, iadd(i, 1))
  end

implement conf_save_session(vault, font_p, font_px, viewmode, split, active, ts) = let
  var vdir = buf_make(256)
  val () = vault_conf_dir_path(vault, vdir)
  var spath = buf_make(256)
  val () = bcat_all(spath, vdir)
  val () = buf_free(vdir)
  val () = b_app_str(spath, "/session.json")
  var json = buf_make(8192)
  val () = b_app_str(json, "{\n  \"font_path\": \"")
  val () = b_app_str(json, font_p)
  val () = b_app_str(json, "\",\n  \"font_px\": ")
  val () = b_app_int(json, font_px)
  val () = b_app_str(json, ",\n  \"viewmode\": ")
  val () = b_app_int(json, viewmode)
  val () = b_app_str(json, ",\n  \"split\": ")
  val () = b_app_int(json, split)
  val () = b_app_str(json, ",\n  \"active\": ")
  val () = b_app_int(json, active)
  val () = b_app_str(json, ",\n  \"tabs\": [\n")
  val () = tabs_to_json(ts, json, 0)
  val () = b_app_str(json, "\n  ]\n}\n")
  val _w = write_file(cstr(spath), json)
  val () = buf_free(spath)
  val () = buf_free(json)
in
end

fun parse_one_tab(content: !Buf, p_pos: int, ts: Tabs): Tabs = let
  var tmp_path = buf_make(256)
  val ok_p = extract_str_after(content, iadd(p_pos, 6), tmp_path)
  val sc_pos = find_substr(content, "\"scroll\"", p_pos)
  val sc = if ige(sc_pos, 0) then extract_int_after(content, iadd(sc_pos, 8), 0) else 0
  val p_str = cstr(tmp_path)
  val ex = fs_exists(p_str)
  val exists = if ieq(ok_p, 1) andalso ieq(ex, 1) then 1 else 0
in
  if ieq(exists, 1) then let
    val d = doc_open()
    val _load = doc_load(d, p_str)
    var tbuf = buf_make(64)
    val () = base_name(tmp_path, tbuf)
    val powned = bcopy(tmp_path)
    val () = buf_free(tmp_path)
  in
    tabs_append(ts, d, powned, tbuf, sc)
  end else let
    val () = buf_free(tmp_path)
  in
    ts
  end
end

fun parse_tabs_rec(content: !Buf, cursor: int, ts: Tabs): Tabs = let
  val p_pos = find_substr(content, "\"path\"", cursor)
in
  if ilt(p_pos, 0) then ts
  else let
    val ts_next = parse_one_tab(content, p_pos, ts)
  in
    parse_tabs_rec(content, iadd(p_pos, 8), ts_next)
  end
end

fun extract_session_fields(content: !Buf, font_p: &Buf >> Buf, font_px: &int >> int, viewmode: &int >> int, split: &int >> int, active: &int >> int): void = let
  val fp_pos = find_substr(content, "\"font_path\"", 0)
  val () = if ige(fp_pos, 0) then let val _x = extract_str_after(content, iadd(fp_pos, 11), font_p) in () end else ()
  val px_pos = find_substr(content, "\"font_px\"", 0)
  val () = if ige(px_pos, 0) then font_px := extract_int_after(content, iadd(px_pos, 9), 18) else ()
  val vm_pos = find_substr(content, "\"viewmode\"", 0)
  val () = if ige(vm_pos, 0) then viewmode := extract_int_after(content, iadd(vm_pos, 10), 0) else ()
  val sp_pos = find_substr(content, "\"split\"", 0)
  val () = if ige(sp_pos, 0) then split := extract_int_after(content, iadd(sp_pos, 7), 0) else ()
  val ac_pos = find_substr(content, "\"active\"", 0)
  val () = if ige(ac_pos, 0) then active := extract_int_after(content, iadd(ac_pos, 8), 0) else ()
in
end

implement conf_load_session(vault, font_p, font_px, viewmode, split, active, ts) = let
  var vdir = buf_make(256)
  val () = vault_conf_dir_path(vault, vdir)
  var spath = buf_make(256)
  val () = bcat_all(spath, vdir)
  val () = buf_free(vdir)
  val () = b_app_str(spath, "/session.json")
  var content = buf_make(8192)
  val r_ok = read_file(cstr(spath), content)
  val () = buf_free(spath)
in
  if ieq(r_ok, 1) then let
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
