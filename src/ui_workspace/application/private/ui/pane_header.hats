fun app_take_tab_hists(s: &App_record >> _): TabHistList = let
  val hl = s.tab_hists
  val () = s.tab_hists := THNil()
in
  hl
end

fun app_put_tab_hists(s: &App_record >> _, hl: TabHistList): void = let
  val ph = s.tab_hists
  val () = s.tab_hists := hl
in
  tab_hist_free(ph)
end

fun app_sync_tab_hists(s: &App_record >> _, ts: !Tabs): void = let
  val hl = app_take_tab_hists(s)
in
  app_put_tab_hists(s, tab_hist_sync(hl, ts))
end

fun app_drop_tab_hist(s: &App_record >> _, idx: int): void = let
  val hl = app_take_tab_hists(s)
in
  app_put_tab_hists(s, tab_hist_drop(hl, idx))
end

fun app_move_tab_hist(s: &App_record >> _, from_i: int, to_i: int): void = let
  val hl = app_take_tab_hists(s)
in
  app_put_tab_hists(s, tab_hist_move(hl, from_i, to_i))
end

fun app_clone_tab_hist(s: &App_record >> _, idx: int): void = let
  val hl = app_take_tab_hists(s)
in
  app_put_tab_hists(s, tab_hist_clone(hl, idx))
end

fun app_rename_tab_hists(s: &App_record >> _, old_p: !Buf, new_p: !Buf): void = let
  val hl = app_take_tab_hists(s)
in
  app_put_tab_hists(s, tab_hist_rename_prefix(hl, old_p, new_p))
end

fun validate_pane_left(s: &App_record >> _, n: int): void = let
  val act_ok = ige(s.active, 0) andalso ilt(s.active, n) andalso ieq(buf_get(s.tab_pane, s.active), 0)
in
  if not(act_ok) then let
    val f_left = tab_pane_find_first(s.tab_pane, 0)
    val () = if ige(f_left, 0) then s.active := f_left else ()
  in end else ()
end

fun validate_pane_right(s: &App_record >> _, n: int): void = let
  val right_ok = ige(s.righti, 0) andalso ilt(s.righti, n) andalso ieq(buf_get(s.tab_pane, s.righti), 1)
in
  if not(right_ok) then let
    val f_right = tab_pane_find_first(s.tab_pane, 1)
    val () = if ige(f_right, 0) then s.righti := f_right else ()
  in end else ()
end

fun validate_panes_len(s: &App_record >> _, n: int): void = let
  val () = if buf_len(s.tab_pane) < n then sync_tab_pane(s.tab_pane, n, s.split, s.righti) else ()
  val has_right = tab_pane_has(s.tab_pane, 1)
  val has_left = tab_pane_has(s.tab_pane, 0)
in
  if is_on(s.split) then (
    if not(has_right) orelse not(has_left) then (
      s.split := Off; s.focus := Off; tab_pane_fill_all(s.tab_pane, n, 0)
    ) else (validate_pane_left(s, n); validate_pane_right(s, n))
  ) else ()
end

fun split_pane_single(s: &App_record >> _): void = let
  val ts = s.tabs
  val () = s.tabs := TNil()
  val ts2 = tabs_clone_tab(ts, 0)
  val ph = s.tabs
  val () = s.tabs := ts2
  val () = tabs_free(ph)
  val () = app_clone_tab_hist(s, 0)
  val () = buf_ensure(s.tab_pane, 2)
  val () = buf_set_len(s.tab_pane, 2)
  val () = buf_set(s.tab_pane, 0, 0)
  val () = buf_set(s.tab_pane, 1, 1)
  val () = s.active := 0
  val () = s.righti := 1
  val () = s.split := On
  val () = s.focus := On
  val () = s.cursor_pane := 1
  val () = validate_panes_len(s, 2)
in
  save_app_session(s)
end

fun split_pane_multi(s: &App_record >> _, ti: int): void = let
  val n = tabs_len(s.tabs)
  val () = tab_pane_init_split(s.tab_pane, n, ti)
  val () = s.split := On
  val () = s.righti := ti
  val () = s.focus := On
  val () = s.cursor_pane := 1
  val () = if ieq(s.active, ti) then let
    val nxt = tab_pane_find_first(s.tab_pane, 0)
    val () = if ige(nxt, 0) then s.active := nxt else ()
  in end else ()
  val () = validate_panes_len(s, n)
in
  save_app_session(s)
end

fun toggle_split_pane(s: &App_record >> _): void = let
  val n = tabs_len(s.tabs)
in
  if is_on(s.split) then let
    val () = if is_on(s.focus) andalso ige(s.righti, 0) andalso ilt(s.righti, n) then
      s.active := s.righti
    else ()
    val () = tab_pane_fill_all(s.tab_pane, n, 0)
    val () = s.split := Off
    val () = s.focus := Off
    val () = s.cursor_pane := 0
  in
    save_app_session(s)
  end else if ile(n, 1) then split_pane_single(s)
  else let
    val tgt = if igt(s.active, 0) then 0 else 1
  in
    split_pane_multi(s, tgt)
  end
end

fun nav_arrow_sz(hdr_h: int): int =
  imin(imax(UI_BREADCRUMB_ARROW_SIZE_PIXELS, isub(hdr_h, 10)), imax(UI_BREADCRUMB_ARROW_SIZE_PIXELS, idiv(hdr_h, 2)))

fun nav_btn_w(hdr_h: int): int =
  imax(UI_BREADCRUMB_BTN_WIDTH, iadd(nav_arrow_sz(hdr_h), 14))

fun nav_btn_x_back(ox: int): int = iadd(ox, 8)

fun nav_btn_x_fwd(ox: int, hdr_h: int): int =
  iadd(ox, iadd(8, iadd(nav_btn_w(hdr_h), UI_BREADCRUMB_BTN_GAP)))

fun crumb_start_x(ox: int, hdr_h: int): int =
  iadd(nav_btn_x_fwd(ox, hdr_h), iadd(nav_btn_w(hdr_h), 10))

fun ph_prefix_eq_m {rem:nat} .<rem>. (p: !Buf, pfx: !Buf, i: int, rem: int(rem)): bool =
  if rem = 0 then true
  else if ieq(buf_get(p, i), buf_get(pfx, i)) then ph_prefix_eq_m(p, pfx, iadd(i, 1), rem - 1)
  else false

fun vault_trimmed_len(vault: !Buf): int = let
  val n = buf_len(vault)
in
  if igt(n, 1) andalso ieq(buf_get(vault, isub(n, 1)), CHAR_SLASH) then isub(n, 1) else n
end

fun pane_rel_path(vault: !Buf, path: !Buf, dst: &Buf >> _): void = let
  val () = buffer_clear(dst)
  val vlen = vault_trimmed_len(vault)
  val plen = buf_len(path)
  val () =
    if igt(vlen, 0) andalso igt(plen, iadd(vlen, 1))
       andalso ieq(buf_get(path, vlen), CHAR_SLASH)
       andalso ph_prefix_eq_m(path, vault, 0, airlock_nat(imax(0, vlen))) then
      buffer_append_range(dst, path, iadd(vlen, 1), plen)
    else if igt(plen, 0) then buffer_append_all(dst, path)
    else ()
in
  strip_md_ext(dst)
end

fun crumb_leading_offset(rel: !Buf, n: int): int =
  if igt(n, 0) andalso ieq(buf_get(rel, 0), CHAR_SLASH) then 1 else 0

fun next_slash_m {rem:nat} .<rem>. (b: !Buf, i: int, rem: int(rem)): int =
  if rem = 0 then i
  else if ieq(buf_get(b, i), CHAR_SLASH) then i
  else next_slash_m(b, iadd(i, 1), rem - 1)

fun next_slash(b: !Buf, i: int, n: int): int =
  if ige(i, n) then n else next_slash_m(b, i, airlock_span(i, n))

fun crumb_seg_width(f: !Font, r: !Rend, rel: !Buf, i: int, sl: int): int = let
  val slen = imax(0, isub(sl, i))
in
  if ile(slen, 0) then 0 else let
    var seg = buf_make(imax(4, slen))
    val () = buffer_append_range(seg, rel, i, sl)
    val w = font_width_buf(f, r, seg, slen)
    val () = buf_free(seg)
  in w end
end

fun draw_crumb_segs_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), f: !Font, r: !Rend, rel: !Buf, i: int, n: int,
  cur_x: int, ty: int, tb_h: int, doc_top: int, hx: int, hy: int
): void =
  if recursion_fuel_available(recfuel) then (
    if ige(i, n) then ()
    else let
      val sl = next_slash(rel, i, n)
      val slen = isub(sl, i)
      val sw = crumb_seg_width(f, r, rel, i, sl)
      val is_last = ige(sl, n)
      val hov = ige(hy, tb_h) andalso ilt(hy, doc_top)
        andalso ige(hx, cur_x) andalso ilt(hx, iadd(cur_x, sw))
      val col = if is_last then col_heading() else if hov then col_accent() else col_muted()
      val adv = if igt(slen, 0) then font_draw_at(f, r, cur_x, ty, rel, i, slen, col) else 0
      val () = if hov andalso not(is_last) then rend_rect(r, cur_x, iadd(ty, font_line_h(f)), sw, 1, col_accent()) else ()
      val sep_x = iadd(cur_x, adv)
      val sep_adv = if not(is_last) then font_draw(f, r, sep_x, ty, c_str_ptr(" / "), 3, col_muted()) else 0
    in
      draw_crumb_segs_m(recfuel - 1, f, r, rel, iadd(sl, 1), n, iadd(sep_x, sep_adv), ty, tb_h, doc_top, hx, hy)
    end
  ) else ()

fun draw_pane_nav_buttons(
  f: !Font, r: !Rend, s: &App_record, ox: int, tab_idx: int
): void = let
  val bw = nav_btn_w(s.hdr_h)
  val asz = nav_arrow_sz(s.hdr_h)
  val bx = nav_btn_x_back(ox)
  val fx = nav_btn_x_fwd(ox, s.hdr_h)
  val by = iadd(s.tb_h, 3)
  val bh = isub(s.hdr_h, 6)
  val can_b = tab_hist_can_back(s.tab_hists, tab_idx)
  val can_f = tab_hist_can_forward(s.tab_hists, tab_idx)
  val hb = ige(s.hoverx, bx) andalso ilt(s.hoverx, iadd(bx, bw)) andalso ige(s.hovery, by) andalso ilt(s.hovery, iadd(by, bh))
  val hf = ige(s.hoverx, fx) andalso ilt(s.hoverx, iadd(fx, bw)) andalso ige(s.hovery, by) andalso ilt(s.hovery, iadd(by, bh))
  val cb = if not(can_b) then col_line() else if hb then col_white() else col_text()
  val cf = if not(can_f) then col_line() else if hf then col_white() else col_text()
  val () = if can_b andalso hb then rend_rect(r, bx, by, bw, bh, col_bar()) else ()
  val () = if can_f andalso hf then rend_rect(r, fx, by, bw, bh, col_bar()) else ()
  val ax_off = idiv(isub(bw, iadd(idiv(asz, 2), 1)), 2)
  val ay = iadd(by, idiv(isub(bh, asz), 2))
  val () = ui_draw_icon(f, r, UI_ICON_LEFT_ARROW, iadd(bx, ax_off), ay, asz, cb)
in
  ui_draw_icon(f, r, UI_ICON_RIGHT_ARROW, iadd(fx, ax_off), ay, asz, cf)
end

fun split_btn_w(hdr_h: int): int = imax(20, isub(hdr_h, 6))
fun split_btn_x(ox: int, pw: int, hdr_h: int): int = isub(iadd(ox, pw), iadd(split_btn_w(hdr_h), 6))

fun draw_pane_split_button(r: !Rend, s: &App_record, ox: int, pw: int): void = let
  val bw = split_btn_w(s.hdr_h)
  val bx = split_btn_x(ox, pw, s.hdr_h)
  val by = iadd(s.tb_h, 3)
  val hov = ige(s.hoverx, bx) andalso ilt(s.hoverx, iadd(bx, bw)) andalso ige(s.hovery, by) andalso ilt(s.hovery, iadd(by, bw))
  val fg = if hov then col_white() else col_muted()
  val () = if hov then rend_rect(r, bx, by, bw, bw, col_bar()) else ()
  val ix = iadd(bx, 4)
  val iy = iadd(by, 4)
  val iw = imax(6, isub(bw, 8))
  val ih = imax(6, isub(bw, 8))
  val () = ui_draw_border(r, ix, iy, iw, ih, 1, fg)
in
  if is_off(s.split) then rend_rect(r, iadd(ix, idiv(iw, 2)), iy, 1, ih, fg)
  else rend_rect(r, iadd(ix, 2), iadd(iy, idiv(ih, 2)), isub(iw, 4), 1, fg)
end

fun draw_crumb_rel(
  f: !Font, r: !Rend, s: &App_record, ox: int, pw: int, rel: !Buf
): void = let
  val rlen = buf_len(rel)
  val hy = s.tb_h
  val doc_top = doc_top_y_of(s)
  val start0 = crumb_start_x(ox, s.hdr_h)
  val max_right = isub(split_btn_x(ox, pw, s.hdr_h), 6)
  val ty = iadd(hy, imax(0, idiv(isub(s.hdr_h, font_line_h(f)), 2)))
  val () = rend_clip_push(r, start0, hy, imax(1, isub(max_right, start0)), s.hdr_h)
  val () = if igt(rlen, 0) then let
    val lead = crumb_leading_offset(rel, rlen)
  in
    draw_crumb_segs_m(airlock_nat(MAX_REC_FUEL), f, r, rel, lead, rlen, start0, ty, hy, doc_top, s.hoverx, s.hovery)
  end else ()
in
  rend_clip_pop(r)
end

fun draw_pane_header(
  f: !Font, r: !Rend, s: &App_record, ts: !Tabs, ox: int, pw: int, tab_idx: int, is_active_pane: Toggle
): void = let
  val hy = s.tb_h
  val hdr_h = s.hdr_h
  val () = rend_rect(r, ox, hy, pw, hdr_h, col_bg())
  val () = if is_on(s.split) andalso is_on(is_active_pane) then
    rend_rect(r, ox, iadd(hy, isub(hdr_h, 2)), pw, 2, col_accent())
  else rend_rect(r, ox, iadd(hy, isub(hdr_h, 1)), pw, 1, col_line())
  val () = draw_pane_nav_buttons(f, r, s, ox, tab_idx)
  val () = draw_pane_split_button(r, s, ox, pw)
  var pbuf = buf_make(256)
  var rel = buf_make(256)
  val () = tabs_get_path(ts, tab_idx, pbuf)
  val () = pane_rel_path(s.vault, pbuf, rel)
  val () = draw_crumb_rel(f, r, s, ox, pw, rel)
  val () = buf_free(pbuf)
in
  buf_free(rel)
end

fun doc_title_block_height(doc_lh: int): int =
  iadd(UI_DOC_TITLE_TOP_PAD, iadd(idiv(imul(doc_lh, 7), 4), UI_DOC_TITLE_BOTTOM_PAD))

fun doc_content_top_y(doc_top: int, doc_lh: int): int =
  iadd(doc_top, doc_title_block_height(doc_lh))

fun draw_pane_doc_title_text(f: !Font, r: !Rend, doc_top: int, ox: int, pw: int, title: !Buf, doc_lh: int): void = let
  val tlen = buf_len(title)
  val colx = editor_colx(f, r, ox, pw)
  val ty = iadd(doc_top, UI_DOC_TITLE_TOP_PAD)
  val th = doc_title_block_height(doc_lh)
  val div_y = isub(iadd(doc_top, th), 8)
  val div_w = editor_colw(f, r, ox, pw)
  val () = rend_clip_push(r, ox, doc_top, pw, th)
  val () = if igt(tlen, 0) then
    seen_int(font_draw_scaled_buf(f, r, colx, ty, title, tlen, col_heading(), 7, 4))
  else ()
  val () = rend_rect(r, colx, div_y, div_w, 1, col_line())
in
  rend_clip_pop(r)
end

fun resolve_doc_name_step(ts: !Tabs, tab_idx: int, pbuf: !Buf, tbuf: &Buf >> Buf): void = let
  val plen = buf_len(pbuf)
in
  if igt(plen, 0) then base_name_no_md(pbuf, tbuf)
  else (tabs_get_title(ts, tab_idx, tbuf); strip_md_ext(tbuf))
end

fun resolve_doc_header_name(ts: !Tabs, tab_idx: int, tbuf: &Buf >> Buf): void = let
  var pbuf = buf_make(256)
  val () = tabs_get_path(ts, tab_idx, pbuf)
  val () = resolve_doc_name_step(ts, tab_idx, pbuf, tbuf)
in
  buf_free(pbuf)
end

fun draw_pane_doc_title(f: !Font, r: !Rend, s: &App_record, ts: !Tabs, ox: int, pw: int, tab_idx: int, doc_lh: int): void = let
  val doc_top = doc_top_y_of(s)
  val th = doc_title_block_height(doc_lh)
  val () = rend_rect(r, ox, doc_top, pw, th, col_bg())
  var tbuf = buf_make(128)
  val () = resolve_doc_header_name(ts, tab_idx, tbuf)
  val () = draw_pane_doc_title_text(f, r, doc_top, ox, pw, tbuf, doc_lh)
in
  buf_free(tbuf)
end

fun open_dirs_add_line(open_dirs: &Buf >> _, dir: !Buf): void =
  if igt(buf_len(dir), 0) andalso not(is_in_lines(open_dirs, dir)) then (
    buffer_append_all(open_dirs, dir);
    buf_push(open_dirs, CHAR_LF)
  ) else ()

fun push_slash_if_needed(dst: &Buf >> _, src: !Buf): void = let
  val n = buf_len(src)
in
  if igt(n, 0) andalso ine(buf_get(src, isub(n, 1)), CHAR_SLASH) then buf_push(dst, CHAR_SLASH)
  else ()
end

fun open_dirs_add_chain_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), open_dirs: &Buf >> _, vault: !Buf, rel: !Buf, i: int, n: int
): void =
  if recursion_fuel_available(recfuel) then (
    if ige(i, n) then ()
    else let
      val sl = next_slash(rel, i, n)
      var full = buf_make(256)
      val () = buffer_append_all(full, vault)
      val () = push_slash_if_needed(full, vault)
      val () = buffer_append_range(full, rel, 0, sl)
      val () = open_dirs_add_line(open_dirs, full)
      val () = buf_free(full)
    in
      open_dirs_add_chain_m(recfuel - 1, open_dirs, vault, rel, iadd(sl, 1), n)
    end
  ) else ()

fun find_tree_row_by_path_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), s: &App_record, target: !Buf, i: int
): int =
  if recursion_fuel_available(recfuel) then (
    if ige(i, s.tn) then ~1
    else let
      var rp = buf_make(256)
      val () = row_path(s.tree, s.tmeta, i, rp)
      val eq = ieq(c_strcmp(buffer_c_string(rp), buffer_c_string(target)), 0)
      val () = buf_free(rp)
    in
      if eq then i else find_tree_row_by_path_m(recfuel - 1, s, target, iadd(i, 1))
    end
  ) else ~1

fun tree_view_index_of_source_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), s: &App_record, wanted_src: int, vi: int
): int =
  if recursion_fuel_available(recfuel) then let
    val src = tree_source_for_view(s, vi)
  in
    if ilt(src, 0) then ~1
    else if ieq(src, wanted_src) then vi
    else tree_view_index_of_source_m(recfuel - 1, s, wanted_src, iadd(vi, 1))
  end else ~1

fun tree_reveal_focus_row(s: &App_record >> _, src_row: int): void =
  if ige(src_row, 0) then let
    val () = s.sel := src_row
    val () = s.tree_flash_row := src_row
    val () = s.tree_flash_until_ns := mono_ns() + 1000000000L
    val vi = tree_view_index_of_source_m(airlock_nat(MAX_REC_FUEL), s, src_row, 0)
  in
    if ige(vi, 0) then s.treescroll := imax(0, isub(vi, 2)) else ()
  end else ()

fun app_reveal_rel_in_tree(s: &App_record >> _, rel_prefix: !Buf): void = let
  val () = if igt(s.tn, 0) then sync_open_dirs_from_tree(s) else ()
  val () = s.side := SideFiles
  val () = s.qfocus := Off
  val () = open_dirs_add_chain_m(airlock_nat(MAX_REC_FUEL), s.open_dirs, s.vault, rel_prefix, 0, buf_len(rel_prefix))
  val () = s.tn := 0
  val () = s.treedirty := On
  val () = ensure_tree_fresh(s)
  var target = buf_make(256)
  val () = buffer_append_all(target, s.vault)
  val () = push_slash_if_needed(target, s.vault)
  val () = buffer_append_all(target, rel_prefix)
  val src_row = find_tree_row_by_path_m(airlock_nat(MAX_REC_FUEL), s, target, 0)
  val () = buf_free(target)
  val () = tree_reveal_focus_row(s, src_row)
in
  save_app_session(s)
end

fun crumb_hit_end_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), f: !Font, r: !Rend, rel: !Buf, i: int, n: int,
  cur_x: int, click_x: int
): int =
  if recursion_fuel_available(recfuel) then (
    if ige(i, n) then ~1
    else let
      val sl = next_slash(rel, i, n)
      val sw = crumb_seg_width(f, r, rel, i, sl)
      val sep_w = if ilt(sl, n) then font_width(f, r, c_str_ptr(" / "), 3) else 0
    in
      if ige(click_x, cur_x) andalso ilt(click_x, iadd(cur_x, sw)) then sl
      else crumb_hit_end_m(recfuel - 1, f, r, rel, iadd(sl, 1), n, iadd(cur_x, iadd(sw, sep_w)), click_x)
    end
  ) else ~1

fun run_nav_step(
  s: &App_record >> _, idx: int, dir: int,
  cp: !Buf, csc: int, cc: int,
  np: &Buf >> Buf, nsc: &int >> _, nc: &int >> _
): bool = let
  val hl = app_take_tab_hists(s)
in
  if ilt(dir, 0) then let
    val @(hl2, ok) = tab_hist_back(hl, idx, cp, csc, cc, np, nsc, nc)
    val () = app_put_tab_hists(s, hl2)
  in ok end else let
    val @(hl2, ok) = tab_hist_forward(hl, idx, cp, csc, cc, np, nsc, nc)
    val () = app_put_tab_hists(s, hl2)
  in ok end
end

fun nav_open_if_ok(ts: Tabs, idx: int, ok: bool, np: Buf, nsc: int, nc: int): Tabs =
  if ok then (
    if igt(buf_len(np), 0) then let
      val ts2 = tabs_open_at(ts, idx, np)
      val ts3 = tabs_set_scroll(ts2, idx, nsc)
    in tabs_set_caret(ts3, idx, nc) end
    else (buf_free(np); ts)
  ) else (buf_free(np); ts)

fun tabs_nav_step(s: &App_record >> _, ts: Tabs, pane: int, dir: int): Tabs = let
  val idx = if ieq(pane, 1) andalso is_on(s.split) then s.righti else s.active
  var cp = buf_make(256)
  var np = buf_make(256)
  val () = tabs_get_path(ts, idx, cp)
  val csc = tabs_get_scroll(ts, idx)
  val cc = tabs_caret(ts, idx)
  var nsc: int = 0
  var nc: int = 0
  val ok = run_nav_step(s, idx, dir, cp, csc, cc, np, nsc, nc)
  val () = buf_free(cp)
in
  nav_open_if_ok(ts, idx, ok, np, nsc, nc)
end

fun app_nav_step(s: &App_record >> _, pane: int, dir: int): void = let
  val ts = s.tabs; val () = s.tabs := TNil()
  val ts2 = tabs_nav_step(s, ts, pane, dir)
  val ph = s.tabs; val () = s.tabs := ts2; val () = tabs_free(ph)
in
  save_app_session(s)
end

fun reveal_seg_if(s: &App_record >> _, rel: !Buf, hit_end: int): void = let
  val lead = crumb_leading_offset(rel, hit_end)
in
  if igt(hit_end, lead) then let
    var seg = buf_make(256)
    val () = buffer_append_range(seg, rel, lead, hit_end)
    val () = app_reveal_rel_in_tree(s, seg)
  in
    buf_free(seg)
  end else ()
end

fun click_crumb_rel(
  f: !Font, r: !Rend, s: &App_record >> _, pane_ox: int, pw: int, click_x: int, rel: !Buf
): void = let
  val rlen = buf_len(rel)
  val start0 = crumb_start_x(pane_ox, s.hdr_h)
  val max_right = isub(split_btn_x(pane_ox, pw, s.hdr_h), 6)
in
  if igt(rlen, 0) andalso ige(click_x, start0) andalso ilt(click_x, max_right) then let
    val lead = crumb_leading_offset(rel, rlen)
    val hit_end = crumb_hit_end_m(airlock_nat(MAX_REC_FUEL), f, r, rel, lead, rlen, start0, click_x)
  in
    if ige(hit_end, 0) andalso ilt(hit_end, rlen) then reveal_seg_if(s, rel, hit_end) else ()
  end else ()
end

fun handle_crumb_click(f: !Font, r: !Rend, s: &App_record >> _, ts: !Tabs, pane_ox: int, pw: int, tab_idx: int, click_x: int): void = let
  var pbuf = buf_make(256)
  var rel = buf_make(256)
  val () = tabs_get_path(ts, tab_idx, pbuf)
  val () = pane_rel_path(s.vault, pbuf, rel)
  val () = click_crumb_rel(f, r, s, pane_ox, pw, click_x, rel)
  val () = buf_free(pbuf)
in
  buf_free(rel)
end

fun handle_pane_header_click(
  f: !Font, r: !Rend, s: &App_record >> _, ts: Tabs, pane: int, x: int, pane_ox: int, pw: int
): Tabs = let
  val () = s.focus := toggle_of(ieq(pane, 1))
  val () = s.editor_focused := Off
  val bw = nav_btn_w(s.hdr_h)
  val bx = nav_btn_x_back(pane_ox)
  val fx = nav_btn_x_fwd(pane_ox, s.hdr_h)
  val sbx = split_btn_x(pane_ox, pw, s.hdr_h)
  val sbw = split_btn_w(s.hdr_h)
  val tab_idx = if ieq(pane, 1) andalso is_on(s.split) then s.righti else s.active
in
  if ige(x, bx) andalso ilt(x, iadd(bx, bw)) then tabs_nav_step(s, ts, pane, ~1)
  else if ige(x, fx) andalso ilt(x, iadd(fx, bw)) then tabs_nav_step(s, ts, pane, 1)
  else if ige(x, sbx) andalso ilt(x, iadd(sbx, sbw)) then (toggle_split_pane(s); ts)
  else (handle_crumb_click(f, r, s, ts, pane_ox, pw, tab_idx, x); ts)
end
