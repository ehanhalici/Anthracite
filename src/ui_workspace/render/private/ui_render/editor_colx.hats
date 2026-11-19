fun editor_min_left(f: !Font, r: !Rend, ox: int): int = let
  val aw = font_arrow_w(f, r)
  val pad = imax(4, idiv(font_line_h(f), 4))
  val gap = imax(6, idiv(aw, 2))
  val min_gw = iadd(imul(aw, 5), iadd(gap, iadd(aw, pad)))
  val gw = imax(UI_GUTTER_WIDTH, min_gw)
in
  iadd(ox, iadd(gw, 16))
end

fun measure_80ch_w(f: !Font, r: !Rend): int = let
  var gm: gmet = @{ax= 0, bx= 0, top= 0, bw= 0, bh= 0, x0= 0, y0= 0, ok= Off}
  val () = font_glyph(f, r, 48, gm)
  val ch_w = if igt(gm.ax, 0) then gm.ax else imax(7, idiv(font_line_h(f), 2))
in
  imax(320, imul(ch_w, 80))
end

implement editor_colw(f, r, ox, pw) = let
  val min_left = editor_min_left(f, r, ox)
  val avail = imax(1, isub(iadd(ox, pw), iadd(min_left, 16)))
  val ch80 = measure_80ch_w(f, r)
in
  imin(ch80, avail)
end

implement editor_colx(f, r, ox, pw) = let
  val min_left = editor_min_left(f, r, ox)
  val colw = editor_colw(f, r, ox, pw)
  val ideal_x = iadd(ox, idiv(isub(pw, colw), 2))
  val max_x = imax(min_left, isub(iadd(ox, pw), iadd(colw, 16)))
in
  imin(max_x, imax(min_left, ideal_x))
end

fun arrow_revealed(d: !Doc, i: int, y: int, lh: int, hovy: int, viewmode: ViewMode): bool =
  if not(is_view_read(viewmode)) then true
  else if ige(hovy, y) andalso ilt(hovy, iadd(y, lh)) then true
  else ieq(doc_line_of(d, doc_caret(d)), doc_line_of(d, doc_node_start(d, i)))

fun draw_arrow(f: !Font, r: !Rend, d: !Doc, i: int, k: NodeKind, colx: int, y: int, lh: int, hovy: int, viewmode: ViewMode): void =
  if doc_is_foldable(d, i) andalso arrow_revealed(d, i, y, lh, hovy, viewmode) then let
    val folded = doc_node_collapsed(d, i)
    val arr = if is_on(folded) then ">" else "v"
    val acol = if is_on(folded) then col_accent_hi() else col_muted()
    val ax = arrow_pos_x(f, r, colx)
    val () = draw_s(f, r, ax, y, arr, acol)
  in
  end else ()


fun pen_unpack_line(pl: int): int =
  if pl < 0 then ~1 else idiv(pl, 256)

fun pen_unpack_row(pl: int): int =
  if pl < 0 then 0 else imod(pl, 256)

fun pen_pack(line: int, row: int): int =
  if line < 0 then ~1 else iadd(imul(line, 256), imin(255, row))

fun pen_inc_row(pl: int): int =
  if pl < 0 then 0 else iadd(pl, 1)

fun scan_word_end_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, p: int, en: int): int =
  if recursion_fuel_available(recfuel) then (
    if ige(p, en) then en
    else if ieq(doc_byte(d, p), CHAR_SPACE) then iadd(p, 1)
    else scan_word_end_with_fuel(recfuel - 1, d, iadd(p, 1), en)
  ) else en

fun visual_chunk_long(f: !Font, r: !Rend, d: !Doc, i0: int, w_end: int, max_w: int, scratch: &Buf >> _): int = let
  val width = visual_measure_w(d, i0, w_end, f, r, scratch)
in
  if igt(width, max_w) then
    visual_fit_prefix_with_fuel(airlock_nat(MAX_REC_FUEL), d, i0, i0, w_end, max_w, f, r, scratch)
  else w_end
end

fun visual_chunk_end(f: !Font, r: !Rend, d: !Doc, i0: int, j: int, scratch: &Buf >> _): int = let
  val w_end = scan_word_end_with_fuel(airlock_nat(MAX_REC_FUEL), d, i0, j)
  val wc = doc_get_wrap(d)
  val safe_wc = if igt(wc, 0) then wc else 80
  val max_w = imul(safe_wc, UI_WRAP_CELL_WIDTH)
in
  visual_chunk_long(f, r, d, i0, w_end, max_w, scratch)
end

fun visual_should_wrap(f: !Font, r: !Rend, d: !Doc, i0: int, kend: int, colx: int, pen_x: int, scratch: &Buf >> _): bool = let
  val scap = buf_cap(scratch)
  val n = doc_slice_buf(d, i0, kend, scratch, scap)
  val tw = if igt(n, 0) then font_width_buf(f, r, scratch, n) else 0
  val wc = doc_get_wrap(d)
  val max_w = if wc > 0 then imul(wc, UI_WRAP_CELL_WIDTH) else 720
  val max_x = iadd(colx, max_w)
in
  igt(pen_x, colx) andalso igt(iadd(pen_x, tw), max_x)
end

fun view_run_adv(f: !Font, r: !Rend, d: !Doc, i0: int, j: int, colx: int, oy: int, scroll: int, lh: int, ph: int, c: uint, scratch: &Buf >> _, pen_x: &int >> _, pen_line: &int >> _): int = let
  val scap = buf_cap(scratch)
  val cur_line = doc_line_of(d, i0)
  val pl_line = pen_unpack_line(pen_line)
  val () = if ine(cur_line, pl_line) then let
    val bx = line_base_pos(f, r, d, cur_line, colx, scratch)
  in
    pen_line := pen_pack(cur_line, 0); pen_x := bx
  end else ()
  val row = pen_unpack_row(pen_line)
  val yy = isub(iadd(oy, iadd(doc_line_y(d, cur_line), imul(row, lh))), scroll)
  val n = doc_slice_buf(d, i0, j, scratch, scap)
in
  if igt(n, 0) then (
    if ilt(iadd(yy, lh), oy) orelse igt(yy, iadd(oy, ph)) then
      font_width_buf(f, r, scratch, n)
    else
      font_draw_buf(f, r, pen_x, yy, scratch, n, c)
  ) else 0
end

fun view_newline_adv(f: !Font, r: !Rend, d: !Doc, i0: int, colx: int, scratch: &Buf >> _, pen_x: &int >> _, pen_line: &int >> _): void = let
  val cur_line = doc_line_of(d, i0)
  val next_line = iadd(cur_line, 1)
  val bx = (if ilt(next_line, doc_nlines(d)) then line_base_pos(f, r, d, next_line, colx, scratch) else colx)
  val () = pen_x := bx
  val () = pen_line := pen_pack(next_line, 0)
in
end

fun view_slice_step(
  f: !Font, r: !Rend, d: !Doc, i0: int, kend: int, j: int,
  colx: int, oy: int, scroll: int, lh: int, ph: int, c: uint,
  scratch: &Buf >> _, pen_x: &int >> _, pen_line: &int >> _
): int = let
  val wrap = visual_should_wrap(f, r, d, i0, kend, colx, pen_x, scratch)
  val () = if wrap then let
    val cur_line = doc_line_of(d, i0)
    val bx = line_base_pos(f, r, d, cur_line, colx, scratch)
  in
    pen_x := bx; pen_line := pen_inc_row(pen_line)
  end else ()
  val adv = view_run_adv(f, r, d, i0, kend, colx, oy, scroll, lh, ph, c, scratch, pen_x, pen_line)
  val () = pen_x := iadd(pen_x, adv)
  val is_mid = ilt(kend, j) andalso ine(doc_byte(d, isub(kend, 1)), CHAR_SPACE)
in
  if is_mid then let
    val cur_line = doc_line_of(d, i0)
    val row = pen_unpack_row(pen_line)
    val yy = isub(iadd(oy, iadd(doc_line_y(d, cur_line), imul(row, lh))), scroll)
    val () = anth_draw_wrap_arrow(f, r, pen_x, yy, col_muted())
    val bx = line_base_pos(f, r, d, cur_line, colx, scratch)
    val () = pen_x := bx
    val () = pen_line := pen_inc_row(pen_line)
  in adv end else adv
end

extern fun view_slice_fuel_exhausted(f: !Font, r: !Rend, d: !Doc, i0: int, b: int, colx: int, oy: int, scroll: int, lh: int, ph: int, c: uint, scratch: &Buf >> _, pen_x: &int >> _, pen_line: &int >> _, total: int): int = "mac#anth_die_int"

fun view_slice_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), f: !Font, r: !Rend, d: !Doc, i0: int, b: int,
  colx: int, oy: int, scroll: int, lh: int, ph: int, c: uint,
  scratch: &Buf >> _, pen_x: &int >> _, pen_line: &int >> _, total: int
): int =
  if recursion_fuel_available(recfuel) then (
    if ilt(i0, b) then
      if ieq(doc_byte(d, i0), CHAR_LF) then let
        val () = view_newline_adv(f, r, d, i0, colx, scratch, pen_x, pen_line)
      in
        view_slice_with_fuel(recfuel - 1, f, r, d, iadd(i0, 1), b, colx, oy, scroll, lh, ph, c, scratch, pen_x, pen_line, total)
      end else let
        val j = text_run_end(d, i0, b)
        val kend = visual_chunk_end(f, r, d, i0, j, scratch)
        val adv = view_slice_step(f, r, d, i0, kend, j, colx, oy, scroll, lh, ph, c, scratch, pen_x, pen_line)
      in
        view_slice_with_fuel(recfuel - 1, f, r, d, kend, b, colx, oy, scroll, lh, ph, c, scratch, pen_x, pen_line, iadd(total, adv))
      end
    else total
  ) else view_slice_fuel_exhausted(f, r, d, i0, b, colx, oy, scroll, lh, ph, c, scratch, pen_x, pen_line, total)

fun draw_rtl_view_slice(f: !Font,r: !Rend,d: !Doc,start: int,finish: int,colx: int,oy: int,scroll: int,
  line_height: int,slice_bytes: int,scratch: &Buf >> _,pen_x: &int >> _,pen_line: &int >> _): int = let
  val line=doc_line_of(d,start)
  val max_width=imul(doc_get_wrap(d),UI_WRAP_CELL_WIDTH)
  val text_width=font_width_buf(f,r,scratch,slice_bytes)
  val rows=plain_px_count_with_fuel(airlock_nat(MAX_REC_FUEL),f,r,d,start,finish,max_width,scratch)
  val y=isub(iadd(oy,doc_line_y(d,line)),scroll)
  val ()=plain_px_draw_with_fuel(airlock_nat(MAX_REC_FUEL),f,r,d,start,finish,colx,y,line_height,max_width,0,scratch)
  val ()=pen_line := pen_pack(line,rows)
  val ()=pen_x := iadd(colx,max_width)
in text_width end

fun draw_view_slice(f: !Font, r: !Rend, d: !Doc, a: int, b: int, colx: int, oy: int, scroll: int, lh: int, ph: int, c: uint, scratch: &Buf >> _, pen_x: &int >> _, pen_line: &int >> _): int =
 if doc_visual_active(d) then visual_draw_slice(f,r,d,a,b,colx,oy,scroll,lh,ph,c,scratch) else let
  val scap = buf_cap(scratch)
  val slen = if igt(b, a) then doc_slice_buf(d, a, b, scratch, scap) else 0
  val single = ieq(doc_line_of(d, a), doc_line_of(d, imax(a, isub(b, 1))))
  val is_rtl = if single andalso igt(slen, 0) then ui_text_line_direction_code(f, scratch, slen) else 0
in
  if igt(is_rtl,0) then draw_rtl_view_slice(f,r,d,a,b,colx,oy,scroll,lh,slen,scratch,pen_x,pen_line)
  else
    view_slice_with_fuel(airlock_nat(MAX_REC_FUEL), f, r, d, a, b, colx, oy, scroll, lh, ph, c, scratch, pen_x, pen_line, 0)
end

fun heading_scale(k: NodeKind, snum: &int >> _, sden: &int >> _): void =
  if is_kind(k, KH1) then (snum := 7; sden := 4)
  else if is_kind(k, KH2) then (snum := 3; sden := 2)
  else if is_kind(k, KH3) then (snum := 5; sden := 4)
  else if is_kind(k, KH4) then (snum := 23; sden := 20)
  else if is_kind(k, KH5) then (snum := 11; sden := 10)
  else (snum := 1; sden := 1)


extern fun skip_hash_fuel_exhausted(d: !Doc, st: int, b: int): int = "mac#anth_die_int"

fun skip_hash_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, st: int, b: int): int =
  if recursion_fuel_available(recfuel) then (
    if ilt(st, b) andalso ieq(doc_byte(d, st), CHAR_HASH) then skip_hash_with_fuel(recfuel - 1, d, iadd(st, 1), b)
    else st
  ) else skip_hash_fuel_exhausted(d, st, b)

extern fun skip_gap_fuel_exhausted(d: !Doc, st: int, b: int): int = "mac#anth_die_int"

fun skip_gap_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, st: int, b: int): int =
  if recursion_fuel_available(recfuel) then (
    if ilt(st, b) andalso (ieq(doc_byte(d, st), CHAR_SPACE) orelse ieq(doc_byte(d, st), CHAR_TAB)) then skip_gap_with_fuel(recfuel - 1, d, iadd(st, 1), b)
    else st
  ) else skip_gap_fuel_exhausted(d, st, b)

extern fun trim_tail_fuel_exhausted(d: !Doc, en: int, st: int): int = "mac#anth_die_int"

fun trim_tail_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, en: int, st: int): int =
  if recursion_fuel_available(recfuel) then (
    if igt(en, st) andalso (ieq(doc_byte(d, isub(en, 1)), CHAR_LF) orelse ieq(doc_byte(d, isub(en, 1)), CHAR_CR)) then trim_tail_with_fuel(recfuel - 1, d, isub(en, 1), st)
    else en
  ) else trim_tail_fuel_exhausted(d, en, st)
