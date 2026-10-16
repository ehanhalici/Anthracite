fun draw_leaf_styled(f: !Font, r: !Rend, d: !Doc, i: int, k: NodeKind,
                     oy: int, ph: int, scroll: int, lh: int, colx: int,
                     scratch: &Buf >> _, pen_x: &int >> _, pen_line: &int >> _,
                     viewmode: ViewMode): void = let
  val flags = doc_node_flags(d, i)
  val is_read = is_view_read(viewmode)
  val skip = is_read andalso (is_kind(k, KMark) orelse is_kind(k, KLinkDest) orelse is_kind(k, KLinkTitle) orelse iand(flags, FL_READ_HIDDEN) != 0)
in
  if skip then ()
  else let
    val st0 = doc_node_start(d, i)
    val st = (if is_read andalso is_kind(k, KEscape) then iadd(st0, 1) else st0)
    val en = doc_node_end(d, i)
    val p_idx = doc_node_parent(d, i)
    val p_k = if ige(p_idx, 0) then doc_node_kind(d, p_idx) else KNone
  in
    if is_read andalso is_kind(p_k, KMath) then
      draw_leaf_math_inline(f, r, d, i, oy, ph, scroll, lh, colx, st, en, scratch, pen_x, pen_line)
    else
      draw_leaf_content(f, r, d, i, k, oy, ph, scroll, lh, colx, st, en, scratch, pen_x, pen_line)
  end
end

fun draw_container_box(r: !Rend, d: !Doc, i: int, k: NodeKind, colx: int, y: int, h: int, lh: int, pw: int): void =
  if is_kind(k, KQuote) then
    rend_rect(r, isub(colx, 8), y, 3, imax(h, lh), col_quote())
  else if is_kind(k, KCallout) then
    rend_rect(r, isub(colx, 8), y, 4, imax(h, lh), col_accent())
  else if is_kind(k, KCode) orelse is_kind(k, KMathBlock) then let
    val fl = doc_node_flags(d, i)
    val () = rend_rect(r, colx, y, column_w(pw), imax(h, lh), col_highbg())
  in
    if iand(fl, FL_ERROR) != 0 then rend_rect(r, colx, y, 3, imax(h, lh), col_danger()) else ()
  end else ()

fun draw_node_content(f: !Font, r: !Rend, d: !Doc, i: int, k: NodeKind, ox: int, oy: int, pw: int, ph: int, scroll: int,
                      lh: int, colx: int, y: int, h: int, vault: !Buf, c: &Cache >> _, scratch: &Buf >> _,
                      py: &int >> _, pa: &int >> _, pen_x: &int >> _, pen_line: &int >> _, viewmode: ViewMode): void =
  if is_heading(k) then
    draw_node_heading(f, r, d, i, k, oy, ph, scroll, lh, colx, y, viewmode, scratch, py, pa, pen_x, pen_line)
  else if is_kind(k, KHr) then (
    pen_line := ~1; pen_x := colx;
    rend_rect(r, colx, iadd(y, 4), column_w(pw), 2, col_line())
  )
  else if is_kind(k, KImage) then
    draw_node_image(r, d, i, pw, colx, y, h, vault, c, pen_x, pen_line)
  else if is_kind(k, KEmbed) then
    draw_node_embed(f, r, d, i, ox, oy, pw, ph, scroll, colx, y, h, lh, vault, c, scratch, pen_x, pen_line)
  else if is_kind(k, KMathb) andalso is_view_read(viewmode) then
    draw_node_mathb(f, r, d, i, colx, y, lh, pw, pen_x, pen_line)
  else if kind_is_leaf(k) then
    draw_leaf_styled(f, r, d, i, k, oy, ph, scroll, lh, colx, scratch, pen_x, pen_line, viewmode)
  else
    draw_container_box(r, d, i, k, colx, y, h, lh, pw)

fun draw_node(f: !Font, r: !Rend, d: !Doc, i: int, ox: int, oy: int, pw: int, ph: int, scroll: int, lh: int, vault: !Buf, c: &Cache >> _, scratch: &Buf >> _, py: &int >> _, pa: &int >> _, pen_x: &int >> _, pen_line: &int >> _, viewmode: ViewMode): void = let
  val k = doc_node_kind(d, i)
  val y = isub(iadd(oy, doc_node_y(d, i)), scroll)
  val h = doc_node_height(d, i)
  val colx = editor_colx(f, r, ox, pw)
  val p_idx = doc_node_parent(d, i)
  val p_k = if ige(p_idx, 0) then doc_node_kind(d, p_idx) else KNone
  val in_read = is_view_read(viewmode)
  val skip = is_on(doc_node_hidden(d, i)) orelse (in_read andalso (is_heading(p_k) orelse is_kind(p_k, KImage) orelse is_kind(p_k, KEmbed) orelse is_kind(p_k, KMathb)))
in
  if skip then ()
  else let
    val () = draw_arrow(f, r, d, i, k, colx, y)
  in
    draw_node_content(f, r, d, i, k, ox, oy, pw, ph, scroll, lh, colx, y, h, vault, c, scratch, py, pa, pen_x, pen_line, viewmode)
  end
end

extern fun draw_nodes_impl_fuel_exhausted(f: !Font, r: !Rend, d: !Doc, ox: int, oy: int, pw: int, ph: int, scroll: int, lh: int, vault: !Buf, c: &Cache >> _, scratch: &Buf >> _, i: int, py: &int >> _, pa: &int >> _, pen_x: &int >> _, pen_line: &int >> _, viewmode: ViewMode): void = "mac#anth_die_void"

fun draw_nodes_impl_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, r: !Rend, d: !Doc, ox: int, oy: int, pw: int, ph: int, scroll: int, lh: int, vault: !Buf, c: &Cache >> _, scratch: &Buf >> _, i: int, py: &int >> _, pa: &int >> _, pen_x: &int >> _, pen_line: &int >> _, viewmode: ViewMode): void =
  if recfuel > 0 then (
    if ige(i, doc_nnodes(d)) then ()
    else let
      val y = doc_node_y(d, i)
    in
      if igt(y, iadd(scroll, iadd(ph, 64))) then ()
      else let
        val () = draw_node(f, r, d, i, ox, oy, pw, ph, scroll, lh, vault, c, scratch, py, pa, pen_x, pen_line, viewmode)
      in
        draw_nodes_impl_with_fuel(recfuel - 1, f, r, d, ox, oy, pw, ph, scroll, lh, vault, c, scratch, iadd(i, 1), py, pa, pen_x, pen_line, viewmode)
      end
    end
  ) else draw_nodes_impl_fuel_exhausted(f, r, d, ox, oy, pw, ph, scroll, lh, vault, c, scratch, i, py, pa, pen_x, pen_line, viewmode)

fun draw_nodes_impl(f: !Font, r: !Rend, d: !Doc, ox: int, oy: int, pw: int, ph: int, scroll: int, lh: int, vault: !Buf, c: &Cache >> _, scratch: &Buf >> _, i: int, py: &int >> _, pa: &int >> _, pen_x: &int >> _, pen_line: &int >> _, viewmode: ViewMode): void = draw_nodes_impl_with_fuel(airlock_nat(MAX_REC_FUEL), f, r, d, ox, oy, pw, ph, scroll, lh, vault, c, scratch, i, py, pa, pen_x, pen_line, viewmode)

implement line_quote_prefix(d, ls, le) = let
  val p = skip_spaces(d, ls, le)
in
  if ilt(p, le) andalso ieq(doc_byte(d, p), CHAR_GT) then let
    val next_p = (if ilt(iadd(p, 1), le) andalso ieq(doc_byte(d, iadd(p, 1)), CHAR_SPACE) then iadd(p, 2) else iadd(p, 1))
  in
    isub(next_p, ls)
  end else 0
end

fun row_quote_prefix(d: !Doc, rst: int): int = let
  val line = doc_line_of(d, rst)
  val ls = doc_line_start(d, line)
  val le = if ilt(iadd(line, 1), doc_nlines(d)) then doc_line_start(d, iadd(line, 1)) else doc_len(d)
in
  if ieq(rst, ls) then line_quote_prefix(d, ls, le) else 0
end

fun caret_calc_adv(f: !Font, r: !Rend, d: !Doc, rst: int, ren: int, caret: int, scratch: &Buf >> _): int = let
  val scap = buf_cap(scratch)
  val rlen = doc_slice_buf(d, rst, ren, scratch, scap)
  val c_off = imax(0, isub(caret, rst))
in
  anth_ui_caret_adv(f, r, buf_ptr(scratch), rlen, c_off)
end

fun caret_calc_pos(d: !Doc, caret: int, row: &int >> _): @(int, int, int) = let
  val line = doc_line_of(d, caret)
  val ls = doc_line_start(d, line)
  val le = if ilt(iadd(line, 1), doc_nlines(d)) then doc_line_start(d, iadd(line, 1)) else doc_len(d)
  val wc = doc_get_wrap(d)
  val off_cps = doc_codepoints(d, ls, caret)
  val rw = (if wc > 0 then idiv(off_cps, wc) else 0) : int
  val () = row := rw
  val rst = (if wc > 0 then doc_advance_cps(d, ls, le, imul(rw, wc)) else ls) : int
  val ren = (if wc > 0 then doc_advance_cps(d, rst, le, wc) else le) : int
  val p_rst = iadd(rst, row_quote_prefix(d, rst))
in
  @(line, p_rst, imax(p_rst, ren))
end

fun caret_xy(f: !Font, r: !Rend, d: !Doc, colx: int, oy: int, scroll: int, lh: int, scratch: &Buf >> _, x: &int >> _, y: &int >> _): void =
 if doc_visual_active(d) then let val point=visual_caret_point(f,d,colx,oy,scroll,lh,scratch)
   val ()=x := point.x in y := point.y end else let
  val caret = doc_caret(d)
  var row: int = 0
  val @(line, p_rst, p_ren) = caret_calc_pos(d, caret, row)
  val base_x = row_base_pos(f, r, d, p_rst, p_ren, colx, scratch)
  val scap = buf_cap(scratch)
  val rlen = doc_slice_buf(d, p_rst, p_ren, scratch, scap)
  val adv = anth_ui_caret_adv(f, r, buf_ptr(scratch), rlen, isub(caret, p_rst))
  val yy = isub(iadd(oy, iadd(doc_line_y(d, line), imul(row, lh))), scroll)
  val () = x := iadd(base_x, adv)
  val () = seen_int(lh)
in
  y := yy
end

fun draw_sel_rect(r: !Rend, wa: int, wb: int, colx: int, sy: int, lh: int): void = let
  val xmin = imin(wa, wb)
  val xmax = imax(wa, wb)
  val sx = iadd(colx, xmin)
  val sw = imax(isub(xmax, xmin), 4)
in
  rend_rect(r, sx, sy, sw, lh, col_sel())
end

fun draw_sel_row(f: !Font, r: !Rend, d: !Doc, rst: int, ren: int, a: int, b: int, colx: int, sy: int, lh: int, scratch: &Buf >> _): void = let
  val pfx = row_quote_prefix(d, rst)
  val p_rst = iadd(rst, pfx)
  val p_ren = imax(p_rst, ren)
  val sa = imax(p_rst, a)
  val sb = imin(p_ren, b)
in
  if ilt(sa, sb) then let
    val base_x = row_base_pos(f, r, d, p_rst, p_ren, colx, scratch)
    val scap = buf_cap(scratch)
    val rlen = doc_slice_buf(d, p_rst, p_ren, scratch, scap)
    val at_eol = (if ige(b, p_ren) then 1 else 0) : int
    var rel_sx: int = 0
    var rel_sw: int = 0
    val () = anth_ui_sel_span(f, r, buf_ptr(scratch), rlen, isub(sa, p_rst), isub(sb, p_rst), at_eol, rel_sx, rel_sw)
    val sx = iadd(base_x, rel_sx)
    val sw = rel_sw
  in
    rend_rect(r, sx, sy, sw, lh, col_sel())
  end else ()
end

fun draw_sel_rows_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), f: !Font, r: !Rend, d: !Doc, ls: int, le: int,
  a: int, b: int, colx: int, base_sy: int, lh: int, wc: int, row: int, rows: int, scratch: &Buf >> _
): void =
  if recfuel > 0 then (
    if ige(row, rows) then ()
    else let
      val rst = (if wc > 0 then doc_advance_cps(d, ls, le, imul(row, wc)) else ls) : int
      val ren = (if wc > 0 then doc_advance_cps(d, rst, le, wc) else le) : int
      val sy = iadd(base_sy, imul(row, lh))
      val () = draw_sel_row(f, r, d, rst, ren, a, b, colx, sy, lh, scratch)
    in
      draw_sel_rows_with_fuel(recfuel - 1, f, r, d, ls, le, a, b, colx, base_sy, lh, wc, iadd(row, 1), rows, scratch)
    end
  ) else ()

fun draw_sel_line(f: !Font, r: !Rend, d: !Doc, ls: int, le: int, smin: int, smax: int, colx: int, oy: int, scroll: int, lh: int, scratch: &Buf >> _): void = let
  val a = imax(ls, smin)
  val b = imin(le, smax)
in
  if ilt(a, b) then let
    val line = doc_line_of(d, ls)
    val sy = isub(iadd(oy, doc_line_y(d, line)), scroll)
    val wc = doc_get_wrap(d)
    val cols = doc_codepoints(d, ls, le)
    val rows = (if wc > 0 andalso igt(cols, wc) then idiv(iadd(cols, isub(wc, 1)), wc) else 1) : int
  in
    if rows <= 1 then draw_sel_row(f, r, d, ls, le, a, b, colx, sy, lh, scratch)
    else draw_sel_rows_with_fuel(airlock_nat(MAX_REC_FUEL), f, r, d, ls, le, a, b, colx, sy, lh, wc, 0, rows, scratch)
  end else ()
end

