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
staload "ui_workspace/ui_raddbg.sats"

implement rd_menu_bar_button(f, r, x, y, w, h, text, is_active, is_hover) = let
  val () =
    if ieq(is_active, 1) then let
      val () = rend_rect(r, x, y, w, h, col_side())
      val () = rend_rect(r, x, isub(iadd(y, h), 2), w, 2, col_accent())
    in
    end else if ieq(is_hover, 1) then let
      val () = rend_rect(r, x, y, w, h, col_bar())
      val () = rend_rect(r, x, isub(iadd(y, h), 2), w, 2, col_line())
    in
    end else ()
  val tcol =
    if ieq(is_active, 1) then col_white()
    else if ieq(is_hover, 1) then col_heading()
    else col_text()
  val tw = font_width(f, r, c_str_ptr(text), c_strlen(text))
  val tx = iadd(x, idiv(isub(w, tw), 2))
  val ty = iadd(y, idiv(isub(h, font_line_h(f)), 2))
  val _dt = draw_s(f, r, tx, ty, text, tcol)
in
end

implement rd_icon_button(f, r, icon, text, x, y, w, h, is_active, is_hover) = let
  val bg =
    if ieq(is_active, 1) then col_side()
    else if ieq(is_hover, 1) then col_bar()
    else col_bg()
  val border =
    if ieq(is_active, 1) then col_accent()
    else if ieq(is_hover, 1) then col_line()
    else col_bg()
  val () = rend_rect(r, x, y, w, h, bg)
  val () = if ieq(is_active, 1) orelse ieq(is_hover, 1) then ui_draw_border(r, x, y, w, h, 1, border) else ()
  val icon_col =
    if ieq(is_active, 1) then col_accent()
    else if ieq(is_hover, 1) then col_heading()
    else col_muted()
  val text_col =
    if ieq(is_active, 1) then col_white()
    else if ieq(is_hover, 1) then col_heading()
    else col_text()
  val ty = iadd(y, idiv(isub(h, font_line_h(f)), 2))
  val () = if igt(icon, 0) then let
    val () = ui_draw_icon(f, r, icon, iadd(x, 8), iadd(y, idiv(isub(h, 12), 2)), 12, icon_col)
    val _dt = draw_s(f, r, iadd(x, 26), ty, text, text_col)
  in
  end else let
    val _dt = draw_s(f, r, iadd(x, 8), ty, text, text_col)
  in
  end
in
end

fun fit_str_bytes(f: !Font, r: !Rend, p: ptr, n: int, max_w: int): int = let
  var i: int = 0
  var last_fit: int = 0
in
  while (ilt(i, n)) (
    let
      val b = mem_byte(p, n, i)
      val step = if ilt(b, 128) then 1 else if ilt(b, 224) then 2 else if ilt(b, 240) then 3 else 4
      val next_i = imin(n, iadd(i, step))
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

implement rd_cell(f, r, x, y, w, h, depth, is_expandable, is_expanded, icon, label, value_text, is_selected, is_hover) = let
  val () =
    if ieq(is_selected, 1) then let
      val () = rend_rect(r, x, y, w, h, col_side())
      val () = rend_rect(r, x, y, 2, h, col_accent())
    in
    end else if ieq(is_hover, 1) then let
      val () = rend_rect(r, x, y, w, h, col_bar())
    in
    end else ()
  val x_indent = iadd(x, imul(depth, 14))
  val ty = iadd(y, idiv(isub(h, font_line_h(f)), 2))
  var x_cur: int = x_indent
  val () =
    if ieq(is_expandable, 1) then let
      val () = ui_expander(f, r, x_cur, iadd(y, idiv(isub(h, 8), 2)), is_expanded, is_hover)
      val () = x_cur := iadd(x_cur, 14)
    in
    end else let
      val () = x_cur := iadd(x_cur, 6)
    in
    end
  val () =
    if igt(icon, 0) then let
      val icol = if ieq(is_selected, 1) then col_accent() else col_muted()
      val () = ui_draw_icon(f, r, icon, x_cur, iadd(y, idiv(isub(h, 12), 2)), 12, icol)
      val () = x_cur := iadd(x_cur, 16)
    in
    end else ()
  val lcol = if ieq(is_selected, 1) then col_white() else col_text()
  val llen = c_strlen(label)
  val vlen = c_strlen(value_text)
  val vw = if igt(vlen, 0) then font_width(f, r, c_str_ptr(value_text), vlen) else 0
  val max_label_w = imax(0, isub(iadd(x, w), iadd(x_cur, if igt(vlen, 0) then iadd(vw, 12) else 6)))
  val fit_n = fit_str_bytes(f, r, c_str_ptr(label), llen, max_label_w)
  val _dl = if igt(fit_n, 0) then font_draw(f, r, x_cur, ty, c_str_ptr(label), fit_n, lcol) else 0
  val () =
    if igt(vlen, 0) then let
      val vx = isub(iadd(x, w), iadd(vw, 10))
      val _dv = draw_s(f, r, vx, ty, value_text, col_muted())
    in
    end else ()
in
end

implement rd_loading_overlay(f, r, w, h, progress_pct, title, status_msg) = let
  val () = rend_rect(r, 0, 0, w, h, col_overlay())
  val mw = 380
  val mh = 140
  val mx = idiv(isub(w, mw), 2)
  val my = idiv(isub(h, mh), 2)
  val () = ui_draw_shadow(r, mx, my, mw, mh, 8)
  val () = rend_rect(r, mx, my, mw, mh, col_bg())
  val () = ui_draw_border(r, mx, my, mw, mh, 1, col_line())
  val _dt = draw_s(f, r, iadd(mx, 20), iadd(my, 20), title, col_heading())
  val track_x = iadd(mx, 20)
  val track_y = iadd(my, 54)
  val track_w = isub(mw, 40)
  val () = rend_rect(r, track_x, track_y, track_w, 8, col_bar())
  val () = ui_draw_border(r, track_x, track_y, track_w, 8, 1, col_line())
  val clamped = imin(100, imax(0, progress_pct))
  val fill_w = idiv(imul(track_w, clamped), 100)
  val () = if igt(fill_w, 0) then rend_rect(r, track_x, track_y, fill_w, 8, col_accent()) else ()
  val _ds = draw_s(f, r, iadd(mx, 20), iadd(my, 76), status_msg, col_muted())
in
end

fun put_digits(b: &Buf >> Buf, n: int): void =
  if ige(n, 10) then let
    val q = idiv(n, 10)
    val () = put_digits(b, q)
    val d = isub(n, imul(q, 10))
  in
    bpush(b, iadd(48, d))
  end else let
    val () = bpush(b, iadd(48, n))
  in
  end

fun format_line_num(n: int, b: &Buf >> Buf): void = let
  val () = bclear(b)
  val s0 = if ilt(n, 10) then "   " else if ilt(n, 100) then "  " else if ilt(n, 1000) then " " else ""
  val () = bstr(b, s0)
  val () = put_digits(b, if igt(n, 0) then n else 0)
in
end

implement rd_code_slice(f, r, x, y, w, h, line_num, code_text, is_active, has_bp, is_hover) = let
  val () =
    if ieq(is_active, 1) then rend_rect(r, x, y, w, h, col_side())
    else if ieq(is_hover, 1) then rend_rect(r, x, y, w, h, col_bar())
    else ()
  val gutter_w = 44
  val () = rend_rect(r, iadd(x, gutter_w), y, 1, h, col_line())
  val () = if ieq(has_bp, 1) then let
    val dot_sz = 8
    val dot_y = iadd(y, idiv(isub(h, dot_sz), 2))
    val () = rend_rect(r, iadd(x, 6), dot_y, dot_sz, dot_sz, col_danger())
  in
  end else ()
  var num_b = buf_make(16)
  val () = format_line_num(line_num, num_b)
  val num_len = buf_len(num_b)
  val num_w = font_width(f, r, buf_ptr(num_b), num_len)
  val ty = iadd(y, idiv(isub(h, font_line_h(f)), 2))
  val num_x = isub(iadd(x, isub(gutter_w, 6)), num_w)
  val _dn = font_draw(f, r, num_x, ty, buf_ptr(num_b), num_len, col_muted())
  val () = buf_free(num_b)
  val tcol = if ieq(is_active, 1) then col_white() else col_text()
  val _dc = draw_s(f, r, iadd(x, iadd(gutter_w, 8)), ty, code_text, tcol)
in
end

implement rd_label(f, r, x, y, text) =
  draw_s(f, r, x, y, text, col_text())

implement rd_error_label(f, r, x, y, text) =
  draw_s(f, r, x, y, text, col_danger())

implement rd_help_label(f, r, x, y, text) =
  draw_s(f, r, x, y, text, col_muted())
