fun line_y_bsearch(d: !Doc, docy: int, lo: int, hi: int, best: int): int = line_y_bsearch_with_fuel(airlock_nat(MAX_REC_FUEL), d, docy, lo, hi, best)

fun line_at_y(d: !Doc, docy: int, i: int, best: int): int =
  line_y_bsearch(d, docy, 0, isub(doc_nlines(d), 1), 0)

fun line_at_y_fast(d: !Doc, docy: int, lh: int): int = let
  val n = doc_nlines(d)
  val () = seen_int(lh)
in
  if ile(n, 1) then 0
  else line_at_y(d, docy, 0, 0)
end

extern fun plain_rows_fuel_exhausted(f: !Font, r: !Rend, d: !Doc, st: int, en: int, colx: int, yy: int, safe_lh: int, wc: int, row: int, rows: int, scratch: &Buf >> _): void = "mac#anth_die_void"

fun plain_row_step(f: !Font, r: !Rend, d: !Doc, st: int, en: int, colx: int, yy: int, safe_lh: int, wc: int, row: int, rows: int, scratch: &Buf >> _): void = let
  val rst = (if wc > 0 then doc_advance_cps(d, st, en, imul(row, wc)) else st) : int
  val ren = (if wc > 0 then doc_advance_cps(d, rst, en, wc) else en) : int
  val base_x = row_base_pos(f, r, d, rst, ren, colx, scratch)
  val scap = buf_cap(scratch)
  val n = if igt(ren, rst) then doc_slice_buf(d, rst, ren, scratch, scap) else 0
  val row_y = iadd(yy, imul(row, safe_lh))
  val is_rtl = if igt(n, 0) then ui_text_line_direction_code(f, scratch, n) else 0
  val tw = if igt(n, 0) then font_width_buf(f, r, scratch, n) else 0
  val () = if igt(n, 0) then seen_int(font_draw_buf(f, r, base_x, row_y, scratch, n, col_text())) else ()
  val ax = if igt(is_rtl, 0) then imax(colx, isub(base_x, 12)) else iadd(base_x, tw)
in
  if ilt(iadd(row, 1), rows) then anth_draw_wrap_arrow(f, r, ax, row_y, col_muted()) else ()
end

fun plain_rows_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), f: !Font, r: !Rend, d: !Doc, st: int, en: int,
  colx: int, yy: int, safe_lh: int, wc: int, row: int, rows: int, scratch: &Buf >> _
): void =
  if recfuel > 0 then (
    if ilt(row, rows) then let
      val () = plain_row_step(f, r, d, st, en, colx, yy, safe_lh, wc, row, rows, scratch)
    in
      plain_rows_with_fuel(recfuel - 1, f, r, d, st, en, colx, yy, safe_lh, wc, iadd(row, 1), rows, scratch)
    end else ()
  ) else plain_rows_fuel_exhausted(f, r, d, st, en, colx, yy, safe_lh, wc, row, rows, scratch)

fun visual_measure_w(
  d: !Doc, i0: int, p: int, f: !Font, r: !Rend, scratch: &Buf >> _
): int = let
  val scap = buf_cap(scratch)
  val n = doc_slice_buf(d, i0, p, scratch, scap)
in
  if igt(n, 0) then font_width_buf(f, r, scratch, n) else 0
end

fun visual_fit_step(
  d: !Doc, i0: int, lo: int, hi: int, max_w: int,
  f: !Font, r: !Rend, scratch: &Buf >> _
): int = let
  val count = doc_codepoints(d, lo, hi)
  val half = idiv(count, 2)
in
  if ile(half, 0) then
    (if igt(visual_measure_w(d, i0, hi, f, r, scratch), max_w) then
      (if ieq(lo, i0) then doc_advance_cps(d, i0, hi, 1) else lo)
    else hi)
  else let
    val mid = doc_advance_cps(d, lo, hi, half)
    val w = visual_measure_w(d, i0, mid, f, r, scratch)
  in
    if igt(w, max_w) then ~mid else mid
  end
end

fun visual_fit_prefix_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, i0: int, lo: int, hi: int,
  max_w: int, f: !Font, r: !Rend, scratch: &Buf >> _
): int =
  if recfuel > 0 then let
    val res = visual_fit_step(d, i0, lo, hi, max_w, f, r, scratch)
  in
    if ilt(res, 0) then
      visual_fit_prefix_with_fuel(recfuel - 1, d, i0, lo, ~res, max_w, f, r, scratch)
    else if ieq(res, lo) orelse ieq(res, hi) then res
    else
      visual_fit_prefix_with_fuel(recfuel - 1, d, i0, res, hi, max_w, f, r, scratch)
  end else (if ieq(lo, i0) then doc_advance_cps(d, i0, hi, 1) else lo)

fun plain_px_end(f: !Font, r: !Rend, d: !Doc, st: int, en: int, max_w: int, scratch: &Buf >> _): int = let
  val width = visual_measure_w(d, st, en, f, r, scratch)
in
  if igt(width, max_w) then visual_fit_prefix_with_fuel(airlock_nat(MAX_REC_FUEL), d, st, st, en, max_w, f, r, scratch) else en
end

extern fun plain_px_count_fuel_exhausted(f: !Font, r: !Rend, d: !Doc, st: int, en: int, max_w: int, scratch: &Buf >> _): int = "mac#anth_die_int"

fun plain_px_count_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), f: !Font, r: !Rend, d: !Doc, st: int, en: int, max_w: int, scratch: &Buf >> _
): int =
  if recfuel > 0 then
    if ige(st, en) then 0 else let
      val next = plain_px_end(f, r, d, st, en, max_w, scratch)
    in
      iadd(1, plain_px_count_with_fuel(recfuel - 1, f, r, d, next, en, max_w, scratch))
    end
  else plain_px_count_fuel_exhausted(f, r, d, st, en, max_w, scratch)

extern fun plain_px_draw_fuel_exhausted(f: !Font, r: !Rend, d: !Doc, st: int, en: int, colx: int, yy: int, lh: int, max_w: int, row: int, scratch: &Buf >> _): void = "mac#anth_die_void"

fun plain_px_draw_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), f: !Font, r: !Rend, d: !Doc, st: int, en: int,
  colx: int, yy: int, lh: int, max_w: int, row: int, scratch: &Buf >> _
): void =
  if recfuel > 0 then
    if ige(st, en) then () else let
      val next = plain_px_end(f, r, d, st, en, max_w, scratch)
      val base_x = row_base_pos(f, r, d, st, next, colx, scratch)
      val scap = buf_cap(scratch)
      val n = doc_slice_buf(d, st, next, scratch, scap)
      val tw = if igt(n, 0) then font_width_buf(f, r, scratch, n) else 0
      val row_y = iadd(yy, imul(row, lh))
      val is_rtl = if igt(n, 0) then ui_text_line_direction_code(f, scratch, n) else 0
      val ax = if igt(is_rtl, 0) then imax(colx, isub(base_x, 12)) else iadd(base_x, tw)
      val () = if igt(n, 0) then seen_int(font_draw_buf(f, r, base_x, row_y, scratch, n, col_text())) else ()
      val () = if ilt(next, en) then anth_draw_wrap_arrow(f, r, ax, row_y, col_muted()) else ()
    in
      plain_px_draw_with_fuel(recfuel - 1, f, r, d, next, en, colx, yy, lh, max_w, iadd(row, 1), scratch)
    end
  else plain_px_draw_fuel_exhausted(f, r, d, st, en, colx, yy, lh, max_w, row, scratch)

fun draw_single_plain_row(f: !Font,r: !Rend,d: !Doc,start: int,finish: int,colx: int,y: int,scratch: &Buf >> _): void = let
  val capacity=buf_cap(scratch)
  val size=imin(isub(finish,start),capacity)
  val count=if igt(size,0) then doc_slice_buf(d,start,iadd(start,size),scratch,capacity) else 0
  val base=row_base_pos(f,r,d,start,finish,colx,scratch)
in if igt(count,0) then seen_int(font_draw_buf(f,r,base,y,scratch,count,col_text())) else () end

fun draw_plain_line(f: !Font, r: !Rend, d: !Doc, li: int, nlines: int, colx: int, oy: int, safe_lh: int, scroll: int, scratch: &Buf >> _): void = let
  val step = doc_line_step(d, li)
in
  if step <= 0 then ()
  else let
    val st = doc_line_start(d, li)
    val en0 = if ilt(iadd(li, 1), nlines) then doc_line_start(d, iadd(li, 1)) else doc_len(d)
    val en = if igt(en0, st) andalso ieq(doc_byte(d, isub(en0, 1)), CHAR_LF) then isub(en0, 1) else en0
    val cols = doc_codepoints(d, st, en)
    val wc = doc_get_wrap(d)
    val yy = isub(iadd(oy, doc_line_y(d, li)), scroll)
    val rows = (if wc > 0 andalso igt(cols, wc) then idiv(iadd(cols, isub(wc, 1)), wc) else 1) : int
  in
    if rows <= 1 then draw_single_plain_row(f,r,d,st,en,colx,yy,scratch)
    else
      plain_rows_with_fuel(airlock_nat(MAX_REC_FUEL), f, r, d, st, en, colx, yy, safe_lh, wc, 0, rows, scratch)
  end
end

extern fun plain_lines_fuel_exhausted(f: !Font, r: !Rend, d: !Doc, li: int, li_end: int, nlines: int, colx: int, oy: int, safe_lh: int, scroll: int, scratch: &Buf >> _): void = "mac#anth_die_void"

fun plain_lines_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, r: !Rend, d: !Doc, li: int, li_end: int, nlines: int, colx: int, oy: int, safe_lh: int, scroll: int, scratch: &Buf >> _): void =
  if recfuel > 0 then (
    if ilt(li, li_end) then let
      val () = draw_plain_line(f, r, d, li, nlines, colx, oy, safe_lh, scroll, scratch)
    in
      plain_lines_with_fuel(recfuel - 1, f, r, d, iadd(li, 1), li_end, nlines, colx, oy, safe_lh, scroll, scratch)
    end else ()
  ) else plain_lines_fuel_exhausted(f, r, d, li, li_end, nlines, colx, oy, safe_lh, scroll, scratch)

fun draw_plain_doc(f: !Font, r: !Rend, d: !Doc, colx: int, oy: int, pw: int, ph: int, scroll: int, lh: int, scratch: &Buf >> _): void = let
  val nlines = doc_nlines(d)
  val safe_lh = if igt(lh, 0) then lh else 18
  val li_start = imax(0, isub(line_at_y_fast(d, scroll, safe_lh), 1))
  val li_end = imin(nlines, iadd(line_at_y_fast(d, iadd(scroll, ph), safe_lh), 2))
  val () = seen_int(pw)
in
  plain_lines_with_fuel(airlock_nat(MAX_REC_FUEL), f, r, d, li_start, li_end, nlines, colx, oy, safe_lh, scroll, scratch)
end

extern fun count_before_fuel_exhausted(d: !Doc, a: int, p: int, k0: int): int = "mac#anth_die_int"

fun count_before_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, a: int, p: int, k0: int): int =
  if recfuel > 0 then (
    if ige(p, a) then k0
    else count_before_with_fuel(recfuel - 1, d, a, iadd(p, 1), (if ieq(doc_byte(d, p), CHAR_LF) then iadd(k0, 1) else k0))
  ) else count_before_fuel_exhausted(d, a, p, k0)

fun count_before(d: !Doc, a: int, p: int, k0: int): int = count_before_with_fuel(airlock_nat(MAX_REC_FUEL), d, a, p, k0)

implement font_arrow_w(f, r) = let
  val s = "v"
  val w = font_width(f, r, c_str_ptr(s), 1)
in
  if igt(w, 0) then w else 8
end

implement arrow_pos_x(f, r, colx) = let
  val aw = font_arrow_w(f, r)
  val pad = imax(4, idiv(font_line_h(f), 4))
in
  isub(colx, iadd(aw, pad))
end

implement gutter_num_end_x(f, r, colx) = let
  val arr_x = arrow_pos_x(f, r, colx)
  val gap = imax(6, idiv(font_arrow_w(f, r), 2))
in
  isub(arr_x, gap)
end
