extern fun sel_lines_fuel_exhausted(f: !Font, r: !Rend, d: !Doc, li: int, l1: int, smin: int, smax: int, colx: int, oy: int, scroll: int, lh: int, scratch: &Buf >> _): void = "mac#anth_die_void"

fun sel_lines_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, r: !Rend, d: !Doc, li: int, l1: int, smin: int, smax: int, colx: int, oy: int, scroll: int, lh: int, scratch: &Buf >> _): void =
  if recfuel > 0 then (
    if ile(li, l1) andalso ilt(li, doc_nlines(d)) then let
      val ls = doc_line_start(d, li)
      val le = if ilt(iadd(li, 1), doc_nlines(d)) then doc_line_start(d, iadd(li, 1)) else doc_len(d)
      val () = draw_sel_line(f, r, d, ls, le, smin, smax, colx, oy, scroll, lh, scratch)
    in
      sel_lines_with_fuel(recfuel - 1, f, r, d, iadd(li, 1), l1, smin, smax, colx, oy, scroll, lh, scratch)
    end else ()
  ) else sel_lines_fuel_exhausted(f, r, d, li, l1, smin, smax, colx, oy, scroll, lh, scratch)

fun draw_sel_lines(f: !Font, r: !Rend, d: !Doc, l0: int, l1: int, smin: int, smax: int, colx: int, oy: int, scroll: int, lh: int, scratch: &Buf >> _): void =
  sel_lines_with_fuel(airlock_nat(MAX_REC_FUEL), f, r, d, l0, l1, smin, smax, colx, oy, scroll, lh, scratch)

fun draw_selection(f: !Font, r: !Rend, d: !Doc, colx: int, oy: int, scroll: int, lh: int, scratch: &Buf >> _): void =
 if doc_visual_active(d) then visual_draw_selection(f,r,d,colx,oy,scroll,lh,scratch) else let
  val caret = doc_caret(d)
  val anchor = doc_anchor(d)
in
  if ine(caret, anchor) then let
    val smin = imin(caret, anchor)
    val smax = imax(caret, anchor)
    val l0 = doc_line_of(d, smin)
    val l1 = doc_line_of(d, smax)
  in
    draw_sel_lines(f, r, d, l0, l1, smin, smax, colx, oy, scroll, lh, scratch)
  end else ()
end


fun draw_caret(f: !Font, r: !Rend, d: !Doc, colx: int, oy: int, scroll: int, lh: int, scratch: &Buf >> _): void = let
  var cx: int = 0
  var cy: int = 0
  val () = caret_xy(f, r, d, colx, oy, scroll, lh, scratch, cx, cy)
  val bar = if igt(lh, 0) then lh else 1
  val () = rend_rect(r, cx, cy, 2, bar, col_caret())
in
end

fun find_first_vis_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, lo: int, hi: int, target_y: int): int =
  if recfuel > 0 then (
    if ige(lo, hi) then lo
    else let
      val mid = iadd(lo, idiv(isub(hi, lo), 2))
      val y = doc_node_y(d, mid)
      val h = doc_node_height(d, mid)
      val bottom=case+ doc_visual_node_bottom(d,mid) of | None() => iadd(y,h) | Some(value) => value
    in
      if ilt(bottom, target_y) then
        find_first_vis_with_fuel(recfuel - 1, d, iadd(mid, 1), hi, target_y)
      else
        find_first_vis_with_fuel(recfuel - 1, d, lo, mid, target_y)
    end
  ) else lo

fun rewind_line_start_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, idx: int, target_line: int): int =
  if recfuel > 0 then (
    if ile(idx, 0) then 0
    else let
      val prev = isub(idx, 1)
      val pline = doc_line_of(d, doc_node_start(d, prev))
    in
      if ieq(pline, target_line) then
        rewind_line_start_with_fuel(recfuel - 1, d, prev, target_line)
      else idx
    end
  ) else idx

fun first_vis_node(d: !Doc, scroll: int): int = let
  val n = doc_nnodes(d)
in
  if ile(n, 0) then 0
  else if ile(scroll, 0) then 0
  else let
    val raw_idx = find_first_vis_with_fuel(airlock_nat(MAX_REC_FUEL), d, 0, n, scroll)
  in
    if ige(raw_idx, n) then raw_idx
    else let
      val target_line = doc_line_of(d, doc_node_start(d, raw_idx))
    in
      rewind_line_start_with_fuel(airlock_nat(MAX_REC_FUEL), d, raw_idx, target_line)
    end
  end
end

fun draw_flash_line(r: !Rend, d: !Doc, oy: int, scroll: int, lh: int, colx: int, pw: int): void = let
  val fl = doc_get_flash(d, mono_ns())
in
  if ige(fl, 0) andalso ilt(fl, doc_nlines(d)) then let
    val fy = isub(iadd(oy, doc_line_y(d, fl)), scroll)
    val () = rend_rect(r, colx, fy, column_w(pw), lh, col_rgba(147, 51, 234, 110))
  in
  end else ()
end

fun draw_doc_content(f: !Font, r: !Rend, d: !Doc, ox: int, oy: int, pw: int, ph: int, scroll: int, lh: int, vault: !Buf, c: &Cache >> _, scratch: &Buf >> _, viewmode: ViewMode, colx: int, py: &int >> _, pa: &int >> _, pen_x: &int >> _, pen_line: &int >> _): void = let
  val () = draw_flash_line(r, d, oy, scroll, lh, colx, pw)
in
  if doc_nnodes(d) > 0 then let
    val start_i = first_vis_node(d, scroll)
  in
    draw_nodes_impl(f, r, d, ox, oy, pw, ph, scroll, lh, vault, c, scratch, start_i, py, pa, pen_x, pen_line, viewmode)
  end else if doc_visual_active(d) then
    seen_int(visual_draw_slice(f,r,d,0,doc_len(d),colx,oy,scroll,lh,ph,col_text(),scratch))
  else
    draw_plain_doc(f, r, d, colx, oy, pw, ph, scroll, lh, scratch)
end

fun draw_gutter_num(f: !Font, r: !Rend, line: int, colx: int, yy: int, scratch: &Buf >> _): void = let
  val () = buffer_clear(scratch)
  val () = buffer_append_integer(scratch, iadd(line, 1))
  val slen = buf_len(scratch)
  val tw = font_width_buf(f, r, scratch, slen)
  val num_end = gutter_num_end_x(f, r, colx)
  val tx = isub(num_end, tw)
in
  seen_int(font_draw_buf(f, r, tx, yy, scratch, slen, col_muted()))
end

fun draw_gutter_line(f: !Font, r: !Rend, d: !Doc, line: int, colx: int, oy: int, scroll: int, ph: int, scratch: &Buf >> _): void = let
  val step = doc_line_step(d, line)
in
  if step > 0 then let
    val yy = isub(iadd(oy, doc_line_y(d, line)), scroll)
  in
    if ilt(yy, isub(oy, step)) orelse igt(yy, iadd(oy, ph)) then ()
    else draw_gutter_num(f, r, line, colx, yy, scratch)
  end else ()
end

extern fun draw_gutter_range_fuel_exhausted(f: !Font, r: !Rend, d: !Doc, li: int, en: int, colx: int, oy: int, scroll: int, ph: int, scratch: &Buf >> _): void = "mac#anth_die_void"

fun draw_gutter_range_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), f: !Font, r: !Rend, d: !Doc, li: int, en: int, colx: int, oy: int, scroll: int, ph: int, scratch: &Buf >> _
): void =
  if recfuel > 0 then (
    if ige(li, en) then ()
    else let
      val () = draw_gutter_line(f, r, d, li, colx, oy, scroll, ph, scratch)
    in
      draw_gutter_range_with_fuel(recfuel - 1, f, r, d, iadd(li, 1), en, colx, oy, scroll, ph, scratch)
    end
  ) else draw_gutter_range_fuel_exhausted(f, r, d, li, en, colx, oy, scroll, ph, scratch)

fun draw_line_gutter(f: !Font, r: !Rend, d: !Doc, colx: int, oy: int, pw: int, ph: int, scroll: int, lh: int, scratch: &Buf >> _): void = let
  val n = doc_nlines(d)
  val start_li = imax(0, isub(line_at_y_fast(d, scroll, lh), 1))
  val end_li = imin(n, iadd(line_at_y_fast(d, iadd(scroll, ph), lh), 2))
in
  draw_gutter_range_with_fuel(airlock_nat(MAX_REC_FUEL), f, r, d, start_li, end_li, colx, oy, scroll, ph, scratch)
end

implement draw_doc(f, r, d, ox, oy, pw, ph, scroll, lh0, vault, c, scratch, viewmode) = let
  val lh=if font_text_active(f) then font_document_line_height(f,lh0) else lh0
  val colx = editor_colx(f, r, ox, pw)
  val width=imax(1,imin(column_w(pw),isub(iadd(ox,pw),iadd(colx,16))))
  val colw=if font_text_active(f) then width else column_w(pw)
  val height=prepare_document_layout(f,d,c,r,vault,lh,colw,viewmode)
  var py: int = oy
  var pa: int = 0
  var pen_x: int = colx
  var pen_line: int = ~1
  val () = rend_scissor(r, ox, oy, pw, ph)
  val () = draw_line_gutter(f, r, d, colx, oy, pw, ph, scroll, lh, scratch)
  val () = draw_selection(f, r, d, colx, oy, scroll, lh, scratch)
  val () = draw_doc_content(f, r, d, ox, oy, pw, ph, scroll, lh, vault, c, scratch, viewmode, colx, py, pa, pen_x, pen_line)
  val () = if is_view_edit(viewmode) then draw_caret(f, r, d, colx, oy, scroll, lh, scratch) else ()
  val () = rend_scissor_off(r)
  val () = if igt(height, ph) then ui_scroll_bar(r, isub(iadd(ox, pw), 6), oy, 6, ph, Vertical, height, ph, scroll, Off, Off) else ()
  val () = seen_int(py)
  val () = seen_int(pa)
in
end


fun tab_item_width(f: !Font, r: !Rend, title: !Buf): int = let
  val tlen = buf_len(title)
  val tw = if igt(tlen, 0) then font_width_buf(f, r, title, tlen) else 0
in
  imin(200, imax(100, iadd(tw, 36)))
end

fun draw_tab_frame(f: !Font, r: !Rend, title: !Buf, bx: int, tab_w: int, i: int, active: int): void = let
  val tlen = buf_len(title)
  val bg = if ieq(i, active) then col_bg() else col_side()
  val () = rend_rect(r, bx, 4, tab_w, 28, bg)
  val () = ui_draw_border(r, bx, 4, tab_w, 28, 1, if ieq(i, active) then col_line() else col_bar())
  val () = if ieq(i, active) then rend_rect(r, bx, 4, tab_w, 2, col_accent()) else ()
  val text_w = isub(tab_w, 32)
  val () = rend_scissor(r, iadd(bx, 8), 4, text_w, 28)
  val () = seen_int(font_draw_buf(f, r, iadd(bx, 8), 8, title, tlen, if ieq(i, active) then col_white() else col_text()))
  val () = rend_scissor_off(r)
  val close_x = isub(iadd(bx, tab_w), 18)
  val () = ui_draw_icon(f, r, UI_ICON_CLOSE, close_x, 14, 8, col_muted())
in
end

fun tab_pane_match(filter: int, tab_pane: !Buf, i: int): bool =
  if filter < 0 then true
  else if i < buf_len(tab_pane) then ieq(buf_get(tab_pane, i), filter)
  else ieq(0, filter)

