fun km_skip_ws_m {rem:nat} .<rem>. (b: !Buf, i: int, rem: int(rem)): int =
  if rem = 0 then i
  else if ieq(buf_get(b, i), CHAR_SPACE) orelse ieq(buf_get(b, i), CHAR_TAB) then
    km_skip_ws_m(b, iadd(i, 1), rem - 1)
  else i

fun km_skip_ws(b: !Buf, i: int, en: int): int =
  if ige(i, en) then en else km_skip_ws_m(b, i, airlock_span(i, en))

fun km_find_ws_m {rem:nat} .<rem>. (b: !Buf, i: int, rem: int(rem)): int =
  if rem = 0 then i
  else if ieq(buf_get(b, i), CHAR_SPACE) orelse ieq(buf_get(b, i), CHAR_TAB) then i
  else km_find_ws_m(b, iadd(i, 1), rem - 1)

fun km_find_ws(b: !Buf, i: int, en: int): int =
  if ige(i, en) then en else km_find_ws_m(b, i, airlock_span(i, en))

fun km_find_sep_m {rem:nat} .<rem>. (b: !Buf, i: int, rem: int(rem)): int =
  if rem = 0 then i
  else let val c = buf_get(b, i) in
    if ieq(c, CHAR_PLUS) orelse ieq(c, CHAR_MINUS) then i
    else km_find_sep_m(b, iadd(i, 1), rem - 1)
  end

fun km_find_sep(b: !Buf, i: int, en: int): int =
  if ige(i, en) then en else km_find_sep_m(b, i, airlock_span(i, en))

fun km_parse_key_name_a(b: !Buf, st: int, en: int): int =
  if km_slice_eq(b, st, en, "left") then KEYCODE_LEFT
  else if km_slice_eq(b, st, en, "right") then KEYCODE_RIGHT
  else if km_slice_eq(b, st, en, "up") then KEYCODE_UP
  else if km_slice_eq(b, st, en, "down") then KEYCODE_DOWN
  else if km_slice_eq(b, st, en, "backspace") then KEYCODE_BACKSPACE
  else if km_slice_eq(b, st, en, "delete") orelse km_slice_eq(b, st, en, "del") then KEYCODE_DELETE
  else if km_slice_eq(b, st, en, "home") then KEYCODE_HOME
  else if km_slice_eq(b, st, en, "end") then KEYCODE_END
  else if km_slice_eq(b, st, en, "return") orelse km_slice_eq(b, st, en, "enter") then KEYCODE_RETURN
  else if km_slice_eq(b, st, en, "tab") then KEYCODE_TAB
  else if km_slice_eq(b, st, en, "escape") orelse km_slice_eq(b, st, en, "esc") then KEYCODE_ESCAPE
  else if km_slice_eq(b, st, en, "pageup") orelse km_slice_eq(b, st, en, "page_up") then KEYCODE_PAGE_UP
  else if km_slice_eq(b, st, en, "pagedown") orelse km_slice_eq(b, st, en, "page_down") then KEYCODE_PAGE_DOWN
  else if km_slice_eq(b, st, en, "wheelup") orelse km_slice_eq(b, st, en, "wheel_up") then KEYCODE_WHEEL_UP
  else if km_slice_eq(b, st, en, "wheeldown") orelse km_slice_eq(b, st, en, "wheel_down") then KEYCODE_WHEEL_DOWN
  else if km_slice_eq(b, st, en, "space") then CHAR_SPACE
  else 0

fun km_parse_key_name(b: !Buf, st: int, en: int): int = let
  val n = isub(en, st)
in
  if ieq(n, 1) then km_lower_byte(buf_get(b, st))
  else km_parse_key_name_a(b, st, en)
end

fun km_mod_bit(b: !Buf, st: int, en: int): int =
  if km_slice_eq(b, st, en, "ctrl") orelse km_slice_eq(b, st, en, "c") then KEYMOD_CTRL
  else if km_slice_eq(b, st, en, "alt") orelse km_slice_eq(b, st, en, "m") orelse km_slice_eq(b, st, en, "meta") then KEYMOD_ALT
  else if km_slice_eq(b, st, en, "shift") orelse km_slice_eq(b, st, en, "s") then KEYMOD_SHIFT
  else 0

fun km_parse_chord_m {rem:nat} .<rem>. (
  b: !Buf, i: int, en: int, mods: &int >> _, key: &int >> _, rem: int(rem)
): bool =
  if rem = 0 then igt(key, 0)
  else if ige(i, en) then igt(key, 0)
  else let
    val sep = km_find_sep(b, i, en)
    val is_last = ige(sep, en) orelse (ieq(sep, i) andalso ieq(isub(en, i), 1))
  in
    if is_last then let
      val k = km_parse_key_name(b, i, en)
      val () = key := k
    in
      igt(k, 0)
    end else let
      val mb = km_mod_bit(b, i, sep)
    in
      if ieq(mb, 0) then false
      else let
        val () = mods := anth_ior(mods, mb)
      in
        km_parse_chord_m(b, iadd(sep, 1), en, mods, key, rem - 1)
      end
    end
  end

fun km_parse_one_chord(b: !Buf, st: int, en: int, out_m: &int >> _, out_k: &int >> _): bool = let
  var m: int = 0
  var k: int = 0
  val ok = if ilt(st, en) then km_parse_chord_m(b, st, en, m, k, airlock_span(st, en)) else false
  val () = out_m := m
  val () = out_k := k
in
  ok
end

implement keymap_parse_sequence(src, st0, en0, m1, k1, m2, k2) = let
  val st = km_skip_ws(src, st0, en0)
  val sp = km_find_ws(src, st, en0)
  val () = (m1 := 0; k1 := 0; m2 := 0; k2 := 0)
in
  if ige(st, en0) then false
  else if ige(sp, en0) then km_parse_one_chord(src, st, en0, m1, k1)
  else let
    val st2 = km_skip_ws(src, sp, en0)
    val ok1 = km_parse_one_chord(src, st, sp, m1, k1)
  in
    if ige(st2, en0) then ok1
    else ok1 andalso km_parse_one_chord(src, st2, km_find_ws(src, st2, en0), m2, k2)
  end
end

fun km_append_extra_key(dst: &Buf >> _, key: int): void =
  if ieq(key, KEYCODE_PAGE_DOWN) then buffer_append_string(dst, "PageDown")
  else if ieq(key, KEYCODE_WHEEL_UP) then buffer_append_string(dst, "WheelUp")
  else if ieq(key, KEYCODE_WHEEL_DOWN) then buffer_append_string(dst, "WheelDown")
  else if ieq(key, CHAR_SPACE) then buffer_append_string(dst, "Space")
  else if ige(key, CHAR_LOWER_A) andalso ile(key, CHAR_LOWER_Z) then buffer_push_byte(dst, isub(key, 32))
  else if ige(key, 33) andalso ile(key, 126) then buffer_push_byte(dst, key)
  else buffer_preserve(dst)

fun km_append_key_name(dst: &Buf >> _, key: int): void =
  if ieq(key, KEYCODE_LEFT) then buffer_append_string(dst, "Left")
  else if ieq(key, KEYCODE_RIGHT) then buffer_append_string(dst, "Right")
  else if ieq(key, KEYCODE_UP) then buffer_append_string(dst, "Up")
  else if ieq(key, KEYCODE_DOWN) then buffer_append_string(dst, "Down")
  else if ieq(key, KEYCODE_BACKSPACE) then buffer_append_string(dst, "Backspace")
  else if ieq(key, KEYCODE_DELETE) then buffer_append_string(dst, "Delete")
  else if ieq(key, KEYCODE_HOME) then buffer_append_string(dst, "Home")
  else if ieq(key, KEYCODE_END) then buffer_append_string(dst, "End")
  else if ieq(key, KEYCODE_RETURN) then buffer_append_string(dst, "Return")
  else if ieq(key, KEYCODE_TAB) then buffer_append_string(dst, "Tab")
  else if ieq(key, KEYCODE_ESCAPE) then buffer_append_string(dst, "Escape")
  else if ieq(key, KEYCODE_PAGE_UP) then buffer_append_string(dst, "PageUp")
  else km_append_extra_key(dst, key)

implement keymap_format_chord(mods, key, dst) = let
  val () = if ine(anth_iand(mods, KEYMOD_CTRL), 0) then buffer_append_string(dst, "Ctrl+") else ()
  val () = if ine(anth_iand(mods, KEYMOD_ALT), 0) then buffer_append_string(dst, "Alt+") else ()
  val () = if ine(anth_iand(mods, KEYMOD_SHIFT), 0) then buffer_append_string(dst, "Shift+") else ()
in
  km_append_key_name(dst, key)
end
