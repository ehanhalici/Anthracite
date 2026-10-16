implement ui_button(f, r, x, y, w, h, text, is_hover, is_active) = let
  val bg =
    if is_on(is_active) then col_menu()
    else if is_on(is_hover) then col_side()
    else col_bar()
  val border =
    if is_on(is_active) orelse is_on(is_hover) then col_accent()
    else col_line()
  val text_col =
    if is_on(is_active) then col_white()
    else if is_on(is_hover) then col_heading()
    else col_text()
  val () = rend_rect(r, x, y, w, h, bg)
  val () = ui_draw_border(r, x, y, w, h, 1, border)
  val tw = font_width(f, r, c_str_ptr(text), c_strlen(text))
  val tx = iadd(x, idiv(isub(w, tw), 2))
  val ty = iadd(y, idiv(isub(h, font_line_h(f)), 2))
  val () = draw_s(f, r, tx, ty, text, text_col)
in
end

implement ui_hover_label(f, r, x, y, w, h, text, is_hover) = let
  val bg = if is_on(is_hover) then col_side() else col_bg()
  val () = if is_on(is_hover) then (
    rend_rect(r, x, y, w, h, bg);
    ui_draw_border(r, x, y, w, h, 1, col_line())
  ) else ()
  val ty = iadd(y, idiv(isub(h, font_line_h(f)), 2))
  val tcol = if is_on(is_hover) then col_heading() else col_text()
  val () = rend_scissor(r, x, y, w, h)
  val () = draw_s(f, r, iadd(x, 6), ty, text, tcol)
in
  rend_scissor_off(r)
end

implement ui_expander(f, r, x, y, is_expanded, is_hover) = let
  val acol = if is_on(is_hover) then col_white() else col_accent()
  val () =
    if is_on(is_expanded) then ui_draw_icon(f, r, UI_ICON_DOWN_ARROW, x, y, 8, acol)
    else ui_draw_icon(f, r, UI_ICON_RIGHT_ARROW, x, y, 8, acol)
in
end

implement ui_scroll_bar(r, x, y, w, h, is_vert, total_len, visible_len, scroll_pos, is_hover, is_dragging) = let
  val () = rend_rect(r, x, y, w, h, col_bar())
  val () = if igt(total_len, visible_len) andalso igt(visible_len, 0) then let
    val travel = if is_vertical(is_vert) then h else w
    val min_thumb = SCROLLBAR_MIN_THUMB
    val thumb_len = imax(min_thumb, idiv(imul(travel, visible_len), total_len))
    val max_scroll = isub(total_len, visible_len)
    val max_travel = isub(travel, thumb_len)
    val thumb_off = idiv(imul(imax(0, imin(scroll_pos, max_scroll)), max_travel), max_scroll)
    val thumb_col =
      if is_on(is_dragging) then col_accent()
      else if is_on(is_hover) then col_muted()
      else col_line()
    val () =
      if is_vertical(is_vert) then rend_rect(r, iadd(x, 1), iadd(y, thumb_off), isub(w, 2), thumb_len, thumb_col)
      else rend_rect(r, iadd(x, thumb_off), iadd(y, 1), thumb_len, isub(h, 2), thumb_col)
  in
  end else ()
in
end


fun line_edit_selection(f: !Font, r: !Rend, x: int, y: int, h: int, b: !Buf, cursor: int, mark: int, n: int): void = let
  val sel_st = imin(cursor, mark)
  val sel_en = imax(cursor, mark)
  val x_st = if igt(sel_st, 0) then font_width_buf(f, r, b, sel_st) else 0
  val x_en = font_width_buf(f, r, b, imin(sel_en, n))
  val sel_w = isub(x_en, x_st)
in
  rend_rect(r, iadd(iadd(x, 6), x_st), iadd(y, 2), sel_w, isub(h, 4), col_sel())
end

fun line_edit_caret(f: !Font, r: !Rend, x: int, y: int, h: int, b: !Buf, cursor: int, n: int): void = let
  val cur_clamped = imin(cursor, n)
  val cur_x_off = if igt(cur_clamped, 0) then font_width_buf(f, r, b, cur_clamped) else 0
  val cx = iadd(iadd(x, 6), cur_x_off)
in
  rend_rect(r, cx, iadd(y, 4), 2, isub(h, 8), col_caret())
end

implement ui_line_edit_draw(f, r, x, y, w, h, b, cursor, mark, is_focused, placeholder) = let
  val () = rend_rect(r, x, y, w, h, col_bg())
  val border = if is_on(is_focused) then col_accent() else col_line()
  val () = ui_draw_border(r, x, y, w, h, 1, border)
  val () = rend_scissor(r, iadd(x, 4), iadd(y, 2), isub(w, 8), isub(h, 4))
  val n = buf_len(b)
  val ty = iadd(y, idiv(isub(h, font_line_h(f)), 2))
  val () = if ieq(n, 0) andalso is_off(is_focused) then let
    val () = draw_s(f, r, iadd(x, 6), ty, placeholder, col_muted())
  in
  end else let
    val () = if ine(mark, cursor) andalso igt(n, 0) then line_edit_selection(f, r, x, y, h, b, cursor, mark, n) else ()
    val () = seen_int(if igt(n, 0) then font_draw_buf(f, r, iadd(x, 6), ty, b, n, col_text()) else 0)
    val () = if is_on(is_focused) then line_edit_caret(f, r, x, y, h, b, cursor, n) else ()
  in
  end
  val () = rend_scissor_off(r)
in
end

implement ui_pane_begin(r, x, y, w, h, bg_col) = let
  val () = ui_draw_shadow(r, x, y, w, h, 6)
  val () = rend_rect(r, x, y, w, h, bg_col)
  val () = ui_draw_border(r, x, y, w, h, 1, col_line())
in
end

implement ui_pane_draw_header(f, r, x, y, w, title, has_close) = let
  val bar_h = PANE_HEADER_HEIGHT
  val () = rend_rect(r, x, y, w, bar_h, col_bar())
  val () = rend_rect(r, x, iadd(y, isub(bar_h, 1)), w, 1, col_line())
  val ty = iadd(y, idiv(isub(bar_h, font_line_h(f)), 2))
  val () = draw_s(f, r, iadd(x, 10), ty, title, col_heading())
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
  val tw = font_width(f, r, c_str_ptr(text), c_strlen(text))
  val tx = iadd(x, idiv(isub(w, tw), 2))
  val ty = iadd(y, idiv(isub(h, font_line_h(f)), 2))
  val () = draw_s(f, r, tx, ty, text, tcol)
in
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

fun icon_button_label(f: !Font, r: !Rend, icon: int, text: string, x: int, y: int, h: int, icon_col: uint, text_col: uint): void = let
  val ty = iadd(y, idiv(isub(h, font_line_h(f)), 2))
in
  if igt(icon, 0) then let
    val () = ui_draw_icon(f, r, icon, iadd(x, 8), iadd(y, idiv(isub(h, 12), 2)), 12, icon_col)
    val () = draw_s(f, r, iadd(x, 26), ty, text, text_col)
  in
  end else let
    val () = draw_s(f, r, iadd(x, 8), ty, text, text_col)
  in
  end
end

implement ui_icon_button(f, r, icon, text, x, y, w, h, is_active, is_hover) = let
  val () = icon_button_frame(r, x, y, w, h, is_active, is_hover)
  val () = rend_scissor(r, x, y, w, h)
  val icon_col =
    if is_on(is_active) then col_accent()
    else if is_on(is_hover) then col_heading()
    else col_muted()
  val text_col =
    if is_on(is_active) then col_white()
    else if is_on(is_hover) then col_heading()
    else col_text()
  val () = icon_button_label(f, r, icon, text, x, y, h, icon_col, text_col)
in
  rend_scissor_off(r)
end


fun fit_next_index(p: ptr, n: int, i: int): int = let
  val b = mem_byte(p, n, i)
  val step = if ilt(b, 128) then 1 else if ilt(b, 224) then 2 else if ilt(b, 240) then 3 else 4
in
  imin(n, iadd(i, step))
end

