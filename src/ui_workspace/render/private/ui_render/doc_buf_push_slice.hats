fun doc_buf_push_slice_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, st: int, en: int, i: int, dst: &Buf >> _): void =
  if recursion_fuel_available(recfuel) then (
    if ilt(i, en) then let
      val () = buf_push(dst, doc_byte(d, i))
    in
      doc_buf_push_slice_with_fuel(recfuel - 1, d, st, en, iadd(i, 1), dst)
    end else ()
  ) else ()

implement take_path(d, i, dst) = let
  val () = buffer_clear(dst)
  val kd = doc_find_child(d, i, KLinkDest)
  val kw = (if ilt(kd, 0) then doc_find_child(d, i, KWikiTarget) else ~1)
  val target = (if ige(kd, 0) then kd else kw)
in
  if ige(target, 0) then let
    val cs = doc_node_start(d, target)
    val ce = doc_node_end(d, target)
  in
    doc_buf_push_slice_with_fuel(airlock_nat(MAX_REC_FUEL), d, cs, ce, cs, dst)
  end else let
    val a0 = doc_node_start(d, i)
    val b0 = doc_node_end(d, i)
  in
    take_path_with_fuel(airlock_nat(MAX_REC_FUEL), d, ScanSeek(), a0, b0, dst)
  end
end

implement take_anchor(d, i, dst) = let
  val () = buffer_clear(dst)
  val kb = doc_find_child(d, i, KWikiBlock)
  val kh = (if ilt(kb, 0) then doc_find_child(d, i, KWikiHeading) else ~1)
  val target = (if ige(kb, 0) then kb else kh)
in
  if ige(target, 0) then let
    val cs0 = doc_node_start(d, target)
    val ce = doc_node_end(d, target)
    val cs = (if ilt(cs0, ce) andalso ieq(doc_byte(d, cs0), CHAR_HASH) then iadd(cs0, 1) else cs0)
  in
    doc_buf_push_slice_with_fuel(airlock_nat(MAX_REC_FUEL), d, cs, ce, cs, dst)
  end else ()
end

implement resolve_path(vault, rel, dst) = let
  val () = buffer_clear(dst)
  val s = anth_resolve_vault_path(buffer_c_string(vault), buffer_c_string(rel))
  val () = buffer_append_string(dst, s)
in
end

implement with_md(path, dst) = let
  val () = buffer_clear(dst)
  val () = buffer_append_range(dst, path, 0, buf_len(path))
in
  buffer_append_string_if(dst, toggle_of(not(ends(path, ".md") orelse is_image_path(path))), ".md")
end

extern fun count_nl_fuel_exhausted(b: !Buf, capn: int, i: int, k: int): int = "mac#anth_die_int"

fun count_nl_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), b: !Buf, capn: int, i: int, k: int): int =
  if recursion_fuel_available(recfuel) then (
    if ige(i, buf_len(b)) orelse ige(k, capn) then k
    else count_nl_with_fuel(recfuel - 1, b, capn, iadd(i, 1), (if ieq(buf_get(b, i), CHAR_LF) then iadd(k, 1) else k))
  ) else count_nl_fuel_exhausted(b, capn, i, k)

fun count_nl(b: !Buf, capn: int, i: int, k: int): int = count_nl_with_fuel(airlock_nat(MAX_REC_FUEL), b, capn, i, k)

implement read_available_file_bytes(b, fd, sz) =
  if fd < 0 then let
    val () = seen_buf(b)
  in
    0
  end else fs_read_buf(fd, b, sz)

fun file_lines(path: !Buf, capn: int): int = let
  val p = buffer_c_string(path)
  val sz = fs_size(p)
in
  if sz <= 0 orelse sz > 50000000 then 0
  else let
    val fd = fs_open_read(p)
    var b = buf_make(iadd(sz, 1))
    val n = read_available_file_bytes(b, fd, sz)
    val () = if fd >= 0 then fs_close(fd) else ()
    val () = buf_set_len(b, if igt(n, 0) then n else 0)
    val k = count_nl(b, capn, 0, 1)
    val () = buf_free(b)
  in
    k
  end
end

fun load_tex(path: !Buf, r: !Rend, w: &int >> _, h: &int >> _): uint = let
  val im = img_open()
  val p = buffer_c_string(path)
  val ok = img_load(im, p)
  val tex = if ieq(ok, 1) then img_upload(im, r) else 0u
  val () = w := image_width(im)
  val () = h := image_height(im)
  val () = img_free(im)
in
  tex
end


fun ensure_tex_miss(c: &Cache >> _, path: !Buf, r: !Rend, w: &int >> _, h: &int >> _): uint = let
  val t = load_tex(path, r, w, h)
  val owned = buffer_clone(path)
  val () = c := cache_put(c, owned, t, w, h)
in
  t
end

fun ensure_tex(c: &Cache >> _, path: !Buf, r: !Rend, w: &int >> _, h: &int >> _): uint = let
  var tex: uint = 0u
  var iw: int = 0
  var ih: int = 0
  var hit: Toggle = Off
  val c2 = cache_lookup(c, path, tex, iw, ih, hit)
  val () = c := c2
in
  if is_on(hit) then let
    val () = w := iw
    val () = h := ih
  in
    tex
  end else ensure_tex_miss(c, path, r, w, h)
end


fun skip_spaces_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, p: int, en: int): int =
  if recursion_fuel_available(recfuel) then (
    if ilt(p, en) then let
      val c = doc_byte(d, p)
    in
      if ieq(c, 32) orelse ieq(c, 9) then skip_spaces_with_fuel(recfuel - 1, d, iadd(p, 1), en)
      else p
    end else en
  ) else en

fun skip_spaces(d: !Doc, p: int, en: int): int =
  skip_spaces_with_fuel(airlock_nat(MAX_REC_FUEL), d, p, en)

fun parse_digits_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, p: int, en: int, acc: int): @(int, int) =
  if recursion_fuel_available(recfuel) then (
    if ilt(p, en) then let
      val c = doc_byte(d, p)
    in
      if ige(c, 48) andalso ile(c, 57) then
        parse_digits_with_fuel(recfuel - 1, d, iadd(p, 1), en, iadd(imul(acc, 10), isub(c, 48)))
      else @(p, acc)
    end else @(en, acc)
  ) else @(p, acc)

fun parse_digits(d: !Doc, p: int, en: int): @(int, int) =
  parse_digits_with_fuel(airlock_nat(MAX_REC_FUEL), d, p, en, 0)

fun parse_image_dim(d: !Doc, p1: int, en: int, w: int): @(int, int) = let
  val p2 = skip_spaces(d, p1, en)
in
  if ilt(p2, en) then let
    val c = doc_byte(d, p2)
  in
    if ieq(c, 120) orelse ieq(c, 88) then let
      val p3 = skip_spaces(d, iadd(p2, 1), en)
      val @(p4, h) = parse_digits(d, p3, en)
      val p5 = skip_spaces(d, p4, en)
    in
      if ieq(p5, en) andalso igt(h, 0) then @(w, h)
      else @(w, 0)
    end else @(0, 0)
  end else if ieq(p2, en) then @(w, 0)
  else @(0, 0)
end

fun parse_image_size_str(d: !Doc, st: int, en: int): @(int, int) = let
  val p0 = skip_spaces(d, st, en)
in
  if ilt(p0, en) then let
    val c0 = doc_byte(d, p0)
  in
    if ieq(c0, 120) orelse ieq(c0, 88) then let
      val p1 = skip_spaces(d, iadd(p0, 1), en)
      val @(p2, h) = parse_digits(d, p1, en)
      val p3 = skip_spaces(d, p2, en)
    in
      if ieq(p3, en) andalso igt(h, 0) then @(0, h) else @(0, 0)
    end else let
      val @(p1, w) = parse_digits(d, p0, en)
    in
      if igt(w, 0) then parse_image_dim(d, p1, en, w) else @(0, 0)
    end
  end else @(0, 0)
end

fun find_last_pipe_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, p: int, st: int): int =
  if recursion_fuel_available(recfuel) then (
    if ige(p, st) then (
      if ieq(doc_byte(d, p), CHAR_PIPE) then p
      else find_last_pipe_with_fuel(recfuel - 1, d, isub(p, 1), st)
    ) else ~1
  ) else ~1
