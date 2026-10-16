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

fun scan_one_vault(content: !Buf, p_pos: int, paths: &Buf >> Buf, names: &Buf >> Buf, meta: &Buf >> Buf, cnt: &int >> int, tmp_p: &Buf >> Buf, tmp_n: &Buf >> Buf): void = let
  val ok_p = extract_str_after(content, iadd(p_pos, KEY_PATH_LEN), tmp_p)
  val () = if ok_p then () else ()
  val () = extract_vault_name(content, p_pos, tmp_p, tmp_n)
  val poff = buf_len(paths)
  val plen = buf_len(tmp_p)
  val () = buffer_append_range(paths, tmp_p, 0, plen)
  val noff = buf_len(names)
  val nlen = buf_len(tmp_n)
  val () = buffer_append_range(names, tmp_n, 0, nlen)
in
  record_vault_meta(meta, cnt, poff, plen, noff, nlen)
end

extern fun scan_vaults_rec_fuel_exhausted(content: !Buf, cursor: int, paths: &Buf >> Buf, names: &Buf >> Buf, meta: &Buf >> Buf, cnt: &int >> int, tmp_p: &Buf >> Buf, tmp_n: &Buf >> Buf): void = "mac#anth_die_void"

fun scan_vaults_rec_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), content: !Buf, cursor: int, paths: &Buf >> Buf, names: &Buf >> Buf, meta: &Buf >> Buf, cnt: &int >> int, tmp_p: &Buf >> Buf, tmp_n: &Buf >> Buf): void =
  if recursion_fuel_available(recfuel) then (
  let
    val p_pos = find_substr(content, KEY_PATH, cursor)
  in
    if ilt(p_pos, 0) then ()
    else let
      val () = scan_one_vault(content, p_pos, paths, names, meta, cnt, tmp_p, tmp_n)
    in
      scan_vaults_rec_with_fuel(recfuel - 1, content, iadd(p_pos, KEY_PATH_LEN), paths, names, meta, cnt, tmp_p, tmp_n)
    end
  end
  ) else scan_vaults_rec_fuel_exhausted(content, cursor, paths, names, meta, cnt, tmp_p, tmp_n)

fun scan_vaults_rec(content: !Buf, cursor: int, paths: &Buf >> Buf, names: &Buf >> Buf, meta: &Buf >> Buf, cnt: &int >> int, tmp_p: &Buf >> Buf, tmp_n: &Buf >> Buf): void = scan_vaults_rec_with_fuel(airlock_nat(MAX_REC_FUEL), content, cursor, paths, names, meta, cnt, tmp_p, tmp_n)

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
  val () = buffer_clear(paths)
  val () = buffer_clear(names)
  val () = buffer_clear(meta)
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

extern fun search_conf_dir_rec_fuel_exhausted(content: !Buf, cur: int, vault: string, dst: &Buf >> Buf, pbuf: &Buf >> Buf): int = "mac#anth_die_int"

fun search_conf_dir_rec_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), content: !Buf, cur: int, vault: string, dst: &Buf >> Buf, pbuf: &Buf >> Buf): int =
  if recursion_fuel_available(recfuel) then (
  let
    val p_pos = find_substr(content, KEY_PATH, cur)
  in
    if ilt(p_pos, 0) then 0
    else let
      val ok_p = extract_str_after(content, iadd(p_pos, KEY_PATH_LEN), pbuf)
      val matches = ok_p andalso ieq(c_strcmp(buffer_c_string(pbuf), vault), 0)
    in
      if matches then let
        val cd_pos = find_substr(content, KEY_CONF_DIR, p_pos)
        val ok_cd = if ige(cd_pos, 0) then extract_str_after(content, iadd(cd_pos, KEY_CONF_DIR_LEN), dst) else false
      in
        if ok_cd then 1 else 0
      end else
        search_conf_dir_rec_with_fuel(recfuel - 1, content, iadd(p_pos, KEY_PATH_LEN), vault, dst, pbuf)
    end
  end
  ) else search_conf_dir_rec_fuel_exhausted(content, cur, vault, dst, pbuf)

fun search_conf_dir_rec(content: !Buf, cur: int, vault: string, dst: &Buf >> Buf, pbuf: &Buf >> Buf): int = search_conf_dir_rec_with_fuel(airlock_nat(MAX_REC_FUEL), content, cur, vault, dst, pbuf)

fun find_vault_conf_dir_impl(content: !Buf, vault: string, dst: &Buf >> Buf): bool = let
  var pbuf = buf_make(BUF_SZ_PATH)
  val res = search_conf_dir_rec(content, 0, vault, dst, pbuf)
  val () = buf_free(pbuf)
in
  ieq(res, 1)
end

fun load_vault_strings(paths: !Buf, names: !Buf, meta: !Buf, vi: int, p_cur: &Buf >> Buf, n_cur: &Buf >> Buf): void = let
  val base_word = imul(vi, VAULT_META_STRIDE_WORDS)
  val poff = buf_get32(meta, iadd(base_word, VAULT_META_FIELD_POFF))
  val plen = buf_get32(meta, iadd(base_word, VAULT_META_FIELD_PLEN))
  val noff = buf_get32(meta, iadd(base_word, VAULT_META_FIELD_NOFF))
  val nlen = buf_get32(meta, iadd(base_word, VAULT_META_FIELD_NLEN))
  val () = buffer_clear(p_cur)
  val () = buffer_append_range(p_cur, paths, poff, iadd(poff, plen))
  val () = buffer_clear(n_cur)
  val () = buffer_append_range(n_cur, names, noff, iadd(noff, nlen))
in
end

fun mark_existing_vault(p_cur: !Buf, vault: string, already_in: &int >> int): void =
  if ieq(c_strcmp(buffer_c_string(p_cur), vault), 0) then already_in := 1 else ()

fun append_vault_entry(new_json: &Buf >> Buf, vi: int, p_cur: !Buf, n_cur: !Buf): void = let
  val () = if igt(vi, 0) then buffer_append_string(new_json, ",\n") else ()
  val () = buffer_append_string(new_json, "    {\n      \"path\": \"")
  val () = buffer_append_all(new_json, p_cur)
  val () = buffer_append_string(new_json, "\",\n      \"name\": \"")
  val () = buffer_append_all(new_json, n_cur)
  val () = buffer_append_string(new_json, "\",\n      \"conf_dir\": \"v_")
  val () = buffer_append_integer(new_json, vi)
  val () = buffer_append_string(new_json, "\"\n    }")
in
end

extern fun write_existing_vaults_rec_fuel_exhausted(vi: int, nvaults: int, paths: !Buf, names: !Buf, meta: !Buf, new_json: &Buf >> Buf, p_cur: &Buf >> Buf, n_cur: &Buf >> Buf, vault: string, already_in: &int >> int): void = "mac#anth_die_void"

fun write_existing_vaults_rec_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), vi: int, nvaults: int, paths: !Buf, names: !Buf, meta: !Buf, new_json: &Buf >> Buf, p_cur: &Buf >> Buf, n_cur: &Buf >> Buf, vault: string, already_in: &int >> int): void =
  if recursion_fuel_available(recfuel) then (
    if ige(vi, nvaults) then ()
    else let
      val () = load_vault_strings(paths, names, meta, vi, p_cur, n_cur)
      val () = mark_existing_vault(p_cur, vault, already_in)
      val () = append_vault_entry(new_json, vi, p_cur, n_cur)
    in
      write_existing_vaults_rec_with_fuel(recfuel - 1, iadd(vi, 1), nvaults, paths, names, meta, new_json, p_cur, n_cur, vault, already_in)
    end
  ) else write_existing_vaults_rec_fuel_exhausted(vi, nvaults, paths, names, meta, new_json, p_cur, n_cur, vault, already_in)

fun write_existing_vaults_rec(vi: int, nvaults: int, paths: !Buf, names: !Buf, meta: !Buf, new_json: &Buf >> Buf, p_cur: &Buf >> Buf, n_cur: &Buf >> Buf, vault: string, already_in: &int >> int): void = write_existing_vaults_rec_with_fuel(airlock_nat(MAX_REC_FUEL), vi, nvaults, paths, names, meta, new_json, p_cur, n_cur, vault, already_in)

fun append_new_vault_entry(new_json: &Buf >> Buf, vault: string, nvaults: int): void = let
  val () = if igt(nvaults, 0) then buffer_append_string(new_json, ",\n") else ()
  val () = buffer_append_string(new_json, "    {\n      \"path\": \"")
  val () = buffer_append_string(new_json, vault)
  val () = buffer_append_string(new_json, "\",\n      \"name\": \"")
  var bname = buf_make(BUF_SZ_NAME)
  var vbuf = buf_make(iadd(c_strlen(vault), 1))
  val () = buffer_append_string(vbuf, vault)
  val () = base_name(vbuf, bname)
  val () = buf_free(vbuf)
  val () = buffer_append_all(new_json, bname)
  val () = buf_free(bname)
  val () = buffer_append_string(new_json, "\",\n      \"conf_dir\": \"v_")
  val () = buffer_append_integer(new_json, nvaults)
  val () = buffer_append_string(new_json, "\"\n    }\n")
in
end

fun append_new_vault_if_needed(new_json: &Buf >> Buf, already_in: Toggle, vault: string, nvaults: int): void =
  if is_off(already_in) andalso igt(c_strlen(vault), 0) then append_new_vault_entry(new_json, vault, nvaults)
  else let
    val () = buffer_append_string(new_json, "\n")
  in
  end

fun build_vaults_json(vault: string, paths: !Buf, names: !Buf, meta: !Buf, nvaults: int): Buf = let
  var new_json = buf_make(BUF_SZ_LARGE)
  val () = buffer_append_string(new_json, "{\n  \"active_vault\": \"")
  val () = buffer_append_string(new_json, vault)
  val () = buffer_append_string(new_json, "\",\n  \"vaults\": [\n")
  var already_in: int = 0
  var p_cur = buf_make(BUF_SZ_PATH)
  var n_cur = buf_make(BUF_SZ_NAME)
  val () = write_existing_vaults_rec(0, nvaults, paths, names, meta, new_json, p_cur, n_cur, vault, already_in)
  val () = buf_free(p_cur)
  val () = buf_free(n_cur)
  val () = append_new_vault_if_needed(new_json, toggle_of(ieq(already_in, 1)), vault, nvaults)
  val () = buffer_append_string(new_json, "  ]\n}\n")
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
  val () = write_checked("vault_config_save", buffer_c_string(vpath), new_json)
  val () = buf_free(new_json)
in
end
