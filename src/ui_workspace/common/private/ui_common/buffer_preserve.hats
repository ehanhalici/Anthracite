implement buffer_preserve(b) = ()
implement buffer_clear(b) = buf_set_len(b, 0)
implement buffer_push_byte(b, v) = buf_push(b, v)

implement push_if(b, go, v) =
  if is_on(go) then buf_push(b, v) else buffer_preserve(b)

fun bappend_loop {rem:nat} .<rem>. (b: &Buf >> Buf, s: string, rem: int(rem), i: int): void =
  if rem > 0 then let
    val () = buf_push(b, c_str_byte(s, i))
  in
    bappend_loop(b, s, rem - 1, iadd(i, 1))
  end else buffer_preserve(b)

implement buffer_append_string_range(b, s, i, n) =
  if ige(i, n) then buffer_preserve(b)
  else bappend_loop(b, s, airlock_span(i, n), i)

implement buffer_append_string(b, s) = buffer_append_string_range(b, s, 0, c_strlen(s))

implement buffer_append_string_if(b, go, s) =
  if is_on(go) then buffer_append_string(b, s) else buffer_preserve(b)

fun bcat_loop {rem:nat} .<rem>. (dst: &Buf >> Buf, src: !Buf, rem: int(rem), i: int): void =
  if rem > 0 then let
    val () = buf_push(dst, buf_get(src, i))
  in
    bcat_loop(dst, src, rem - 1, iadd(i, 1))
  end else buffer_preserve(dst)

implement buffer_append_range(dst, src, i, n) =
  if ige(i, n) then buffer_preserve(dst)
  else bcat_loop(dst, src, airlock_span(i, n), i)

implement buffer_append_all(dst, src) = let
  val n = buf_len(src)
in
  buffer_append_range(dst, src, 0, n)
end

fun digits_sub {v:nat} .<v>. (b: &Buf >> Buf, v: int(v)): void =
  if v > 0 then let
    val () = digits_sub(b, v / 10)
  in
    buffer_push_byte(b, iadd(CHAR_ZERO, imod(v, 10)))
  end else buffer_preserve(b)

implement buffer_append_integer(b, n0) = let
  val n = if ilt(n0, 0) then let val () = buffer_push_byte(b, CHAR_MINUS) in isub(0, n0) end else n0
in
  if ieq(n, 0) then buffer_push_byte(b, CHAR_ZERO)
  else if ige(n, 0) then digits_sub(b, airlock_nat(n))
  else buffer_preserve(b)
end

implement buffer_append_range_if(dst, src, i, n, go) =
  if is_on(go) then buffer_append_range(dst, src, i, n) else buffer_preserve(dst)

fun beq_loop {rem:nat} .<rem>. (a: !Buf, b: !Buf, rem: int(rem), i: int): bool =
  if rem > 0 then
    (if ine(buf_get(a, i), buf_get(b, i)) then false else beq_loop(a, b, rem - 1, iadd(i, 1)))
  else true

implement buffer_equal_from(a, b, i) =
  if ine(buf_len(a), buf_len(b)) then false
  else if ige(i, buf_len(a)) then true
  else beq_loop(a, b, airlock_span(i, buf_len(a)), i)

implement buffer_clone(src) = let
  var d = buf_make(iadd(buf_len(src), 1))
  val n = buf_len(src)
  val () = buffer_append_range(d, src, 0, n)
in
  d
end

implement buffer_c_string(b) = let
  val n = buf_len(b)
  val () = buf_set(b, n, 0)
in
  buf_cstr(b)
end

fun ends_loop {rem:nat} .<rem>. (b: !Buf, s: string, n: int, m: int, rem: int(rem), i: int): bool =
  if rem > 0 then
    (if ine(buf_get(b, iadd(isub(n, m), i)), c_str_byte(s, i)) then false
     else ends_loop(b, s, n, m, rem - 1, iadd(i, 1)))
  else true

fun ends_at(b: !Buf, s: string, n: int, m: int, i: int): bool =
  if ige(i, m) then true
  else ends_loop(b, s, n, m, airlock_span(i, m), i)

implement ends(b, s) = let
  val n = buf_len(b)
  val m = c_strlen(s)
in
  if ilt(n, m) then false else ends_at(b, s, n, m, 0)
end

fun to_lower_ch(c: int): int =
  if c >= 65 andalso c <= 90 then iadd(c, 32) else c

fun ends_ci_loop {rem:nat} .<rem>. (b: !Buf, s: string, n: int, m: int, rem: int(rem), i: int): bool =
  if rem > 0 then
    (if ine(to_lower_ch(buf_get(b, iadd(isub(n, m), i))), to_lower_ch(c_str_byte(s, i))) then false
     else ends_ci_loop(b, s, n, m, rem - 1, iadd(i, 1)))
  else true

fun ends_ci_at(b: !Buf, s: string, n: int, m: int, i: int): bool =
  if ige(i, m) then true
  else ends_ci_loop(b, s, n, m, airlock_span(i, m), i)

fun ends_ci(b: !Buf, s: string): bool = let
  val n = buf_len(b)
  val m = c_strlen(s)
in
  if ilt(n, m) then false else ends_ci_at(b, s, n, m, 0)
end

implement is_image_path(b) =
  ends_ci(b, ".png") orelse ends_ci(b, ".jpg") orelse ends_ci(b, ".jpeg")
  orelse ends_ci(b, ".bmp") orelse ends_ci(b, ".webp")

implement draw_s(f, r, x, y, s, c) =
  seen_int(font_draw(f, r, x, y, c_str_ptr(s), c_strlen(s), c))

implement join2(a, b) = let
  var d = buf_make(iadd(iadd(buf_len(a), buf_len(b)), 2))
  val na = buf_len(a)
  val slash = igt(na, 0) andalso ine(buf_get(a, isub(na, 1)), CHAR_SLASH)
  val () = buffer_append_range(d, a, 0, na)
  val () = push_if(d, toggle_of(slash), CHAR_SLASH)
  val () = buffer_append_range(d, b, 0, buf_len(b))
in
  d
end

fun last_slash_loop {rem:nat} .<rem>. (path: !Buf, rem: int(rem), i: int, a: int): int =
  if rem > 0 then
    last_slash_loop(path, rem - 1, iadd(i, 1), (if ieq(buf_get(path, i), CHAR_SLASH) then iadd(i, 1) else a))
  else a

implement last_slash(path, i, a) =
  if ige(i, buf_len(path)) then a
  else last_slash_loop(path, airlock_span(i, buf_len(path)), i, a)

implement base_name(path, dst) = let
  val a = last_slash(path, 0, 0)
  val () = buffer_clear(dst)
in
  buffer_append_range(dst, path, a, buf_len(path))
end

fun slash_loop {rem:nat} .<rem>. (path: !Buf, rem: int(rem), i: int, a: int): int =
  if rem > 0 then
    slash_loop(path, rem - 1, iadd(i, 1), (if ieq(buf_get(path, i), CHAR_SLASH) then i else a))
  else a

fun slash_at(path: !Buf, i: int, a: int): int =
  if ige(i, buf_len(path)) then a
  else slash_loop(path, airlock_span(i, buf_len(path)), i, a)

implement dirname_of(path, dst) = let
  val sl = slash_at(path, 0, ~1)
  val () = buffer_clear(dst)
in
  buffer_append_range_if(dst, path, 0, sl, toggle_of(ige(sl, 0)))
end

implement child_path(dir, name, dst) = let
  val () = buffer_clear(dst)
  val () = buffer_append_range(dst, dir, 0, buf_len(dir))
  val nd = buf_len(dir)
  val need_slash = igt(nd, 0) andalso ine(buf_get(dir, isub(nd, 1)), CHAR_SLASH)
  val () = if need_slash then buf_push(dst, CHAR_SLASH) else ()
in
  buffer_append_range(dst, name, 0, buf_len(name))
end

implement row_path(text, meta, row, dst) = let
  val off = buf_get32(meta, iadd(imul(row, 4), 2))
  val n = buf_get32(meta, iadd(imul(row, 4), 3))
  val () = buffer_clear(dst)
in
  buffer_append_range(dst, text, off, iadd(off, n))
end

fun has_dot_loop {rem:nat} .<rem>. (b: !Buf, rem: int(rem), i: int): bool =
  if rem > 0 then
    (if ieq(buf_get(b, i), CHAR_DOT) then true else has_dot_loop(b, rem - 1, iadd(i, 1)))
  else false

implement has_dot_char(b, i) =
  if ige(i, buf_len(b)) then false
  else has_dot_loop(b, airlock_span(i, buf_len(b)), i)

implement texture_is_valid(t) = anth_u2i(t)

fun has_esc_loop {rem:nat} .<rem>. (b: !Buf, rem: int(rem), i: int): bool =
  if rem > 0 then
    (if ieq(buf_get(b, i), CHAR_ESC) then true else has_esc_loop(b, rem - 1, iadd(i, 1)))
  else false

