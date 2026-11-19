implement ui_button(f, r, x, y, w, h, text, is_hover, is_active) = let
  val bg =
    if is_on(is_active) then col_accent()
    else if is_on(is_hover) then col_surface_hi()
    else col_surface()
  val border =
    if is_on(is_active) then col_accent_hi()
    else col_line()
  val text_col =
    if is_on(is_active) then col_white()
    else if is_on(is_hover) then col_heading()
    else col_text()
  val () = rend_rrect_ex(r, x, y, w, h, 6, 6, 6, 6, bg, bg, 1, border, 1)
  val () = ui_draw_fitted_text(f, r, x, y, w, h, 8, 8, On, text, text_col)
in
end

implement ui_hover_label(f, r, x, y, w, h, text, is_hover) = let
  val () = if is_on(is_hover) then rend_rrect(r, x, y, w, h, 5, col_surface()) else ()
  val tcol = if is_on(is_hover) then col_heading() else col_text()
in
  ui_draw_fitted_text(f, r, x, y, w, h, 8, 8, Off, text, tcol)
end

implement ui_expander(f, r, x, y, is_expanded, is_hover) = let
  val acol = if is_on(is_hover) then col_text() else col_muted()
  val () =
    if is_on(is_expanded) then ui_draw_icon(f, r, UI_ICON_DOWN_ARROW, x, y, 8, acol)
    else ui_draw_icon(f, r, UI_ICON_RIGHT_ARROW, x, y, 8, acol)
in
end

fun scroll_thumb_draw_v(
  r: !Rend, x: int, y: int, w: int, thumb_off: int, thumb_len: int,
  thumb_col: uint, wide: Toggle
): void = let
  val tw = if is_on(wide) then imin(w, UI_SCROLLBAR_DRAW_WIDTH) else imin(w, UI_SCROLLBAR_IDLE_WIDTH)
  val tx = isub(iadd(x, w), iadd(tw, 2))
  val rad = imax(1, idiv(tw, 2))
in
  rend_rrect(r, tx, iadd(y, thumb_off), tw, thumb_len, rad, thumb_col)
end

implement ui_scroll_bar(r, x, y, w, h, is_vert, total_len, visible_len, scroll_pos, is_hover, is_dragging) = let
  val active = is_on(is_hover) orelse is_on(is_dragging)
  val () = if active then rend_rrect(r, x, y, w, h, 3, col_press_overlay()) else ()
  val () = if igt(total_len, visible_len) andalso igt(visible_len, 0) then let
    val travel = if is_vertical(is_vert) then h else w
    val thumb_len = imax(SCROLLBAR_MIN_THUMB, idiv(imul(travel, visible_len), total_len))
    val max_scroll = isub(total_len, visible_len)
    val max_travel = imax(0, isub(travel, thumb_len))
    val thumb_off = idiv(imul(imax(0, imin(scroll_pos, max_scroll)), max_travel), max_scroll)
    val thumb_col =
      if is_on(is_dragging) then col_accent()
      else if is_on(is_hover) then col_muted()
      else col_scroll_thumb()
    val hth = imax(2, isub(h, 2))
  in
    if is_vertical(is_vert) then scroll_thumb_draw_v(r, x, y, w, thumb_off, thumb_len, thumb_col, toggle_of(active))
    else rend_rrect(r, iadd(x, thumb_off), iadd(y, 1), thumb_len, hth, imax(1, idiv(hth, 2)), thumb_col)
  end else ()
in
end


fun line_edit_selection(f: !Font, r: !Rend, x: int, y: int, h: int, pad_l: int, b: !Buf, cursor: int, mark: int, n: int): void = let
  val sel_st = imin(cursor, mark)
  val sel_en = imax(cursor, mark)
  val x_st = if igt(sel_st, 0) then font_width_buf(f, r, b, sel_st) else 0
  val x_en = font_width_buf(f, r, b, imin(sel_en, n))
  val sel_w = isub(x_en, x_st)
in
  rend_rect(r, iadd(iadd(x, pad_l), x_st), iadd(y, 3), sel_w, imax(1, isub(h, 6)), col_sel())
end

fun line_edit_caret(f: !Font, r: !Rend, x: int, y: int, h: int, pad_l: int, b: !Buf, cursor: int, n: int): void = let
  val cur_clamped = imin(cursor, n)
  val cur_x_off = if igt(cur_clamped, 0) then font_width_buf(f, r, b, cur_clamped) else 0
  val cx = iadd(iadd(x, pad_l), cur_x_off)
in
  rend_rect(r, cx, iadd(y, 5), 2, imax(2, isub(h, 10)), col_caret())
end

fun line_edit_draw_box(
  f: !Font, r: !Rend, x: int, y: int, w: int, h: int, pad_l: int,
  b: !Buf, cursor: int, mark: int, is_focused: Toggle, placeholder: string
): void = let
  val n = buf_len(b)
  val ty = iadd(y, idiv(isub(h, font_line_h(f)), 2))
  val () = rend_clip_push(r, iadd(x, pad_l), iadd(y, 2), imax(1, isub(w, iadd(pad_l, 6))), imax(1, isub(h, 4)))
  val () = if ieq(n, 0) andalso is_off(is_focused) then
    draw_s(f, r, iadd(x, pad_l), ty, placeholder, col_muted())
  else let
    val () = if ine(mark, cursor) andalso igt(n, 0) then
      line_edit_selection(f, r, x, y, h, pad_l, b, cursor, mark, n) else ()
    val () = seen_int(if igt(n, 0) then font_draw_buf(f, r, iadd(x, pad_l), ty, b, n, col_text()) else 0)
  in
    if is_on(is_focused) then line_edit_caret(f, r, x, y, h, pad_l, b, cursor, n) else ()
  end
in
  rend_clip_pop(r)
end

implement ui_line_edit_draw(f, r, x, y, w, h, b, cursor, mark, is_focused, placeholder) = let
  val border = if is_on(is_focused) then col_accent() else col_line()
  val () = rend_rrect_ex(r, x, y, w, h, 6, 6, 6, 6, col_bg(), col_bg(), 1, border, 1)
in
  line_edit_draw_box(f, r, x, y, w, h, 8, b, cursor, mark, is_focused, placeholder)
end

implement ui_search_input_draw(f, r, x, y, w, h, b, cursor, mark, is_focused, placeholder) = let
  val border = if is_on(is_focused) then col_accent() else col_line()
  val () = rend_rrect_ex(r, x, y, w, h, 7, 7, 7, 7, col_bg(), col_bg(), 1, border, 1)
  val ic = if is_on(is_focused) then col_accent_hi() else col_muted()
  val iy = iadd(y, idiv(isub(h, 12), 2))
  val () = ui_draw_icon(f, r, UI_ICON_SEARCH, iadd(x, 10), iy, 12, ic)
in
  line_edit_draw_box(f, r, x, y, w, h, 28, b, cursor, mark, is_focused, placeholder)
end

implement ui_pane_begin(r, x, y, w, h, bg_col) = let
  val () = ui_draw_shadow(r, x, y, w, h, 8)
  val () = rend_rrect_ex(r, x, y, w, h, 8, 8, 8, 8, bg_col, bg_col, 1, col_line(), 1)
in
end

implement ui_pane_draw_header(f, r, x, y, w, title, has_close) = let
  val bar_h = PANE_HEADER_HEIGHT
  val () = rend_rect(r, x, y, w, bar_h, col_bar())
  val () = rend_rect(r, x, iadd(y, isub(bar_h, 1)), w, 1, col_line())
  val pr = if is_on(has_close) then 26 else 10
  val () = ui_draw_fitted_text(f, r, x, y, w, bar_h, 10, pr, Off, title, col_heading())
  val ty = iadd(y, idiv(isub(bar_h, font_line_h(f)), 2))
  val () = if is_on(has_close) then let
    val () = draw_s(f, r, isub(iadd(x, w), 18), ty, "x", col_muted())
  in
  end else ()
in
end


fun menu_bar_button_bg(r: !Rend, x: int, y: int, w: int, h: int, is_active: Toggle, is_hover: Toggle): void =
  if is_on(is_active) then let
    val () = rend_rect(r, x, y, w, h, col_side())
    val () = rend_rect(r, x, isub(iadd(y, h), 2), w, 2, col_accent())
  in
  end else if is_on(is_hover) then let
    val () = rend_rect(r, x, y, w, h, col_bar())
    val () = rend_rect(r, x, isub(iadd(y, h), 2), w, 2, col_line())
  in
  end else ()

implement ui_menu_bar_button(f, r, x, y, w, h, text, is_active, is_hover) = let
  val () = menu_bar_button_bg(r, x, y, w, h, is_active, is_hover)
  val tcol =
    if is_on(is_active) then col_white()
    else if is_on(is_hover) then col_heading()
    else col_text()
in
  ui_draw_fitted_text(f, r, x, y, w, h, 8, 8, On, text, tcol)
end


fun icon_button_frame(r: !Rend, x: int, y: int, w: int, h: int, is_active: Toggle, is_hover: Toggle): void = let
  val bg =
    if is_on(is_active) then col_side()
    else if is_on(is_hover) then col_bar()
    else col_bg()
  val border =
    if is_on(is_active) then col_accent()
    else if is_on(is_hover) then col_line()
    else col_bg()
  val () = rend_rect(r, x, y, w, h, bg)
  val () = if is_on(is_active) orelse is_on(is_hover) then ui_draw_border(r, x, y, w, h, 1, border) else ()
in
end

implement ui_icon_button(f, r, icon, text, x, y, w, h, is_active, is_hover) = let
  val () = icon_button_frame(r, x, y, w, h, is_active, is_hover)
  val icon_col =
    if is_on(is_active) then col_accent_hi()
    else if is_on(is_hover) then col_heading()
    else col_muted()
  val text_col =
    if is_on(is_active) then col_white()
    else if is_on(is_hover) then col_heading()
    else col_text()
  val () = if igt(icon, 0) then ui_draw_icon(f, r, icon, iadd(x, 8), iadd(y, idiv(isub(h, 12), 2)), 12, icon_col) else ()
  val pl = if igt(icon, 0) then 26 else 8
in
  ui_draw_fitted_text(f, r, x, y, w, h, pl, 8, Off, text, text_col)
end

implement ui_icon_only_button(f, r, icon, x, y, sz, is_active, is_hover) = let
  val () =
    if is_on(is_active) then rend_rrect(r, x, y, sz, sz, 6, col_accent_soft())
    else if is_on(is_hover) then rend_rrect(r, x, y, sz, sz, 6, col_surface())
    else ()
  val icol =
    if is_on(is_active) then col_accent_hi()
    else if is_on(is_hover) then col_heading()
    else col_muted()
  val isz = imax(10, idiv(sz, 2))
  val ix = iadd(x, idiv(isub(sz, isz), 2))
  val iy = iadd(y, idiv(isub(sz, isz), 2))
in
  ui_draw_icon(f, r, icon, ix, iy, isz, icol)
end

fun draw_seg_half(
  f: !Font, r: !Rend, sx: int, sy: int, sw: int, sh: int,
  lbl: string, is_act: bool, is_hov: bool
): void = let
  val () =
    if is_act then rend_rrect(r, sx, sy, sw, sh, 5, col_surface_hi())
    else if is_hov then rend_rrect(r, sx, sy, sw, sh, 5, col_tab_hover())
    else ()
  val tc = if is_act then col_heading() else if is_hov then col_text() else col_muted()
in
  ui_draw_fitted_text(f, r, sx, sy, sw, sh, 6, 6, On, lbl, tc)
end

implement ui_segmented_pair(f, r, x, y, w, h, left_lbl, right_lbl, right_active, hover_idx) = let
  val () = rend_rrect_ex(r, x, y, w, h, 7, 7, 7, 7, col_bg(), col_bg(), 1, col_line(), 1)
  val hw = imax(1, idiv(isub(w, 6), 2))
  val sh = imax(1, isub(h, 6))
  val lx = iadd(x, 3)
  val rx = iadd(lx, hw)
  val sy = iadd(y, 3)
  val ra = is_on(right_active)
  val () = draw_seg_half(f, r, lx, sy, hw, sh, left_lbl, not(ra), ieq(hover_idx, 0))
in
  draw_seg_half(f, r, rx, sy, imax(1, isub(isub(w, 6), hw)), sh, right_lbl, ra, ieq(hover_idx, 1))
end


fun fit_next_index(p: ptr, n: int, i: int): int = let
  val b = mem_byte(p, n, i)
  val step = if ilt(b, 128) then 1 else if ilt(b, 224) then 2 else if ilt(b, 240) then 3 else 4
in
  imin(n, iadd(i, step))
end

