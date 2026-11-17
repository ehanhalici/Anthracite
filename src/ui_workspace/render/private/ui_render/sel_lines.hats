extern fun sel_lines_fuel_exhausted(f: !Font, r: !Rend, d: !Doc, li: int, l1: int, smin: int, smax: int, colx: int, oy: int, scroll: int, lh: int, scratch: &Buf >> _): void = "mac#anth_die_void"

fun sel_lines_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, r: !Rend, d: !Doc, li: int, l1: int, smin: int, smax: int, colx: int, oy: int, scroll: int, lh: int, scratch: &Buf >> _): void =
  if recursion_fuel_available(recfuel) then (
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
  if recursion_fuel_available(recfuel) then (
    if ige(lo, hi) then lo
    else let
      val mid = iadd(lo, idiv(isub(hi, lo), 2))
      val y = doc_node_y(d, mid)
      val h = doc_node_height(d, mid)
      val bottom=case+ doc_visual_node_bottom(d,mid) of | ~None_vt() => iadd(y,h) | ~Some_vt(value) => value
    in
      if ilt(bottom, target_y) then
        find_first_vis_with_fuel(recfuel - 1, d, iadd(mid, 1), hi, target_y)
      else
        find_first_vis_with_fuel(recfuel - 1, d, lo, mid, target_y)
    end
  ) else lo

fun rewind_line_start_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, idx: int, target_line: int): int =
  if recursion_fuel_available(recfuel) then (
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

implement first_vis_node(d,scroll) = let
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

fun draw_flash_line(f: !Font, r: !Rend, d: !Doc, oy: int, scroll: int, lh: int, ox: int, colx: int, pw: int): void = let
  val fl = doc_get_flash(d, mono_ns())
in
  if ige(fl, 0) andalso ilt(fl, doc_nlines(d)) then let
    val fy = isub(iadd(oy, doc_line_y(d, fl)), scroll)
    val () = rend_rect(r, colx, fy, editor_colw(f, r, ox, pw), lh, col_rgba(147, 51, 234, 110))
  in
  end else ()
end

fun draw_doc_content(f: !Font, r: !Rend, d: !Doc, ox: int, oy: int, pw: int, ph: int, scroll: int, lh: int, vault: !Buf, c: &Cache >> _, scratch: &Buf >> _, viewmode: ViewMode, colx: int, py: &int >> _, pa: &int >> _, pen_x: &int >> _, pen_line: &int >> _): void = let
  val () = draw_flash_line(f, r, d, oy, scroll, lh, ox, colx, pw)
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
  if recursion_fuel_available(recfuel) then (
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

fun draw_document_prepared_ex(f: !Font,r: !Rend,d: !Doc,ox: int,oy: int,pw: int,ph: int,
  scroll: int,lh: int,vault: !Buf,c: &Cache >> _,scratch: &Buf >> _,viewmode: ViewMode,height: int,colx: int,
  shover: Toggle, sdrag: Toggle): void = let
  var py: int = oy
  var pa: int = 0
  var pen_x: int = colx
  var pen_line: int = ~1
  val () = rend_clip_push(r, ox, oy, pw, ph)
  val () = draw_line_gutter(f, r, d, colx, oy, pw, ph, scroll, lh, scratch)
  val show_active = is_view_edit(viewmode) andalso doc_cursor_active(d)
  val show_sel = is_view_read(viewmode) orelse doc_cursor_active(d)
  val () = if show_sel then draw_selection(f, r, d, colx, oy, scroll, lh, scratch) else ()
  val () = draw_doc_content(f, r, d, ox, oy, pw, ph, scroll, lh, vault, c, scratch, viewmode, colx, py, pa, pen_x, pen_line)
  val () = if show_active then draw_caret(f, r, d, colx, oy, scroll, lh, scratch) else ()
  val () = rend_clip_pop(r)
  val () = if igt(height, ph) then ui_scroll_bar(r, isub(iadd(ox, pw), 8), oy, 8, ph, Vertical, height, ph, scroll, shover, sdrag) else ()
  val () = seen_int(py)
  val () = seen_int(pa)
in
end

fun draw_document_scrolled_ex(f: !Font,r: !Rend,d: !Doc,ox: int,oy: int,pw: int,ph: int,
  scroll: int,lh0: int,vault: !Buf,c: &Cache >> _,scratch: &Buf >> _,mode: ViewMode,
  shover: Toggle, sdrag: Toggle, out_h: &int >> _): int = let
  val lh=if font_text_active(f) then font_document_line_height(f,lh0) else lh0
  val colx=editor_colx(f,r,ox,pw)
  val width=editor_colw(f,r,ox,pw)
  val state=work_state(airlock_nat(MAX_REC_FUEL),c)
  val line=if doc_layout_cache_height(d)>0 then line_at_y_fast(d,scroll,lh) else ~1
  val scope: EmbedWorkScope= @{active=state.enabled,document=doc_identity(d),anchorLine=line,
    scroll=isub(scroll,if ilt(line,0) then 0 else doc_line_y(d,line)),height=ph,foreground=true,childDelta=0,band=EmbedWorkVisible()}
  val ()=work_set_scope(c,scope)
  val raw_height = prepare_document_layout(f, d, c, r, vault, lh, width, mode)
  val total_height = iadd(raw_height, imax(0, isub(ph, lh)))
  val max_scroll = imax(0, isub(raw_height, lh))
  val () = out_h := total_height
  val adjusted = if state.enabled then imin(max_scroll, imax(0, work_top(d, scope))) else imin(max_scroll, imax(0, scroll))
  val () = draw_document_prepared_ex(f, r, d, ox, oy, pw, ph, adjusted, lh, vault, c, scratch, mode, total_height, colx, shover, sdrag)
  val () = work_set_scope(c, state.scope)
in adjusted end

fun draw_document_scrolled(f: !Font,r: !Rend,d: !Doc,ox: int,oy: int,pw: int,ph: int,
  scroll: int,lh0: int,vault: !Buf,c: &Cache >> _,scratch: &Buf >> _,mode: ViewMode): int = let
  var dummy_h: int = 0
in
  draw_document_scrolled_ex(f, r, d, ox, oy, pw, ph, scroll, lh0, vault, c, scratch, mode, Off, Off, dummy_h)
end

implement draw_doc(f,r,d,ox,oy,pw,ph,scroll,lh,vault,c,scratch,mode) =
  seen_int(draw_document_scrolled(f,r,d,ox,oy,pw,ph,scroll,lh,vault,c,scratch,mode))

fun draw_tab_ell_prefix(f: !Font, r: !Rend, title: !Buf, tlen: int, bx: int, ty: int, text_w: int, tcol: uint): void =
  if ile(text_w, 20) then let
    val fit_n = ui_fit_str_bytes(f, r, buf_ptr(title), tlen, imax(0, text_w))
  in
    if igt(fit_n, 0) then seen_int(font_draw(f, r, iadd(bx, 8), ty, buf_ptr(title), fit_n, tcol)) else ()
  end else let
    val ell_w = font_width(f, r, c_str_ptr("..."), 3)
    val fit_n = ui_fit_str_bytes(f, r, buf_ptr(title), tlen, imax(0, isub(text_w, ell_w)))
    val adv = if igt(fit_n, 0) then font_draw(f, r, iadd(bx, 8), ty, buf_ptr(title), fit_n, tcol) else 0
  in
    draw_s(f, r, iadd(iadd(bx, 8), adv), ty, "...", tcol)
  end

fun draw_tab_title_clipped(f: !Font, r: !Rend, title: !Buf, bx: int, ty: int, text_w: int, tcol: uint): void = let
  val tlen = buf_len(title)
  val tw = if igt(tlen, 0) then font_width_buf(f, r, title, tlen) else 0
in
  if ile(tlen, 0) orelse ile(text_w, 0) then ()
  else if ile(tw, text_w) then seen_int(font_draw_buf(f, r, iadd(bx, 8), ty, title, tlen, tcol))
  else draw_tab_ell_prefix(f, r, title, tlen, bx, ty, text_w, tcol)
end

fun draw_tab_frame(f: !Font, r: !Rend, title: !Buf, bx: int, tab_w: int, i: int, active: int): void = let
  val lh = font_line_h(f)
  val tb_h = chrome_topbar_h(lh)
  val box_h = isub(tb_h, 8)
  val ty = idiv(isub(tb_h, lh), 2)
  val close_y = idiv(isub(tb_h, 8), 2)
  val bg = if ieq(i, active) then col_bg() else col_side()
  val () = rend_rect(r, bx, 4, tab_w, box_h, bg)
  val () = ui_draw_border(r, bx, 4, tab_w, box_h, 1, if ieq(i, active) then col_line() else col_bar())
  val () = if ieq(i, active) then rend_rect(r, bx, 4, tab_w, 2, col_accent()) else ()
  val close_pad = if ige(tab_w, 44) then 30 else if ieq(i, active) then 18 else 10
  val text_w = imax(0, isub(tab_w, close_pad))
  val tcol = if ieq(i, active) then col_white() else col_text()
  val () = rend_clip_push(r, iadd(bx, 6), 4, text_w, box_h)
  val () = draw_tab_title_clipped(f, r, title, bx, ty, text_w, tcol)
  val () = rend_clip_pop(r)
  val show_close = ige(tab_w, 44) orelse ieq(i, active)
  val close_x = isub(iadd(bx, tab_w), if ige(tab_w, 44) then 18 else 14)
in
  if show_close then ui_draw_icon(f, r, UI_ICON_CLOSE, close_x, close_y, 8, col_muted()) else ()
end

fun tab_pane_match(filter: int, tab_pane: !Buf, i: int): bool =
  if filter < 0 then true
  else if i < buf_len(tab_pane) then ieq(buf_get(tab_pane, i), filter)
  else ieq(0, filter)

fun count_pane_tabs_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), ts: !Tabs, i: int, filter: int, tab_pane: !Buf, acc: int
): int =
  if recursion_fuel_available(recfuel) then (
    case+ ts of
    | TNil() => acc
    | TCons(_, _, _, _, rest) => let
        val next_acc = if tab_pane_match(filter, tab_pane, i) then iadd(acc, 1) else acc
      in
        count_pane_tabs_with_fuel(recfuel - 1, rest, iadd(i, 1), filter, tab_pane, next_acc)
      end
  ) else acc

fun tab_box_width_for_bar(avail_w: int, pane_tabs: int): int =
  if ile(avail_w, 0) orelse ile(pane_tabs, 0) then UI_TAB_FIXED_WIDTH
  else let
    val slot_w = idiv(avail_w, pane_tabs)
    val fit_w = imax(28, isub(slot_w, 4))
  in
    imin(UI_TAB_FIXED_WIDTH, fit_w)
  end
