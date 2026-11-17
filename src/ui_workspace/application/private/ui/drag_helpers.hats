fun draw_drop_target(f: !Font, r: !Rend, x: int, y: int, w: int, h: int, text: string): void = let
  val () = rend_rect(r, x, y, w, h, col_side())
  val () = ui_draw_border(r, iadd(x, 4), iadd(y, 4), isub(w, 8), isub(h, 8), 2, col_accent())
  val bw = 160
  val bh = 28
  val cx = iadd(x, idiv(isub(w, bw), 2))
  val cy = iadd(y, idiv(isub(h, bh), 2))
  val () = ui_badge(f, r, cx, cy, text, col_bg(), col_accent())
in
end

fun scrollbar_thumb_metrics(total: int, vis: int, track_h: int, scroll: int, out_off: &int >> _, out_len: &int >> _): void =
  if ile(total, vis) orelse ile(vis, 0) orelse ile(track_h, 0) then (
    out_off := 0; out_len := track_h
  ) else let
    val tlen = imax(18, idiv(imul(track_h, vis), total))
    val max_sc = isub(total, vis)
    val max_tr = imax(1, isub(track_h, tlen))
    val off = idiv(imul(imax(0, imin(scroll, max_sc)), max_tr), max_sc)
  in
    out_off := off; out_len := tlen
  end

fun scrollbar_y_to_scroll(y: int, oy: int, track_h: int, total: int, vis: int, grab_off: int): int =
  if ile(total, vis) orelse ile(vis, 0) then 0
  else let
    val tlen = imax(18, idiv(imul(track_h, vis), total))
    val max_sc = isub(total, vis)
    val max_tr = imax(1, isub(track_h, tlen))
    val thumb_y = imax(0, imin(max_tr, isub(isub(y, oy), grab_off)))
  in
    idiv(imul(thumb_y, max_sc), max_tr)
  end

fun doc_pane_total_h(s: &App_record, pane: int): int =
  if ieq(pane, 1) then s.doc_h_right else s.doc_h_left

fun doc_pane_tab_idx(s: &App_record, pane: int): int =
  if ieq(pane, 1) andalso is_on(s.split) then s.righti else s.active

fun begin_doc_scroll_drag_tabs(s: &App_record >> _, ts: Tabs, pane: int, y: int, h: int): Tabs = let
  val total = doc_pane_total_h(s, pane)
  val top_y = s.doc_top_y
  val track_h = imax(1, isub(h, top_y))
  val idx = doc_pane_tab_idx(s, pane)
  val cur_sc = tabs_get_scroll(ts, idx)
  var toff: int = 0; var tlen: int = 0
  val () = scrollbar_thumb_metrics(total, track_h, track_h, cur_sc, toff, tlen)
  val ty = iadd(top_y, toff)
  val on_thumb = ige(y, ty) andalso ilt(y, iadd(ty, tlen))
  val grab = if on_thumb then isub(y, ty) else idiv(tlen, 2)
  val () = s.focus := toggle_of(ieq(pane, 1))
  val () = s.drag := DragDocScroll
  val () = s.scroll_drag_pane := pane
  val () = s.scroll_drag_grab_y := grab
in
  if not(on_thumb) then
    tabs_set_scroll(ts, idx, scrollbar_y_to_scroll(y, top_y, track_h, total, track_h, grab))
  else ts
end

fun motion_doc_scroll(s: &App_record >> _, y: int): void = let
  val pane = s.scroll_drag_pane
  val total = doc_pane_total_h(s, pane)
  val top_y = s.doc_top_y
  val track_h = imax(1, isub(s.last_h, top_y))
  val idx = doc_pane_tab_idx(s, pane)
  val nsc = scrollbar_y_to_scroll(y, top_y, track_h, total, track_h, s.scroll_drag_grab_y)
  val ts = s.tabs; val () = s.tabs := TNil()
  val ts2 = tabs_set_scroll(ts, idx, nsc)
  val ph = s.tabs; val () = s.tabs := ts2
in
  tabs_free(ph)
end

fun begin_tree_scroll_drag(s: &App_record >> _, y: int, h: int): void = let
  val top_y = tree_top_y_of(s)
  val track_h = imax(1, isub(h, top_y))
  val vis_rows = imax(1, idiv(track_h, tree_row_h(s.fontpx)))
  val total = tree_visible_count(s)
  var toff: int = 0; var tlen: int = 0
  val () = scrollbar_thumb_metrics(total, vis_rows, track_h, s.treescroll, toff, tlen)
  val ty = iadd(top_y, toff)
  val on_thumb = ige(y, ty) andalso ilt(y, iadd(ty, tlen))
  val grab = if on_thumb then isub(y, ty) else idiv(tlen, 2)
  val () = s.drag := DragTreeScroll
  val () = s.scroll_drag_grab_y := grab
in
  if not(on_thumb) then
    s.treescroll := scrollbar_y_to_scroll(y, top_y, track_h, total, vis_rows, grab)
  else ()
end

fun motion_tree_scroll(s: &App_record >> _, y: int): void = let
  val top_y = tree_top_y_of(s)
  val track_h = imax(1, isub(s.last_h, top_y))
  val vis_rows = imax(1, idiv(track_h, tree_row_h(s.fontpx)))
  val total = tree_visible_count(s)
in
  s.treescroll := scrollbar_y_to_scroll(y, top_y, track_h, total, vis_rows, s.scroll_drag_grab_y)
end

fun begin_editor_pan_tabs(s: &App_record >> _, ts: !Tabs, pane: int, y: int): void = let
  val idx = doc_pane_tab_idx(s, pane)
  val () = s.focus := toggle_of(ieq(pane, 1))
  val () = s.drag := DragEditorPan
  val () = s.scroll_drag_pane := pane
  val () = s.pan_start_y := y
in
  s.pan_start_scroll := tabs_get_scroll(ts, idx)
end

fun motion_editor_pan(s: &App_record >> _, y: int): void = let
  val pane = s.scroll_drag_pane
  val idx = doc_pane_tab_idx(s, pane)
  val total = doc_pane_total_h(s, pane)
  val track_h = imax(1, isub(s.last_h, s.doc_top_y))
  val max_sc = imax(0, isub(total, track_h))
  val dy = isub(y, s.pan_start_y)
  val nsc = imax(0, imin(max_sc, isub(s.pan_start_scroll, dy)))
  val ts = s.tabs; val () = s.tabs := TNil()
  val ts2 = tabs_set_scroll(ts, idx, nsc)
  val ph = s.tabs; val () = s.tabs := ts2
in
  tabs_free(ph)
end

fun draw_tab_tooltip_buf(f: !Font, r: !Rend, w: int, th: int, bx: int, tbuf: !Buf): void = let
  val tlen = buf_len(tbuf)
in
  if igt(tlen, 0) then let
    val tw = font_width_buf(f, r, tbuf, tlen)
    val pw = imax(80, iadd(tw, 20))
    val ph = iadd(font_line_h(f), 10)
    val px = imax(8, imin(isub(w, iadd(pw, 8)), bx))
    val py = iadd(th, 4)
    val () = ui_draw_shadow(r, px, py, pw, ph, 4)
    val () = rend_rect(r, px, py, pw, ph, col_menu())
    val () = ui_draw_border(r, px, py, pw, ph, 1, col_line())
  in
    seen_int(font_draw_buf(f, r, iadd(px, 10), iadd(py, 5), tbuf, tlen, col_heading()))
  end else ()
end

fun draw_tab_tooltip(f: !Font, r: !Rend, s: &App_record, w: int): void =
  if is_drag_none(s.drag) andalso is_menu_none(s.menu) andalso is_prompt_none(s.prompt)
     andalso is_off(s.vault_select) andalso ige(s.hovery, 0) andalso ilt(s.hovery, s.tb_h) then let
    val sidew = if not(is_side_none(s.side)) then s.sidew else 0
    val mid = iadd(sidew, idiv(isub(w, sidew), 2))
    val is_r = is_on(s.split) andalso ige(s.hoverx, mid)
    val sx = if is_r then iadd(mid, 4) else topbar_tabs_x0(s)
    val bx_btn = topbar_mode_btn_x(w, s.modew)
    val avail_w = if is_r then imax(40, isub(isub(bx_btn, 6), sx))
      else if is_on(s.split) then imax(40, isub(isub(mid, 4), sx))
      else imax(60, isub(isub(bx_btn, 6), sx))
    val flt = if is_on(s.split) then (if is_r then 1 else 0) else ~1
    var ti: int = ~1; var bx: int = 0; var over: bool = false
    val () = tab_hover_info_w(f, r, s.tabs, sx, avail_w, s.hoverx, flt, s.tab_pane, ti, bx, over)
  in
    if ige(ti, 0) andalso over then let
      var tbuf = buf_make(128)
      val () = tabs_get_title(s.tabs, ti, tbuf)
      val () = draw_tab_tooltip_buf(f, r, w, s.tb_h, bx, tbuf)
    in
      buf_free(tbuf)
    end else ()
  end else ()

fun draw_file_drag_buf(f: !Font, r: !Rend, w: int, hx: int, hy: int, nbuf: !Buf): void = let
  val nlen = buf_len(nbuf)
  val tw = if igt(nlen, 0) then font_width_buf(f, r, nbuf, nlen) else 0
  val gw = imax(48, iadd(tw, 16))
  val gx = imax(4, imin(isub(w, iadd(gw, 4)), iadd(hx, 12)))
  val gy = imax(4, iadd(hy, 8))
  val () = ui_draw_shadow(r, gx, gy, gw, 24, 4)
  val () = rend_rect(r, gx, gy, gw, 24, col_menu())
  val () = ui_draw_border(r, gx, gy, gw, 24, 1, col_accent())
in
  if igt(nlen, 0) then seen_int(font_draw_buf(f, r, iadd(gx, 8), iadd(gy, 3), nbuf, nlen, col_heading())) else ()
end

fun draw_file_drag_name(s: &App_record, pbuf: !Buf, nbuf: &Buf >> Buf): void =
  if is_dir_mark(meta_dir(s.tmeta, s.dragi), DirNo) then base_name_no_md(pbuf, nbuf)
  else base_name(pbuf, nbuf)

fun draw_file_drag_ghost(f: !Font, r: !Rend, s: &App_record, w: int): void =
  if ige(s.dragi, 0) andalso ilt(s.dragi, s.tn) then let
    var pbuf = buf_make(128); var nbuf = buf_make(64)
    val () = row_path(s.tree, s.tmeta, s.dragi, pbuf)
    val () = draw_file_drag_name(s, pbuf, nbuf)
    val () = draw_file_drag_buf(f, r, w, s.hoverx, s.hovery, nbuf)
    val () = buf_free(pbuf)
  in
    buf_free(nbuf)
  end else ()

fun draw_file_drag_sidebar_target(f: !Font, r: !Rend, s: &App_record, h: int): void = let
  val row = tree_source_at_y(s, s.hovery)
  val valid = ige(row, 0) andalso ilt(row, s.tn) andalso ine(row, s.dragi)
  val top_y = tree_top_y_of(s)
in
  if valid andalso is_dir_mark(meta_dir(s.tmeta, row), DirYes) then let
    val vr = isub(tree_view_index_of_source_m(airlock_nat(MAX_REC_FUEL), s, row, 0), s.treescroll)
    val row_h = tree_row_h(s.fontpx)
    val ry = iadd(top_y, imul(vr, row_h))
  in
    if ige(ry, top_y) andalso ilt(ry, h) then
      ui_draw_border(r, 6, ry, isub(s.sidew, 12), row_h, 2, col_accent())
    else ()
  end else if not(valid) andalso ige(s.hovery, s.tb_h) then
    ui_draw_border(r, 4, iadd(s.tb_h, 2), isub(s.sidew, 8), isub(isub(h, s.tb_h), 4), 1, col_accent())
  else ()
end

fun draw_file_drag_overlay(f: !Font, r: !Rend, s: &App_record, w: int, h: int): void =
  if is_drag_file(s.drag) then let
    val sidew = if not(is_side_none(s.side)) then s.sidew else 0
    val mid = iadd(sidew, idiv(isub(w, sidew), 2))
    val th = s.tb_h
    val eh = isub(h, th)
  in
    if ilt(s.hoverx, sidew) then draw_file_drag_sidebar_target(f, r, s, h)
    else if is_on(s.split) then (
      if ige(s.hoverx, mid) then draw_drop_target(f, r, mid, th, isub(w, mid), eh, "Sag Bolmede Ac")
      else draw_drop_target(f, r, sidew, th, isub(mid, sidew), eh, "Sol Bolmede Ac")
    ) else draw_drop_target(f, r, sidew, th, isub(w, sidew), eh, "Bolmede Ac");
    draw_file_drag_ghost(f, r, s, w)
  end else ()
