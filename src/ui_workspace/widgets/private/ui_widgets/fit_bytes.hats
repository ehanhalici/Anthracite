extern fun fit_bytes_fuel_exhausted(f: !Font, r: !Rend, p: ptr, n: int, max_w: int, i: int, last_fit: int): int = "mac#anth_die_int"

fun fit_bytes_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, r: !Rend, p: ptr, n: int, max_w: int, i: int, last_fit: int): int =
  if recursion_fuel_available(recfuel) then (
    if ilt(i, n) then let
      val next_i = fit_next_index(p, n, i)
      val w = font_width(f, r, p, next_i)
    in
      if ile(w, max_w) then fit_bytes_with_fuel(recfuel - 1, f, r, p, n, max_w, next_i, next_i)
      else last_fit
    end else last_fit
  ) else fit_bytes_fuel_exhausted(f, r, p, n, max_w, i, last_fit)

fun fit_str_bytes(f: !Font, r: !Rend, p: ptr, n: int, max_w: int): int =
  fit_bytes_with_fuel(airlock_nat(MAX_REC_FUEL), f, r, p, n, max_w, 0, 0)


fun ui_cell_bg(r: !Rend, x: int, y: int, w: int, h: int, is_selected: Toggle, is_hover: Toggle): void =
  if is_on(is_selected) then let
    val () = rend_rect(r, x, y, w, h, col_side())
    val () = rend_rect(r, x, y, 2, h, col_accent())
  in
  end else if is_on(is_hover) then let
    val () = rend_rect(r, x, y, w, h, col_bar())
  in
  end else ()

fun ui_cell_expander(f: !Font, r: !Rend, x_cur: &int >> _, y: int, h: int, is_expandable: Toggle, is_expanded: Toggle, is_hover: Toggle): void =
  if is_on(is_expandable) then let
    val () = ui_expander(f, r, x_cur, iadd(y, idiv(isub(h, 8), 2)), is_expanded, is_hover)
    val () = x_cur := iadd(x_cur, 14)
  in
  end else let
    val () = x_cur := iadd(x_cur, 6)
  in
  end

fun ui_cell_icon(f: !Font, r: !Rend, x_cur: &int >> _, y: int, h: int, icon: int, is_selected: Toggle): void =
  if igt(icon, 0) then let
    val icol = if is_on(is_selected) then col_accent() else col_muted()
    val () = ui_draw_icon(f, r, icon, x_cur, iadd(y, idiv(isub(h, 12), 2)), 12, icol)
    val () = x_cur := iadd(x_cur, 16)
  in
  end else ()

fun ui_cell_label(f: !Font, r: !Rend, x: int, w: int, x_cur: int, ty: int, lcol: uint, label: string, vlen: int, vw: int): void = let
  val llen = c_strlen(label)
  val max_label_w = imax(0, isub(iadd(x, w), iadd(x_cur, if igt(vlen, 0) then iadd(vw, 12) else 6)))
  val fit_n = fit_str_bytes(f, r, c_str_ptr(label), llen, max_label_w)
  val () = seen_int(if igt(fit_n, 0) then font_draw(f, r, x_cur, ty, c_str_ptr(label), fit_n, lcol) else 0)
in
end

fun ui_cell_value(f: !Font, r: !Rend, x: int, w: int, ty: int, value_text: string, vlen: int, vw: int): void =
  if igt(vlen, 0) then let
    val vx = isub(iadd(x, w), iadd(vw, 10))
    val () = draw_s(f, r, vx, ty, value_text, col_muted())
  in
  end else ()

extern fun draw_cell_guides_fuel_exhausted(r: !Rend, x: int, y: int, h: int, d: int, depth: int): void = "mac#anth_die_void"

fun draw_cell_guides_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), r: !Rend, x: int, y: int, h: int, d: int, depth: int
): void =
  if recursion_fuel_available(recfuel) then (
    if ilt(d, depth) then let
      val gx = iadd(x, iadd(imul(d, 14), 7))
      val () = rend_rect(r, gx, y, 1, h, col_line())
    in
      draw_cell_guides_with_fuel(recfuel - 1, r, x, y, h, iadd(d, 1), depth)
    end else ()
  ) else draw_cell_guides_fuel_exhausted(r, x, y, h, d, depth)

fun draw_cell_guides(r: !Rend, x: int, y: int, h: int, depth: int): void =
  if igt(depth, 0) then draw_cell_guides_with_fuel(airlock_nat(MAX_REC_FUEL), r, x, y, h, 0, depth) else ()

implement ui_cell(f, r, x, y, w, h, depth, is_expandable, is_expanded, icon, label, value_text, is_selected, is_hover) = let
  val () = ui_cell_bg(r, x, y, w, h, is_selected, is_hover)
  val () = draw_cell_guides(r, x, y, h, depth)
  val x_indent = iadd(x, imul(depth, 14))
  val ty = iadd(y, idiv(isub(h, font_line_h(f)), 2))
  var x_cur: int = x_indent
  val () = ui_cell_expander(f, r, x_cur, y, h, is_expandable, is_expanded, is_hover)
  val () = ui_cell_icon(f, r, x_cur, y, h, icon, is_selected)
  val lcol = if is_on(is_selected) then col_white() else col_text()
  val vlen = c_strlen(value_text)
  val vw = if igt(vlen, 0) then font_width(f, r, c_str_ptr(value_text), vlen) else 0
  val () = ui_cell_label(f, r, x, w, x_cur, ty, lcol, label, vlen, vw)
  val () = ui_cell_value(f, r, x, w, ty, value_text, vlen, vw)
in
end


fun ui_loading_track(r: !Rend, mx: int, my: int, mw: int, progress_pct: int): void = let
  val track_x = iadd(mx, LOADING_MARGIN)
  val track_y = iadd(my, LOADING_TRACK_Y_OFFSET)
  val track_w = isub(mw, imul(LOADING_MARGIN, 2))
  val () = rend_rect(r, track_x, track_y, track_w, LOADING_TRACK_HEIGHT, col_bar())
  val () = ui_draw_border(r, track_x, track_y, track_w, LOADING_TRACK_HEIGHT, 1, col_line())
  val clamped = imin(100, imax(0, progress_pct))
  val fill_w = idiv(imul(track_w, clamped), 100)
  val () = if igt(fill_w, 0) then rend_rect(r, track_x, track_y, fill_w, LOADING_TRACK_HEIGHT, col_accent()) else ()
in
end

implement ui_loading_overlay(f, r, w, h, progress_pct, title, status_msg) = let
  val () = rend_rect(r, 0, 0, w, h, col_overlay())
  val mw = LOADING_MODAL_WIDTH
  val mh = LOADING_MODAL_HEIGHT
  val mx = idiv(isub(w, mw), 2)
  val my = idiv(isub(h, mh), 2)
  val () = ui_draw_shadow(r, mx, my, mw, mh, 8)
  val () = rend_rect(r, mx, my, mw, mh, col_bg())
  val () = ui_draw_border(r, mx, my, mw, mh, 1, col_line())
  val () = draw_s(f, r, iadd(mx, LOADING_MARGIN), iadd(my, LOADING_MARGIN), title, col_heading())
  val () = ui_loading_track(r, mx, my, mw, progress_pct)
  val () = draw_s(f, r, iadd(mx, LOADING_MARGIN), iadd(my, LOADING_STATUS_Y_OFFSET), status_msg, col_muted())
in
end

macdef CODE_GUTTER_WIDTH = 44
macdef CODE_BP_DOT_SIZE = 8

fun format_line_num(n: int, b: &Buf >> Buf): void = let
  val () = buffer_clear(b)
  val s0 = if ilt(n, 10) then "   " else if ilt(n, 100) then "  " else if ilt(n, 1000) then " " else ""
  val () = buffer_append_string(b, s0)
  val () = buffer_append_integer(b, if igt(n, 0) then n else 0)
in
end


fun code_breakpoint_dot(r: !Rend, x: int, y: int, h: int, has_bp: Toggle): void =
  if is_on(has_bp) then let
    val dot_sz = CODE_BP_DOT_SIZE
    val dot_y = iadd(y, idiv(isub(h, dot_sz), 2))
    val () = rend_rect(r, iadd(x, 6), dot_y, dot_sz, dot_sz, col_danger())
  in
  end else ()

fun code_draw_line_num(f: !Font, r: !Rend, x: int, y: int, h: int, gutter_w: int, line_num: int): void = let
  var num_b = buf_make(CODE_DRAW_LINE_NUM_NUM_B_INITIAL_BYTES)
  val () = format_line_num(line_num, num_b)
  val num_len = buf_len(num_b)
  val num_w = font_width_buf(f, r, num_b, num_len)
  val ty = iadd(y, idiv(isub(h, font_line_h(f)), 2))
  val num_x = isub(iadd(x, isub(gutter_w, 6)), num_w)
  val () = seen_int(font_draw_buf(f, r, num_x, ty, num_b, num_len, col_muted()))
  val () = buf_free(num_b)
in
end

implement ui_code_slice(f, r, x, y, w, h, line_num, code_text, is_active, has_bp, is_hover) = let
  val () =
    if is_on(is_active) then rend_rect(r, x, y, w, h, col_side())
    else if is_on(is_hover) then rend_rect(r, x, y, w, h, col_bar())
    else ()
  val gutter_w = CODE_GUTTER_WIDTH
  val () = rend_rect(r, iadd(x, gutter_w), y, 1, h, col_line())
  val () = code_breakpoint_dot(r, x, y, h, has_bp)
  val () = code_draw_line_num(f, r, x, y, h, gutter_w, line_num)
  val ty = iadd(y, idiv(isub(h, font_line_h(f)), 2))
  val tcol = if is_on(is_active) then col_white() else col_text()
  val () = draw_s(f, r, iadd(x, iadd(gutter_w, 8)), ty, code_text, tcol)
in
end

implement ui_error_label(f, r, x, y, text) =
  draw_s(f, r, x, y, text, col_danger())

implement ui_help_label(f, r, x, y, text) =
  draw_s(f, r, x, y, text, col_muted())
