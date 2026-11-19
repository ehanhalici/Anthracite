fun convert_sub(d: !Doc, p: int, en: int, out: &Buf >> _): int =
  if ige(p, en) then p
  else if ieq(doc_byte(d, p), CHAR_LBRACE) then let
    val close = find_brace_close(d, iadd(p, 1), en)
    val () = convert_sub_run_with_fuel(airlock_nat(MAX_REC_FUEL), d, iadd(p, 1), close, out)
  in
    if ilt(close, en) then iadd(close, 1) else close
  end else math_script_scalar(d,p,en,out,false)

fun convert_frac(d: !Doc, p: int, en: int, out: &Buf >> _): int = let
  val p0 = math_skip_sp(d, p, en)
in
  if ilt(p0, en) andalso ieq(doc_byte(d, p0), CHAR_LBRACE) then let
    val c1 = find_brace_close(d, iadd(p0, 1), en)
    val p1 = math_skip_sp(d, (if ilt(c1, en) then iadd(c1, 1) else c1), en)
  in
    if ilt(p1, en) andalso ieq(doc_byte(d, p1), CHAR_LBRACE) then let
      val c2 = find_brace_close(d, iadd(p1, 1), en)
      val () = buffer_append_string(out, "(")
      val () = math_append_preview(d, iadd(p0, 1), c1, out)
      val () = buffer_append_string(out, ") / (")
      val () = math_append_preview(d, iadd(p1, 1), c2, out)
      val () = buffer_append_string(out, ")")
    in
      if ilt(c2, en) then iadd(c2, 1) else c2
    end else p0
  end else p0
end

fun convert_sqrt(d: !Doc, p: int, en: int, out: &Buf >> _): int = let
  val () = buffer_append_string(out, "√")
  val p0 = math_skip_sp(d, p, en)
in
  if ilt(p0, en) andalso ieq(doc_byte(d, p0), CHAR_LBRACE) then let
    val c = find_brace_close(d, iadd(p0, 1), en)
    val () = buffer_append_string(out, "(")
    val () = math_append_preview(d, iadd(p0, 1), c, out)
    val () = buffer_append_string(out, ")")
  in
    if ilt(c, en) then iadd(c, 1) else c
  end else p0
end

fun convert_named_cmd(d: !Doc, cmd_end: int, cbuf: !Buf, en: int, out: &Buf >> _): int =
  if ieq(c_strcmp(buffer_c_string(cbuf), "frac"), 0) then convert_frac(d, cmd_end, en, out)
  else if ieq(c_strcmp(buffer_c_string(cbuf), "sqrt"), 0) then convert_sqrt(d, cmd_end, en, out)
  else let
    val sym = math_cmd_lookup(buffer_c_string(cbuf))
    val () = if igt(c_strlen(sym), 0) then buffer_append_string(out, sym) else buffer_append_string(out, buffer_c_string(cbuf))
  in
    cmd_end
  end

fun convert_cmd(d: !Doc, p: int, en: int, out: &Buf >> _): int = let
  val cmd_end = scan_alpha_end(d, p, en)
in
  if igt(cmd_end, p) then let
    var cbuf = buf_make(CONVERT_CMD_CBUF_INITIAL_BYTES)
    val clen = doc_slice_buf(d, p, cmd_end, cbuf, 31)
    val () = buf_set_len(cbuf, clen)
    val next_p = convert_named_cmd(d, cmd_end, cbuf, en, out)
    val () = buf_free(cbuf)
  in
    next_p
  end else if ilt(p, en) then let
    val b = doc_byte(d, p)
    val () = if ieq(b, 44) then buffer_append_string(out, " ") else buf_push(out, b)
  in
    iadd(p, 1)
  end else p
end

fun math_append_preview_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, p: int, en: int, out: &Buf >> _
): void =
  if recursion_fuel_available(recfuel) then (
    if ige(p, en) then ()
    else let
      val b = doc_byte(d, p)
    in
      if ieq(b, 92) then
        math_append_preview_with_fuel(recfuel - 1, d, convert_cmd(d, iadd(p, 1), en, out), en, out)
      else if ieq(b, 94) then
        math_append_preview_with_fuel(recfuel - 1, d, convert_sup(d, iadd(p, 1), en, out), en, out)
      else if ieq(b, 95) then
        math_append_preview_with_fuel(recfuel - 1, d, convert_sub(d, iadd(p, 1), en, out), en, out)
      else if ieq(b, 123) orelse ieq(b, 125) then
        math_append_preview_with_fuel(recfuel - 1, d, iadd(p, 1), en, out)
      else (buf_push(out, b); math_append_preview_with_fuel(recfuel - 1, d, iadd(p, 1), en, out))
    end
  ) else ()

implement math_append_preview(d, st, en, out) =
  math_append_preview_with_fuel(airlock_nat(MAX_REC_FUEL), d, st, en, out)

fun draw_node_mathb(
  f: !Font, r: !Rend, d: !Doc, i: int, colx: int, y: int, lh: int, colw: int,
  pen_x: &int >> _, pen_line: &int >> _
): void = let
  val () = pen_line := ~1
  val () = pen_x := colx
  val @(st, en) = mathb_slice_bounds(d, i)
  val mb = math_layout_measure(f, r, d, st, en, 1)
  val tw = mb.w
  val bw = imin(colw, iadd(tw, 32))
  val bx = iadd(colx, imax(0, idiv(isub(colw, bw), 2)))
  val tx = iadd(bx, idiv(isub(bw, tw), 2))
  val bh = imax(iadd(lh, 8), isub(doc_node_height(d, i), 4))
  val by = isub(y, 4)
  val base = iadd(by, iadd(idiv(isub(bh, iadd(mb.a, mb.d)), 2), mb.a))
  val fl = doc_node_flags(d, i)
  val () = rend_rect(r, bx, by, bw, bh, col_side())
  val () = ui_draw_border(r, bx, by, bw, bh, 1, (if iand(fl, FL_ERROR) != 0 then col_danger() else col_line()))
  val () = math_layout_paint(f, r, d, st, en, 1, tx, base)
in
end

fun draw_leaf_effects(r: !Rend, x0: int, yy: int, tw: int, lh: int, style: int): void =
  if igt(tw, 0) then let
    val () = if iand(style, STYLE_HIGH) != 0 then rend_rect(r, x0, yy, tw, lh, col_highbg()) else ()
    val () = if iand(style, STYLE_LINK) != 0 then rend_rect(r, x0, iadd(yy, isub(lh, 2)), tw, 1, col_link()) else ()
    val () = if iand(style, STYLE_STRIKE) != 0 then rend_rect(r, x0, iadd(yy, idiv(lh, 2)), tw, 1, col_muted()) else ()
    val () = if iand(style, STYLE_ERROR) != 0 then rend_rect(r, x0, iadd(yy, isub(lh, 2)), tw, 2, col_danger()) else ()
  in
  end else ()

fun draw_math_text(
  f: !Font, r: !Rend, d: !Doc, st: int, en: int, x0: int, yy: int, oy: int, ph: int, lh: int
): void =
  if ilt(iadd(yy, lh), oy) orelse igt(yy, iadd(oy, ph)) then ()
  else math_layout_paint(f, r, d, st, en, 0, x0, iadd(yy, font_asc(f)))

fun draw_leaf_math_inline(
  f: !Font, r: !Rend, d: !Doc, i: int, oy: int, ph: int, scroll: int,
  lh: int, colx: int, st: int, en: int, scratch: &Buf >> _,
  pen_x: &int >> _, pen_line: &int >> _
): void = let
  val mb = math_layout_measure(f, r, d, st, en, 0)
  val line = doc_line_of(d, st)
  val pl_line = pen_unpack_line(pen_line)
  val cur_row = (if ieq(line, pl_line) then pen_unpack_row(pen_line) else 0)
  val pt = visual_offset_point(f, d, st, colx, oy, scroll, scratch)
  val vis = doc_visual_active(d)
  val yy = if vis then pt.y else isub(iadd(oy, iadd(doc_line_y(d, line), imul(cur_row, lh))), scroll)
  val x0 = (if vis then pt.x else if ine(line, pl_line) then colx else pen_x) : int
  val tw = mb.w
  val () = draw_math_text(f, r, d, st, en, x0, yy, oy, ph, lh)
  val () = pen_x := iadd(x0, tw)
  val () = pen_line := pen_pack(line, cur_row)
  val () = draw_leaf_effects(r, x0, yy, tw, lh, ast_style(d, i))
in
end

fun is_bullet_mark(d: !Doc, i: int): bool = let
  val k = doc_node_kind(d, i)
  val p_idx = doc_node_parent(d, i)
  val p_k = if ige(p_idx, 0) then doc_node_kind(d, p_idx) else KNone
in
  is_kind(k, KMark) andalso is_kind(p_k, KLi) andalso ilt(doc_find_child(d, p_idx, KTask), 0)
end

fun is_table_pipe_mark(d: !Doc, i: int): bool = let
  val k = doc_node_kind(d, i)
  val p_idx = doc_node_parent(d, i)
  val p_k = if ige(p_idx, 0) then doc_node_kind(d, p_idx) else KNone
in
  is_kind(k, KMark) andalso is_kind(p_k, KTableRow)
end

fun leaf_color_for(d: !Doc, i: int, k: NodeKind, style: int, is_read: bool): uint =
  if is_read andalso is_bullet_mark(d, i) then col_task()
  else if is_kind(k, KMark) then col_muted()
  else if is_kind(k, KTag) then col_tag()
  else if iand(style, STYLE_LINK) != 0 then col_link()
  else if iand(style, STYLE_HIGH) != 0 then col_hightxt()
  else if iand(style, STYLE_BOLD) != 0 then col_white()
  else if iand(style, STYLE_ITALIC) != 0 then col_task()
  else if iand(style, STYLE_STRIKE) != 0 then col_muted()
  else if iand(style, STYLE_MATH) != 0 then col_math()
  else if iand(style, STYLE_CODE) != 0 then col_code()
  else if iand(style, STYLE_HEADING) != 0 then col_heading()
  else kind_col(k)

fun draw_bullet_fallback(
  f: !Font, r: !Rend, d: !Doc, st: int, oy: int, ph: int, scroll: int,
  lh: int, colx: int, col: uint, scratch: &Buf >> _, pen_x: &int >> _, pen_line: &int >> _
): int = let
  val line = doc_line_of(d, st)
  val pl_line = pen_unpack_line(pen_line)
  val cur_row = if ieq(line, pl_line) then pen_unpack_row(pen_line) else 0
  val yy = isub(iadd(oy, iadd(doc_line_y(d, line), imul(cur_row, lh))), scroll)
  val x0 = if ine(line, pl_line) then colx else pen_x
  val () = buffer_clear(scratch)
  val () = buffer_append_string(scratch, "• ")
  val slen = buf_len(scratch)
  val tw = font_width_buf(f, r, scratch, slen)
  val () = if ilt(iadd(yy, lh), oy) orelse igt(yy, iadd(oy, ph)) then ()
    else seen_int(font_draw_buf(f, r, x0, yy, scratch, slen, col))
  val () = pen_x := iadd(x0, tw)
  val () = pen_line := pen_pack(line, cur_row)
in
  tw
end

fun draw_leaf_content(f: !Font, r: !Rend, d: !Doc, i: int, k: NodeKind,
                      oy: int, ph: int, scroll: int, lh: int, colx: int,
                      st: int, en: int, scratch: &Buf >> _, pen_x: &int >> _, pen_line: &int >> _,
                      is_read: bool): void = let
  val style = ast_style(d, i)
  val col = leaf_color_for(d, i, k, style, is_read)
  val line = doc_line_of(d, st)
  val pl_line = pen_unpack_line(pen_line)
  val cur_row = (if ieq(line, pl_line) then pen_unpack_row(pen_line) else 0)
  val yy = isub(iadd(oy, iadd(doc_line_y(d, line), imul(cur_row, lh))), scroll)
  val x0 = (if ine(line, pl_line) then colx else pen_x) : int
  val () = if doc_visual_active(d) then visual_leaf_background(f, r, d, st, en, colx, oy, scroll, lh, ph, style, scratch) else ()
  val tw = if not(doc_visual_active(d)) andalso is_read andalso is_bullet_mark(d, i)
    then draw_bullet_fallback(f, r, d, st, oy, ph, scroll, lh, colx, col, scratch, pen_x, pen_line)
    else draw_view_slice(f, r, d, st, en, colx, oy, scroll, lh, ph, col, scratch, pen_x, pen_line)
in
  if doc_visual_active(d) then visual_leaf_rules(f, r, d, st, en, colx, oy, scroll, lh, ph, style, scratch)
  else draw_leaf_effects(r, x0, yy, tw, lh, style)
end
