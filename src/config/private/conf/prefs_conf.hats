(* Global cross-vault PC preferences persisted at <config_dir>/config.json. *)

fun prefs_path_into(dst: &Buf >> Buf): bool = let
  var base = buf_make(BUF_SZ_PATH)
  val ok = conf_init_dirs(base)
  val () = buffer_clear(dst)
in
  if ok then let
    val () = buffer_append_all(dst, base)
    val () = buffer_append_string(dst, "/config.json")
    val () = buf_free(base)
  in
    true
  end else let
    val () = buf_free(base)
  in
    false
  end
end

fun build_prefs_json(json: &Buf >> Buf, font_p: string, font_px: int, doc_font_px: int, sidew: int): void = let
  val () = buffer_clear(json)
  val () = buffer_append_string(json, "{\n  \"font_path\": \"")
  val () = buffer_append_string(json, font_p)
  val () = buffer_append_string(json, "\",\n  \"font_px\": ")
  val () = buffer_append_integer(json, font_px)
  val () = buffer_append_string(json, ",\n  \"doc_font_px\": ")
  val () = buffer_append_integer(json, doc_font_px)
  val () = buffer_append_string(json, ",\n  \"sidebar_width\": ")
  val () = buffer_append_integer(json, sidew)
in
  buffer_append_string(json, "\n}\n")
end

implement conf_save_prefs(font_p, font_px, doc_font_px, sidew) = let
  var ppath = buf_make(BUF_SZ_PATH)
  val ok = prefs_path_into(ppath)
in
  if not(ok) then buf_free(ppath)
  else let
    var json = buf_make(BUF_SZ_CONTENT)
    val () = build_prefs_json(json, font_p, font_px, doc_font_px, sidew)
    val () = write_checked("prefs_save", buffer_c_string(ppath), json)
    val () = buf_free(json)
  in
    buf_free(ppath)
  end
end

fun copy_font_if_nonempty(src: !Buf, dst: &Buf >> Buf): void =
  if igt(buf_len(src), 0) then (
    buffer_clear(dst);
    buffer_append_all(dst, src)
  ) else ()

fun apply_loaded_prefs(
  content: !Buf, font_p: &Buf >> Buf, font_px: &int >> int, doc_font_px: &int >> int, sidew: &int >> int
): void = let
  var tmp_fp = buf_make(BUF_SZ_PATH)
  val () = buffer_clear(tmp_fp)
  val () = extract_session_fonts(content, tmp_fp, font_px, doc_font_px)
  val () = copy_font_if_nonempty(tmp_fp, font_p)
  val () = buf_free(tmp_fp)
  val sw_pos = find_substr(content, KEY_SIDEBAR_WIDTH, 0)
in
  if ige(sw_pos, 0) then sidew := extract_int_after(content, iadd(sw_pos, KEY_SIDEBAR_WIDTH_LEN), sidew)
  else ()
end

fun read_and_apply_prefs(
  path_str: string, font_p: &Buf >> Buf, font_px: &int >> int, doc_font_px: &int >> int, sidew: &int >> int
): bool = let
  var content = buf_make(BUF_SZ_CONTENT)
  val r_ok = read_file(path_str, content)
in
  if r_ok then let
    val () = apply_loaded_prefs(content, font_p, font_px, doc_font_px, sidew)
    val () = buf_free(content)
  in
    true
  end else let
    val () = buf_free(content)
  in
    false
  end
end

implement conf_load_prefs(font_p, font_px, doc_font_px, sidew) = let
  var ppath = buf_make(BUF_SZ_PATH)
  val ok = prefs_path_into(ppath)
in
  if ok then let
    val res = read_and_apply_prefs(buffer_c_string(ppath), font_p, font_px, doc_font_px, sidew)
    val () = buf_free(ppath)
  in
    res
  end else let
    val () = buf_free(ppath)
  in
    false
  end
end
