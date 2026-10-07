#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "mem.sats"
staload "os/fs.sats"
staload "core_render/render.sats"
staload "core_render/gl.sats"
staload "data_font/font.sats"
staload "ui_workspace/ui_common.sats"
staload "ui_workspace/ui_widgets.sats"

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
  val () = rend_rect(r, isub(x, 2), iadd(y, 2), iadd(w, 4), iadd(h, 4), col_rgba(0, 0, 0, 15))
  val () = rend_rect(r, isub(x, 1), iadd(y, 2), iadd(w, 2), iadd(h, 2), col_rgba(0, 0, 0, 30))
  val () = rend_rect(r, x, iadd(y, 2), w, h, col_rgba(0, 0, 0, 50))
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
  if ieq(is_vert, 1) then rend_rect(r, x, y, 1, len, col_line())
  else rend_rect(r, x, y, len, 1, col_line())

implement ui_label(f, r, x, y, s, col) =
  draw_s(f, r, x, y, s, col)

implement ui_label_multiline(f, r, x, y, max_w, s, col, lh) = let
  val n = c_strlen(s)
  var cur_x: int = x
  var cur_y: int = y
  var start: int = 0
  var i: int = 0
  val sp = c_str_ptr(s)
  val () = while (ile(i, n)) (
    let
      val is_end = if ige(i, n) then 1 else 0
      val c = if ieq(is_end, 1) then 0 else c_str_byte(s, i)
      val is_break = if ieq(is_end, 1) orelse ieq(c, 32) orelse ieq(c, 10) then 1 else 0
    in
      if ieq(is_break, 1) then let
        val word_len = isub(i, start)
        val p = mem_ptr_at(sp, n, start)
        val tw = if igt(word_len, 0) then font_width(f, r, p, word_len) else 0
        val next_x = iadd(cur_x, tw)
        val wrap = if igt(next_x, iadd(x, max_w)) andalso igt(cur_x, x) then 1 else 0
        val () = if ieq(wrap, 1) then (
          cur_x := x;
          cur_y := iadd(cur_y, lh)
        ) else ()
        val () = if igt(word_len, 0) then let
          val _dw = font_draw(f, r, cur_x, cur_y, p, word_len, col)
          val sp_w = font_width(f, r, c_str_ptr(" "), 1)
          val () = cur_x := iadd(cur_x, iadd(tw, sp_w))
        in
        end else ()
        val () = if ieq(c, 10) then (
          cur_x := x;
          cur_y := iadd(cur_y, lh)
        ) else ()
        val () = start := iadd(i, 1)
      in
        i := iadd(i, 1)
      end else (
        i := iadd(i, 1)
      )
    end
  )
in
  iadd(isub(cur_y, y), lh)
end

implement ui_badge(f, r, x, y, s, bg_col, text_col) = let
  val n = c_strlen(s)
  val tw = font_width(f, r, c_str_ptr(s), n)
  val bw = iadd(tw, 12)
  val bh = isub(font_line_h(f), 2)
  val () = rend_rect(r, x, y, bw, bh, bg_col)
  val () = ui_draw_border(r, x, y, bw, bh, 1, col_line())
  val _dw = draw_s(f, r, iadd(x, 6), iadd(y, 1), s, text_col)
in
  bw
end

implement ui_button(f, r, x, y, w, h, text, is_hover, is_active) = let
  val bg =
    if ieq(is_active, 1) then col_menu()
    else if ieq(is_hover, 1) then col_side()
    else col_bar()
  val border =
    if ieq(is_active, 1) orelse ieq(is_hover, 1) then col_accent()
    else col_line()
  val text_col =
    if ieq(is_active, 1) then col_white()
    else if ieq(is_hover, 1) then col_heading()
    else col_text()
  val () = rend_rect(r, x, y, w, h, bg)
  val () = ui_draw_border(r, x, y, w, h, 1, border)
  val tw = font_width(f, r, c_str_ptr(text), c_strlen(text))
  val tx = iadd(x, idiv(isub(w, tw), 2))
  val ty = iadd(y, idiv(isub(h, font_line_h(f)), 2))
  val _dt = draw_s(f, r, tx, ty, text, text_col)
in
end

implement ui_hover_label(f, r, x, y, w, h, text, is_hover) = let
  val bg = if ieq(is_hover, 1) then col_side() else col_bg()
  val () = if ieq(is_hover, 1) then (
    rend_rect(r, x, y, w, h, bg);
    ui_draw_border(r, x, y, w, h, 1, col_line())
  ) else ()
  val ty = iadd(y, idiv(isub(h, font_line_h(f)), 2))
  val tcol = if ieq(is_hover, 1) then col_heading() else col_text()
  val _dt = draw_s(f, r, iadd(x, 6), ty, text, tcol)
in
end

implement ui_expander(f, r, x, y, is_expanded, is_hover) = let
  val acol = if ieq(is_hover, 1) then col_white() else col_accent()
  val () =
    if ieq(is_expanded, 1) then ui_draw_icon(f, r, UI_ICON_DOWN_ARROW, x, y, 8, acol)
    else ui_draw_icon(f, r, UI_ICON_RIGHT_ARROW, x, y, 8, acol)
in
end

implement ui_sort_header(f, r, x, y, w, h, text, is_sorted, is_ascending, is_hover) = let
  val bg = if ieq(is_hover, 1) then col_side() else col_bar()
  val () = rend_rect(r, x, y, w, h, bg)
  val () = ui_draw_border(r, x, y, w, h, 1, col_line())
  val ty = iadd(y, idiv(isub(h, font_line_h(f)), 2))
  val tcol = if ieq(is_hover, 1) then col_heading() else col_text()
  val _dt = draw_s(f, r, iadd(x, 8), ty, text, tcol)
  val () = if ieq(is_sorted, 1) then let
    val icon = if ieq(is_ascending, 1) then UI_ICON_UP_ARROW else UI_ICON_DOWN_ARROW
    val () = ui_draw_icon(f, r, icon, isub(iadd(x, w), 14), ty, 8, col_accent())
  in
  end else ()
in
end

implement ui_toggle_switch(r, x, y, w, h, is_on) = let
  val track_bg = if ieq(is_on, 1) then col_accent() else col_bar()
  val () = rend_rect(r, x, y, w, h, track_bg)
  val () = ui_draw_border(r, x, y, w, h, 1, col_line())
  val knob_sz = isub(h, 4)
  val knob_x = if ieq(is_on, 1) then isub(iadd(x, w), iadd(knob_sz, 2)) else iadd(x, 2)
  val knob_col = if ieq(is_on, 1) then col_bg() else col_muted()
  val () = rend_rect(r, knob_x, iadd(y, 2), knob_sz, knob_sz, knob_col)
in
end

implement ui_slider(r, x, y, w, h, val_pct, is_hover, is_active) = let
  val track_h = 4
  val track_y = iadd(y, idiv(isub(h, track_h), 2))
  val () = rend_rect(r, x, track_y, w, track_h, col_line())
  val pct_clamped = imin(100, imax(0, val_pct))
  val fill_w = idiv(imul(w, pct_clamped), 100)
  val () = if igt(fill_w, 0) then rend_rect(r, x, track_y, fill_w, track_h, col_accent()) else ()
  val knob_sz = 10
  val knob_x = isub(iadd(x, fill_w), idiv(knob_sz, 2))
  val knob_y = iadd(y, idiv(isub(h, knob_sz), 2))
  val knob_col =
    if ieq(is_active, 1) then col_white()
    else if ieq(is_hover, 1) then col_heading()
    else col_accent()
  val () = rend_rect(r, knob_x, knob_y, knob_sz, knob_sz, knob_col)
  val () = ui_draw_border(r, knob_x, knob_y, knob_sz, knob_sz, 1, col_line())
in
end

implement ui_scroll_bar(r, x, y, w, h, is_vert, total_len, visible_len, scroll_pos, is_hover, is_dragging) = let
  val () = rend_rect(r, x, y, w, h, col_bar())
  val () = if igt(total_len, visible_len) andalso igt(visible_len, 0) then let
    val travel = if ieq(is_vert, 1) then h else w
    val min_thumb = 18
    val thumb_len = imax(min_thumb, idiv(imul(travel, visible_len), total_len))
    val max_scroll = isub(total_len, visible_len)
    val max_travel = isub(travel, thumb_len)
    val thumb_off = idiv(imul(imax(0, imin(scroll_pos, max_scroll)), max_travel), max_scroll)
    val thumb_col =
      if ieq(is_dragging, 1) then col_accent()
      else if ieq(is_hover, 1) then col_muted()
      else col_line()
    val () =
      if ieq(is_vert, 1) then rend_rect(r, iadd(x, 1), iadd(y, thumb_off), isub(w, 2), thumb_len, thumb_col)
      else rend_rect(r, iadd(x, thumb_off), iadd(y, 1), thumb_len, isub(h, 2), thumb_col)
  in
  end else ()
in
end

implement ui_line_edit_draw(f, r, x, y, w, h, b, cursor, mark, is_focused, placeholder) = let
  val () = rend_rect(r, x, y, w, h, col_bg())
  val border = if ieq(is_focused, 1) then col_accent() else col_line()
  val () = ui_draw_border(r, x, y, w, h, 1, border)
  val () = rend_scissor(r, iadd(x, 4), iadd(y, 2), isub(w, 8), isub(h, 4))
  val n = buf_len(b)
  val ty = iadd(y, idiv(isub(h, font_line_h(f)), 2))
  val () = if ieq(n, 0) andalso ieq(is_focused, 0) then let
    val _ph = draw_s(f, r, iadd(x, 6), ty, placeholder, col_muted())
  in
  end else let
    val () = if ine(mark, cursor) andalso igt(n, 0) then let
      val sel_st = imin(cursor, mark)
      val sel_en = imax(cursor, mark)
      val x_st = if igt(sel_st, 0) then font_width(f, r, buf_ptr(b), sel_st) else 0
      val x_en = font_width(f, r, buf_ptr(b), imin(sel_en, n))
      val sel_w = isub(x_en, x_st)
      val () = rend_rect(r, iadd(iadd(x, 6), x_st), iadd(y, 2), sel_w, isub(h, 4), col_sel())
    in
    end else ()
    val _dt = if igt(n, 0) then font_draw(f, r, iadd(x, 6), ty, buf_ptr(b), n, col_text()) else 0
    val () = if ieq(is_focused, 1) then let
      val cur_clamped = imin(cursor, n)
      val cur_x_off = if igt(cur_clamped, 0) then font_width(f, r, buf_ptr(b), cur_clamped) else 0
      val cx = iadd(iadd(x, 6), cur_x_off)
      val () = rend_rect(r, cx, iadd(y, 4), 2, isub(h, 8), col_caret())
    in
    end else ()
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
  val bar_h = 28
  val () = rend_rect(r, x, y, w, bar_h, col_bar())
  val () = rend_rect(r, x, iadd(y, isub(bar_h, 1)), w, 1, col_line())
  val ty = iadd(y, idiv(isub(bar_h, font_line_h(f)), 2))
  val _dt = draw_s(f, r, iadd(x, 10), ty, title, col_heading())
  val () = if ieq(has_close, 1) then let
    val _cx = draw_s(f, r, isub(iadd(x, w), 18), ty, "x", col_muted())
  in
  end else ()
in
end

implement ui_color_picker(r, x, y, w, h, r_val, g_val, b_val) = let
  val swatch_w = 28
  val c = col_rgba(r_val, g_val, b_val, 255)
  val () = rend_rect(r, x, y, swatch_w, h, c)
  val () = ui_draw_border(r, x, y, swatch_w, h, 1, col_line())
  val strip_x = iadd(x, iadd(swatch_w, 8))
  val strip_w = isub(w, iadd(swatch_w, 8))
  val () = if igt(strip_w, 0) then ui_hue_strip(r, strip_x, y, strip_w, h, 50) else ()
in
end

implement ui_hue_strip(r, x, y, w, h, hue_pct) = let
  val () = ui_draw_border(r, x, y, w, h, 1, col_line())
  var i: int = 0
  val () = while (ilt(i, w)) (
    let
      val pct = idiv(imul(i, 600), w)
      val r_c = if ilt(pct, 100) then 255 else if ilt(pct, 200) then isub(255, imul(isub(pct, 100), 255)/100) else if ilt(pct, 400) then 0 else if ilt(pct, 500) then imul(isub(pct, 400), 255)/100 else 255
      val g_c = if ilt(pct, 100) then imul(pct, 255)/100 else if ilt(pct, 300) then 255 else if ilt(pct, 400) then isub(255, imul(isub(pct, 300), 255)/100) else 0
      val b_c = if ilt(pct, 200) then 0 else if ilt(pct, 300) then imul(isub(pct, 200), 255)/100 else if ilt(pct, 500) then 255 else isub(255, imul(isub(pct, 500), 255)/100)
      val () = rend_rect(r, iadd(x, i), y, 1, h, col_rgba(r_c, g_c, b_c, 255))
    in
      i := iadd(i, 1)
    end
  )
  val needle_x = iadd(x, idiv(imul(w, imin(100, imax(0, hue_pct))), 100))
  val () = rend_rect(r, isub(needle_x, 1), y, 3, h, col_white())
in
end
