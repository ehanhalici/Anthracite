fun parse_one_tab(content: !Buf, p_pos: int, ts: Tabs, tab_pane: &Buf >> Buf): Tabs = let
  var tmp_path = buf_make(BUF_SZ_PATH)
  val ok_p = extract_str_after(content, iadd(p_pos, KEY_PATH_LEN), tmp_path)
  val rbrace = skip_to_char(content, p_pos, buf_len(content), CHAR_RBRACE)
  val sc = read_tab_scroll(content, p_pos, rbrace)
  val pn = read_tab_pane(content, p_pos, rbrace)
  val p_str = buffer_c_string(tmp_path)
  val ex = fs_exists(p_str)
  val exists = ok_p andalso ieq(ex, 1)
in
  if exists then let
    val () = buf_push(tab_pane, pn)
  in
    open_tab(ts, tmp_path, sc)
  end else let
    val () = buf_free(tmp_path)
  in
    ts
  end
end

extern fun parse_tabs_rec_fuel_exhausted(content: !Buf, cursor: int, ts: Tabs, tab_pane: &Buf >> Buf): Tabs = "mac#anth_die_box"

fun parse_tabs_rec_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), content: !Buf, cursor: int, ts: Tabs, tab_pane: &Buf >> Buf
): Tabs =
  if recfuel > 0 then let
    val p_pos = find_substr(content, KEY_PATH, cursor)
  in
    if ilt(p_pos, 0) then ts
    else let
      val ts_next = parse_one_tab(content, p_pos, ts, tab_pane)
    in
      parse_tabs_rec_with_fuel(recfuel - 1, content, iadd(p_pos, KEY_PATH_LEN), ts_next, tab_pane)
    end
  end else parse_tabs_rec_fuel_exhausted(content, cursor, ts, tab_pane)

fun parse_tabs_rec(content: !Buf, cursor: int, ts: Tabs, tab_pane: &Buf >> Buf): Tabs =
  parse_tabs_rec_with_fuel(airlock_nat(MAX_REC_FUEL), content, cursor, ts, tab_pane)

fun parse_open_dirs_step(content: !Buf, q1: int, q2: int, open_dirs: &Buf >> Buf, tmp: &Buf >> Buf): void = let
  val () = buffer_clear(tmp)
  val () = buffer_append_range(tmp, content, iadd(q1, 1), q2)
  val () = if igt(buf_len(tmp), 0) then (
    buffer_append_all(open_dirs, tmp);
    buf_push(open_dirs, CHAR_LF)
  ) else ()
in
end

fun parse_open_dirs_rec_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), content: !Buf, cursor: int, end_pos: int,
  open_dirs: &Buf >> Buf, tmp: &Buf >> Buf
): void =
  if recfuel > 0 then (
    if ilt(cursor, end_pos) then let
      val q1 = skip_to_char(content, cursor, end_pos, CHAR_QUOTE)
    in
      if ige(q1, end_pos) then ()
      else let
        val q2 = skip_to_char(content, iadd(q1, 1), end_pos, CHAR_QUOTE)
      in
        if ige(q2, end_pos) then ()
        else let
          val () = parse_open_dirs_step(content, q1, q2, open_dirs, tmp)
        in
          parse_open_dirs_rec_with_fuel(recfuel - 1, content, iadd(q2, 1), end_pos, open_dirs, tmp)
        end
      end
    end else ()
  ) else ()

fun parse_open_dirs(content: !Buf, open_dirs: &Buf >> Buf): void = let
  val () = buffer_clear(open_dirs)
  val od_pos = find_substr(content, KEY_OPEN_DIRS, 0)
  val n = buf_len(content)
in
  if ige(od_pos, 0) then let
    val lb = skip_to_char(content, od_pos, n, CHAR_LBRACKET)
    val rb = skip_to_char(content, lb, n, CHAR_RBRACKET)
  in
    if ilt(lb, rb) andalso ilt(rb, n) then let
      var tmp = buf_make(BUF_SZ_PATH)
      val () = parse_open_dirs_rec_with_fuel(airlock_nat(MAX_REC_FUEL), content, iadd(lb, 1), rb, open_dirs, tmp)
      val () = buf_free(tmp)
    in
    end else ()
  end else ()
end

fun extract_session_side(content: !Buf, side_open: &int >> int, sidew: &int >> int): void = let
  val sb_pos = find_substr(content, KEY_SIDEBAR_OPEN, 0)
  val () = if ige(sb_pos, 0) then side_open := extract_int_after(content, iadd(sb_pos, KEY_SIDEBAR_OPEN_LEN), 1) else ()
  val sw_pos = find_substr(content, KEY_SIDEBAR_WIDTH, 0)
  val () = if ige(sw_pos, 0) then sidew := extract_int_after(content, iadd(sw_pos, KEY_SIDEBAR_WIDTH_LEN), 240) else ()
in
end

fun extract_session_fields(
  content: !Buf, font_p: &Buf >> Buf, font_px: &int >> int,
  viewmode: &int >> int, split: &int >> int, active: &int >> int,
  righti: &int >> int, side_open: &int >> int, sidew: &int >> int
): void = let
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
  val ra_pos = find_substr(content, KEY_RIGHT_ACTIVE, 0)
  val () = if ige(ra_pos, 0) then righti := extract_int_after(content, iadd(ra_pos, KEY_RIGHT_ACTIVE_LEN), 0) else ()
  val () = extract_session_side(content, side_open, sidew)
in
end

fun apply_loaded_session(
  content: !Buf, font_p: &Buf >> Buf, font_px: &int >> int,
  viewmode: &int >> int, split: &int >> int, active: &int >> int,
  righti: &int >> int, side_open: &int >> int, sidew: &int >> int,
  tab_pane: &Buf >> Buf, open_dirs: &Buf >> Buf, ts: Tabs
): Tabs = let
  val () = extract_session_fields(content, font_p, font_px, viewmode, split, active, righti, side_open, sidew)
  val () = parse_open_dirs(content, open_dirs)
  val () = buffer_clear(tab_pane)
in
  parse_tabs_rec(content, 0, ts, tab_pane)
end

fun fallback_empty_session(
  side_open: &int >> int, sidew: &int >> int,
  tab_pane: &Buf >> Buf, open_dirs: &Buf >> Buf, ts: Tabs
): Tabs = let
  val () = side_open := 1
  val () = sidew := 240
  val () = buffer_clear(tab_pane)
  val () = buffer_clear(open_dirs)
in
  ts
end

implement conf_load_session(vault, font_p, font_px, viewmode, split, active, righti, side_open, sidew, tab_pane, open_dirs, ts) = let
  var spath = buf_make(BUF_SZ_PATH)
  val () = session_path_into(vault, spath)
  var content = buf_make(BUF_SZ_LARGE)
  val r_ok = read_file(buffer_c_string(spath), content)
  val () = buf_free(spath)
in
  if r_ok then let
    val res = apply_loaded_session(content, font_p, font_px, viewmode, split, active, righti, side_open, sidew, tab_pane, open_dirs, ts)
    val () = buf_free(content)
  in
    res
  end else let
    val () = buf_free(content)
  in
    fallback_empty_session(side_open, sidew, tab_pane, open_dirs, ts)
  end
end
