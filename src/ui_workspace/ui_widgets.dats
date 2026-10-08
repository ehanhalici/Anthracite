#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "mem.sats"
staload "flag.sats"
staload "os/fs.sats"
staload "core_render/render.sats"
staload "core_render/gl.sats"
staload "data_font/font.sats"
staload "ui_workspace/ui_common.sats"
staload "ui_workspace/ui_widgets.sats"

implement is_vertical(a) = case+ a of
  | Vertical() => true
  | Horizontal() => false

macdef SHADOW_ALPHA_OUTER = 15
macdef SHADOW_ALPHA_MID = 30
macdef SHADOW_ALPHA_INNER = 50


macdef SCROLLBAR_MIN_THUMB = 18

macdef PANE_HEADER_HEIGHT = 28

macdef LOADING_MODAL_WIDTH = 380
macdef LOADING_MODAL_HEIGHT = 140
macdef LOADING_TRACK_HEIGHT = 8
macdef LOADING_MARGIN = 20
macdef LOADING_TRACK_Y_OFFSET = 54
macdef LOADING_STATUS_Y_OFFSET = 76



implement ui_draw_border(r, x, y, w, h, th, col) =
  if ile(th, 0) orelse ile(w, 0) orelse ile(h, 0) then ()
  else let
    val () = rend_rect(r, x, y, w, th, col)
    val () = rend_rect(r, x, iadd(y, isub(h, th)), w, th, col)
    val side_h = isub(h, imul(th, 2))
    val () = if igt(side_h, 0) then rend_rect(r, x, iadd(y, th), th, side_h, col) else ()
    val () = if igt(side_h, 0) then rend_rect(r, iadd(x, isub(w, th)), iadd(y, th), th, side_h, col) else ()
  in
  end

implement ui_draw_shadow(r, x, y, w, h, rad) = let
  val () = rend_rect(r, isub(x, 2), iadd(y, 2), iadd(w, 4), iadd(h, 4), col_rgba(0, 0, 0, SHADOW_ALPHA_OUTER))
  val () = rend_rect(r, isub(x, 1), iadd(y, 2), iadd(w, 2), iadd(h, 2), col_rgba(0, 0, 0, SHADOW_ALPHA_MID))
  val () = rend_rect(r, x, iadd(y, 2), w, h, col_rgba(0, 0, 0, SHADOW_ALPHA_INNER))
in
end

fun draw_arrow_right(r: !Rend, x: int, y: int, sz: int, col: uint): void = let
  var i: int = 0
  val steps = idiv(sz, 2)
  val () = while (ilt(i, steps)) (
    let
      val h = isub(sz, imul(i, 2))
      val () = if igt(h, 0) then rend_rect(r, iadd(x, i), iadd(y, i), 1, h, col) else ()
    in
      i := iadd(i, 1)
    end
  )
in
end

fun draw_arrow_down(r: !Rend, x: int, y: int, sz: int, col: uint): void = let
  var i: int = 0
  val steps = idiv(sz, 2)
  val () = while (ilt(i, steps)) (
    let
      val w = isub(sz, imul(i, 2))
      val () = if igt(w, 0) then rend_rect(r, iadd(x, i), iadd(y, i), w, 1, col) else ()
    in
      i := iadd(i, 1)
    end
  )
in
end

fun draw_arrow_left(r: !Rend, x: int, y: int, sz: int, col: uint): void = let
  var i: int = 0
  val steps = idiv(sz, 2)
  val () = while (ilt(i, steps)) (
    let
      val h = isub(sz, imul(i, 2))
      val () = if igt(h, 0) then rend_rect(r, isub(iadd(x, sz), i), iadd(y, i), 1, h, col) else ()
    in
      i := iadd(i, 1)
    end
  )
in
end

fun draw_arrow_up(r: !Rend, x: int, y: int, sz: int, col: uint): void = let
  var i: int = 0
  val steps = idiv(sz, 2)
  val () = while (ilt(i, steps)) (
    let
      val w = isub(sz, imul(i, 2))
      val () = if igt(w, 0) then rend_rect(r, iadd(x, i), isub(iadd(y, sz), i), w, 1, col) else ()
    in
      i := iadd(i, 1)
    end
  )
in
end

fun draw_check(r: !Rend, x: int, y: int, sz: int, col: uint): void = let
  val h2 = idiv(sz, 2)
  val () = rend_rect(r, iadd(x, 1), iadd(y, h2), 2, idiv(sz, 3), col)
  val () = rend_rect(r, iadd(x, 3), iadd(y, iadd(h2, 2)), 2, idiv(sz, 3), col)
  val () = rend_rect(r, iadd(x, 5), iadd(y, idiv(sz, 3)), 2, h2, col)
  val () = rend_rect(r, iadd(x, 7), iadd(y, idiv(sz, 5)), 2, h2, col)
in
end

fun draw_close_icon(r: !Rend, x: int, y: int, sz: int, col: uint): void = let
  var i: int = 0
  val () = while (ilt(i, sz)) (
    let
      val () = rend_rect(r, iadd(x, i), iadd(y, i), 1, 1, col)
      val () = rend_rect(r, iadd(x, isub(sz, i)), iadd(y, i), 1, 1, col)
    in
      i := iadd(i, 1)
    end
  )
in
end

fun draw_folder_icon(r: !Rend, x: int, y: int, sz: int, col: uint): void = let
  val tab_w = idiv(sz, 2)
  val () = rend_rect(r, x, y, tab_w, 2, col)
  val () = rend_rect(r, x, iadd(y, 2), sz, isub(sz, 2), col)
  val () = rend_rect(r, iadd(x, 2), iadd(y, 4), isub(sz, 4), isub(sz, 6), col_bg())
in
end

fun draw_file_icon(r: !Rend, x: int, y: int, sz: int, col: uint): void = let
  val () = rend_rect(r, iadd(x, 1), y, isub(sz, 2), sz, col)
  val () = rend_rect(r, iadd(x, 3), iadd(y, 3), isub(sz, 6), 1, col_bg())
  val () = rend_rect(r, iadd(x, 3), iadd(y, 6), isub(sz, 6), 1, col_bg())
  val () = rend_rect(r, iadd(x, 3), iadd(y, 9), isub(sz, 6), 1, col_bg())
in
end

fun draw_search_icon(r: !Rend, x: int, y: int, sz: int, col: uint): void = let
  val ring = isub(sz, 3)
  val () = ui_draw_border(r, x, y, ring, ring, 1, col)
  val () = rend_rect(r, iadd(x, isub(ring, 1)), iadd(y, isub(ring, 1)), 4, 2, col)
in
end

fun draw_settings_icon(r: !Rend, x: int, y: int, sz: int, col: uint): void = let
  val () = rend_rect(r, x, iadd(y, 2), sz, 1, col)
  val () = rend_rect(r, iadd(x, 3), iadd(y, 1), 2, 3, col)
  val () = rend_rect(r, x, iadd(y, 6), sz, 1, col)
  val () = rend_rect(r, iadd(x, isub(sz, 4)), iadd(y, 5), 2, 3, col)
  val () = rend_rect(r, x, iadd(y, 10), sz, 1, col)
  val () = rend_rect(r, iadd(x, 2), iadd(y, 9), 2, 3, col)
in
end

fun draw_plus_icon(r: !Rend, x: int, y: int, sz: int, col: uint): void = let
  val mid = idiv(sz, 2)
  val () = rend_rect(r, iadd(x, mid), y, 1, sz, col)
  val () = rend_rect(r, x, iadd(y, mid), sz, 1, col)
in
end

fun draw_split_icon(r: !Rend, x: int, y: int, sz: int, col: uint): void = let
  val () = ui_draw_border(r, x, y, sz, sz, 1, col)
  val () = rend_rect(r, iadd(x, idiv(sz, 2)), y, 1, sz, col)
in
end

implement ui_draw_icon(f, r, icon, x, y, sz, col) =
  if ieq(icon, UI_ICON_RIGHT_ARROW) then draw_arrow_right(r, x, y, sz, col)
  else if ieq(icon, UI_ICON_DOWN_ARROW) then draw_arrow_down(r, x, y, sz, col)
  else if ieq(icon, UI_ICON_LEFT_ARROW) then draw_arrow_left(r, x, y, sz, col)
  else if ieq(icon, UI_ICON_UP_ARROW) then draw_arrow_up(r, x, y, sz, col)
  else if ieq(icon, UI_ICON_CHECK) then draw_check(r, x, y, sz, col)
  else if ieq(icon, UI_ICON_CHECK_EMPTY) then ui_draw_border(r, x, y, sz, sz, 1, col)
  else if ieq(icon, UI_ICON_CLOSE) then draw_close_icon(r, x, y, sz, col)
  else if ieq(icon, UI_ICON_FOLDER) then draw_folder_icon(r, x, y, sz, col)
  else if ieq(icon, UI_ICON_FILE) then draw_file_icon(r, x, y, sz, col)
  else if ieq(icon, UI_ICON_SEARCH) then draw_search_icon(r, x, y, sz, col)
  else if ieq(icon, UI_ICON_SETTINGS) then draw_settings_icon(r, x, y, sz, col)
  else if ieq(icon, UI_ICON_PLUS) then draw_plus_icon(r, x, y, sz, col)
  else if ieq(icon, UI_ICON_SPLIT) then draw_split_icon(r, x, y, sz, col)
  else ()

implement ui_divider(r, x, y, len, is_vert) =
  if is_vertical(is_vert) then rend_rect(r, x, y, 1, len, col_line())
  else rend_rect(r, x, y, len, 1, col_line())

implement ui_badge(f, r, x, y, s, bg_col, text_col) = let
  val n = c_strlen(s)
  val tw = font_width(f, r, c_str_ptr(s), n)
  val bw = iadd(tw, 12)
  val bh = isub(font_line_h(f), 2)
  val () = rend_rect(r, x, y, bw, bh, bg_col)
  val () = ui_draw_border(r, x, y, bw, bh, 1, col_line())
  val () = draw_s(f, r, iadd(x, 6), iadd(y, 1), s, text_col)
in
end

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
  val () = draw_s(f, r, iadd(x, 6), ty, text, tcol)
in
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
end


fun fit_next_index(p: ptr, n: int, i: int): int = let
  val b = mem_byte(p, n, i)
  val step = if ilt(b, 128) then 1 else if ilt(b, 224) then 2 else if ilt(b, 240) then 3 else 4
in
  imin(n, iadd(i, step))
end

fun fit_str_bytes(f: !Font, r: !Rend, p: ptr, n: int, max_w: int): int = let
  var i: int = 0
  var last_fit: int = 0
in
  while (ilt(i, n)) (
    let
      val next_i = fit_next_index(p, n, i)
      val w = font_width(f, r, p, next_i)
    in
      if ile(w, max_w) then (
        last_fit := next_i;
        i := next_i
      ) else (
        i := n
      )
    end
  );
  last_fit
end


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

implement ui_cell(f, r, x, y, w, h, depth, is_expandable, is_expanded, icon, label, value_text, is_selected, is_hover) = let
  val () = ui_cell_bg(r, x, y, w, h, is_selected, is_hover)
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
  val () = bclear(b)
  val s0 = if ilt(n, 10) then "   " else if ilt(n, 100) then "  " else if ilt(n, 1000) then " " else ""
  val () = bstr(b, s0)
  val () = b_app_int(b, if igt(n, 0) then n else 0)
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
  var num_b = buf_make(16)
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
