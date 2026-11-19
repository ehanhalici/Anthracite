fun tree_expander_hit(s: &App_record, source: int, x: int): bool =
  if ilt(source, 0) then false
  else let
    val depth = meta_depth(s.tmeta, source)
    val expander_x = iadd(14, imul(depth, UI_TREE_INDENT_PIXELS))
  in
    is_dir_mark(meta_dir(s.tmeta, source), DirYes)
      andalso ige(x, expander_x) andalso ilt(x, iadd(expander_x, 18))
  end

fun ensure_tree_fresh(s: &App_record >> _): void =
  if is_on(s.treedirty) andalso is_side_files(s.side) then let
    val () = if igt(s.tn, 0) then sync_open_dirs_from_tree(s) else ()
    val () = buffer_clear(s.tree)
    val () = buffer_clear(s.tmeta)
    val () = buffer_clear(s.topen)
    val () = s.tn := 0
    val () = scan_dir(s.vault, 0, s.tmeta, s.tree, s.tn)
    val () = tree_open_defaults(s.tree, s.tmeta, s.open_dirs, s.topen, s.tn)
    val () = if ige(s.sel, s.tn) then s.sel := ~1 else ()
    val () = s.treescroll := 0
  in
    s.treedirty := Off
  end else ()

macdef SEARCH_LEFT_PIXELS = 8
macdef SEARCH_CHILD_INDENT_PIXELS = 20
fun search_relative_prefix{n:nat} .<n>. (left: int(n),text: !Buf,off: int,vault: !Buf,i: int): bool =
  if left = 0 then true else ieq(buf_get(text,iadd(off,i)),buf_get(vault,i)) andalso search_relative_prefix(left-1,text,off,vault,iadd(i,1))

fun norm_search_char(b: int): int =
  if ieq(b, 9) orelse ieq(b, 10) orelse ieq(b, 13) then 32 else b

fun norm_range_loop {rem:nat} .<rem>. (
  src: !Buf, i: int, en: int, dst: &Buf >> _, prev_sp: bool, collapse: bool, rem: int(rem)
): bool =
  if rem = 0 then prev_sp
  else if ige(i, en) then prev_sp
  else let
    val c = norm_search_char(buf_get(src, i))
    val is_sp = ieq(c, 32)
    val next_sp = if collapse andalso is_sp then (if prev_sp then true else (buf_push(dst, 32); true))
      else (buf_push(dst, c); is_sp)
  in
    norm_range_loop(src, iadd(i, 1), en, dst, next_sp, collapse, rem - 1)
  end

fun trim_sp_back_m {rem:nat} .<rem>. (b: !Buf, st: int, en: int, rem: int(rem)): int =
  if rem = 0 then st
  else if ile(en, st) then st
  else if ieq(buf_get(b, isub(en, 1)), 32) then trim_sp_back_m(b, st, isub(en, 1), rem - 1)
  else en

fun trim_sp_back(b: !Buf, st: int, en: int): int =
  if ilt(st, en) then trim_sp_back_m(b, st, en, airlock_span(st, en)) else st

fun skip_sp_fwd_m {rem:nat} .<rem>. (b: !Buf, st: int, en: int, rem: int(rem)): int =
  if rem = 0 then en
  else if ige(st, en) then en
  else if ieq(buf_get(b, st), 32) then skip_sp_fwd_m(b, iadd(st, 1), en, rem - 1)
  else st

fun skip_sp_fwd(b: !Buf, st: int, en: int): int =
  if ilt(st, en) then skip_sp_fwd_m(b, st, en, airlock_span(st, en)) else en

fun normalize_snippet(
  src: !Buf, off: int, len: int, match: int, count: int,
  norm: &Buf >> _, m_st: &int >> _, m_en: &int >> _
): void = let
  val () = buffer_clear(norm)
  val m_off = imax(0, imin(match, len))
  val m_cnt = imax(0, imin(count, isub(len, m_off)))
  val p0 = iadd(off, m_off)
  val p1 = iadd(p0, m_cnt)
  val p2 = iadd(off, len)
  val _ = if igt(m_off, 0) then norm_range_loop(src, off, p0, norm, true, true, airlock_span(off, p0)) else false
  val () = m_st := buf_len(norm)
  val _ = if igt(m_cnt, 0) then norm_range_loop(src, p0, p1, norm, false, false, airlock_span(p0, p1)) else false
  val () = m_en := buf_len(norm)
  val _ = if ilt(p1, p2) then norm_range_loop(src, p1, p2, norm, false, true, airlock_span(p1, p2)) else false
  val nlen = buf_len(norm)
  val trimmed = trim_sp_back(norm, m_en, nlen)
in
  buf_set_len(norm, trimmed)
end

fun slice_width(f: !Font, r: !Rend, b: !Buf, st: int, en: int, seg: &Buf >> _): int =
  if ige(st, en) then 0
  else let
    val () = buffer_clear(seg)
    val () = buffer_append_range(seg, b, st, en)
    val slen = buf_len(seg)
  in
    font_width_buf(f, r, seg, slen)
  end

fun skip_utf8_cont_m {rem:nat} .<rem>. (b: !Buf, i: int, en: int, rem: int(rem)): int =
  if rem = 0 then imin(i, en)
  else if ige(i, en) then imin(i, en)
  else let val c = buf_get(b, i) in
    if ige(c, 128) andalso ile(c, 191) then skip_utf8_cont_m(b, iadd(i, 1), en, rem - 1) else i
  end

fun find_next_sp_m {rem:nat} .<rem>. (b: !Buf, i: int, en: int, rem: int(rem)): int =
  if rem = 0 then en
  else if ige(i, en) then en
  else if ieq(buf_get(b, i), 32) then iadd(i, 1)
  else find_next_sp_m(b, iadd(i, 1), en, rem - 1)

fun step_suffix_cut(b: !Buf, i: int, en: int): int =
  if ige(i, en) then en
  else let
    val sp_nxt = find_next_sp_m(b, i, en, airlock_span(i, en))
    val char_nxt = skip_utf8_cont_m(b, iadd(i, 1), en, airlock_span(iadd(i, 1), en))
  in
    if ilt(sp_nxt, en) then sp_nxt else char_nxt
  end

fun fit_suffix_m {rem:nat} .<rem>. (
  f: !Font, r: !Rend, b: !Buf, i: int, en: int, max_w: int, seg: &Buf >> _, rem: int(rem)
): int =
  if rem = 0 then en
  else if ige(i, en) then en
  else if ile(slice_width(f, r, b, i, en, seg), max_w) then i
  else fit_suffix_m(f, r, b, step_suffix_cut(b, i, en), en, max_w, seg, rem - 1)

fun fit_suffix_start(f: !Font, r: !Rend, b: !Buf, st: int, en: int, max_w: int, seg: &Buf >> _): int =
  if ilt(st, en) andalso igt(max_w, 0) then fit_suffix_m(f, r, b, st, en, max_w, seg, airlock_span(st, en))
  else en

fun last_sp_m {rem:nat} .<rem>. (b: !Buf, i: int, en: int, best: int, rem: int(rem)): int =
  if rem = 0 then best
  else if ige(i, en) then best
  else last_sp_m(b, iadd(i, 1), en, if ieq(buf_get(b, i), 32) then i else best, rem - 1)

fun fit_prefix_end(f: !Font, r: !Rend, b: !Buf, st: int, en: int, max_w: int, seg: &Buf >> _): int =
  if ige(st, en) orelse ile(max_w, 0) then st
  else let
    val () = buffer_clear(seg)
    val () = buffer_append_range(seg, b, st, en)
    val slen = buf_len(seg)
    val fit = ui_fit_str_bytes(f, r, buf_ptr(seg), slen, max_w)
  in
    if ile(fit, 0) then st
    else if ige(iadd(st, fit), en) then en
    else let
      val cut = iadd(st, fit)
      val sp = if ieq(buf_get(b, cut), 32) then cut else last_sp_m(b, st, cut, ~1, airlock_span(st, cut))
    in
      if ige(sp, st) then sp else cut
    end
  end

fun draw_buf_range(f: !Font, r: !Rend, b: !Buf, st: int, en: int, x: int, y: int, col: uint, seg: &Buf >> _): void =
  if ilt(st, en) then let
    val () = buffer_clear(seg)
    val () = buffer_append_range(seg, b, st, en)
    val slen = buf_len(seg)
  in
    seen_int(font_draw_buf(f, r, x, y, seg, slen, col))
  end else ()

fun draw_match_pre(
  f: !Font, r: !Rend, norm: !Buf, m_st: int, tx: int, ty0: int, ty1: int, tw: int, mx: int, seg: &Buf >> _
): void = let
  val left_w = imax(0, isub(mx, tx))
  val s1 = if igt(m_st, 0) andalso igt(left_w, 4) then fit_suffix_start(f, r, norm, 0, m_st, left_w, seg) else m_st
  val pw1 = slice_width(f, r, norm, s1, m_st, seg)
  val () = draw_buf_range(f, r, norm, s1, m_st, imax(tx, isub(mx, pw1)), ty1, col_text(), seg)
  val e0 = trim_sp_back(norm, 0, s1)
  val s0 = if igt(e0, 0) then fit_suffix_start(f, r, norm, 0, e0, tw, seg) else 0
in
  if ilt(s0, e0) then draw_buf_range(f, r, norm, s0, e0, tx, ty0, col_muted(), seg) else ()
end

fun draw_match_post(
  f: !Font, r: !Rend, norm: !Buf, m_en: int, nlen: int, tx: int, ty1: int, ty2: int, tw: int, rx: int, seg: &Buf >> _
): void = let
  val rw = imax(0, isub(iadd(tx, tw), rx))
  val e1 = if ilt(m_en, nlen) andalso igt(rw, 4) then fit_prefix_end(f, r, norm, m_en, nlen, rw, seg) else m_en
  val () = draw_buf_range(f, r, norm, m_en, e1, rx, ty1, col_text(), seg)
  val s2 = skip_sp_fwd(norm, e1, nlen)
  val e2 = if ilt(s2, nlen) then fit_prefix_end(f, r, norm, s2, nlen, tw, seg) else s2
in
  if ilt(s2, e2) then draw_buf_range(f, r, norm, s2, e2, tx, ty2, col_muted(), seg) else ()
end

fun draw_search_header(f: !Font, r: !Rend, s: &App_record, row: int, y: int): void = let
  val at = imul(row, SEARCH_RESULT_WORDS)
  val off = buf_get32(s.hmeta, iadd(at, SEARCH_RESULT_TEXT))
  val length = buf_get32(s.hmeta, iadd(at, SEARCH_RESULT_LENGTH))
  val match_cnt = buf_get32(s.hmeta, iadd(at, SEARCH_RESULT_MATCH_LENGTH))
  val root = buf_len(s.vault)
  val relative = igt(length, root) andalso search_relative_prefix(airlock_nat(imax(0, root)), s.hits, off, s.vault, 0)
  val skip = if relative then iadd(root, 1) else 0
  var label: Buf = buf_make(0)
  val () = buffer_append_range(label, s.hits, iadd(off, skip), iadd(off, length))
  val () = if ieq(length, 0) then buffer_append_string(label, "Adsız belge") else ()
  var cbuf: Buf = buf_make(16)
  val () = buffer_append_integer(cbuf, imax(0, match_cnt))
  val expanded = if ilt(row, buf_len(s.ixq)) then ine(buf_get(s.ixq, row), 1) else true
  val g = s.search_layout
  val hdr_h = imin(g.rowHeight, iadd(font_line_h(f), 10))
  val hdr_y = iadd(y, idiv(imax(0, isub(g.rowHeight, hdr_h)), 2))
  val is_sel = ieq(row, s.selected_search_row)
  val () = ui_cell(f, r, SEARCH_LEFT_PIXELS, hdr_y, isub(s.sidew, imul(2, SEARCH_LEFT_PIXELS)), hdr_h, 0, On,
    toggle_of(expanded), UI_ICON_NONE, buffer_c_string(label), buffer_c_string(cbuf), toggle_of(is_sel), Off)
  val () = buf_free(cbuf)
in
  buf_free(label)
end

fun draw_search_card_box(r: !Rend, cx: int, cy: int, cw: int, ch: int, sel: bool): void = let
  val bg = if sel then col_surface() else col_bg()
  val bcol = if sel then col_accent() else col_line()
in
  rend_rrect_ex(r, cx, cy, cw, ch, 6, 6, 6, 6, bg, bg, 1, bcol, 1)
end

fun draw_search_card_keyword(
  f: !Font, r: !Rend, kbuf: !Buf, klen: int, tx: int, ty1: int, tw: int, lh: int, mx: int, kw_w: int
): void =
  if igt(klen, 0) then let
    val () = rend_rrect(r, imax(tx, isub(mx, 2)), ty1, imin(tw, iadd(kw_w, 4)), lh, 3, col_rgba(234, 179, 8, 210))
  in
    seen_int(font_draw_buf(f, r, mx, ty1, kbuf, klen, col_rgba(18, 19, 22, 255)))
  end else ()

fun fit_keyword_end(f: !Font, r: !Rend, b: !Buf, st: int, en: int, mw: int, seg: &Buf >> _): int =
  if ige(st, en) then st
  else let
    val () = buffer_clear(seg)
    val () = buffer_append_range(seg, b, st, en)
    val slen = buf_len(seg)
  in
    iadd(st, ui_fit_str_bytes(f, r, buf_ptr(seg), slen, mw))
  end

fun draw_search_card_lines(
  f: !Font, r: !Rend, norm: !Buf, m_st: int, m_en: int,
  tx: int, cy: int, tw: int, text_lh: int, seg: &Buf >> _
): void = let
  val kfit = fit_keyword_end(f, r, norm, m_st, m_en, tw, seg)
  val kw_w = slice_width(f, r, norm, m_st, kfit, seg)
  val mx = iadd(tx, idiv(imax(0, isub(tw, kw_w)), 2))
  val ty0 = iadd(cy, 4)
  val ty1 = iadd(ty0, text_lh)
  val ty2 = iadd(ty1, text_lh)
  val () = draw_match_pre(f, r, norm, m_st, tx, ty0, ty1, tw, mx, seg)
  val () = draw_match_post(f, r, norm, m_en, buf_len(norm), tx, ty1, ty2, tw, iadd(mx, kw_w), seg)
  val () = buffer_clear(seg)
  val () = if ilt(m_st, kfit) then buffer_append_range(seg, norm, m_st, kfit) else ()
  val klen = buf_len(seg)
in
  draw_search_card_keyword(f, r, seg, klen, tx, ty1, tw, text_lh, mx, kw_w)
end

fun draw_search_match(f: !Font, r: !Rend, s: &App_record, row: int, y: int): void = let
  val at = imul(row, SEARCH_RESULT_WORDS)
  val off = buf_get32(s.hmeta, iadd(at, SEARCH_RESULT_TEXT))
  val length = buf_get32(s.hmeta, iadd(at, SEARCH_RESULT_LENGTH))
  val match = imin(length, imax(0, buf_get32(s.hmeta, iadd(at, SEARCH_RESULT_MATCH))))
  val count = imin(isub(length, match), imax(0, buf_get32(s.hmeta, iadd(at, SEARCH_RESULT_MATCH_LENGTH))))
  val g = s.search_layout
  val cx = iadd(SEARCH_LEFT_PIXELS, 4)
  val cy = iadd(y, 2)
  val cw = imax(48, isub(s.sidew, iadd(imul(2, SEARCH_LEFT_PIXELS), 8)))
  val ch = imax(16, isub(g.rowHeight, 4))
  val () = draw_search_card_box(r, cx, cy, cw, ch, ieq(row, s.selected_search_row))
  val text_lh = imin(imax(1, font_line_h(f)), idiv(imax(12, isub(ch, 8)), 3))
  var norm: Buf = buf_make(imax(16, iadd(length, 8)))
  var seg: Buf = buf_make(imax(16, iadd(length, 8)))
  var m_st: int = 0
  var m_en: int = 0
  val () = normalize_snippet(s.hits, off, length, match, count, norm, m_st, m_en)
  val () = draw_search_card_lines(f, r, norm, m_st, m_en, iadd(cx, 8), cy, imax(24, isub(cw, 16)), text_lh, seg)
  val () = buf_free(seg)
in
  buf_free(norm)
end
fun draw_search_row(f: !Font,r: !Rend,s: &App_record,row: int,y: int): void = let
  val ()=rend_clip_push(r,SEARCH_LEFT_PIXELS,y,isub(s.sidew,imul(2,SEARCH_LEFT_PIXELS)),s.search_layout.rowHeight)
  val ()=if search_row_is_header(s.hmeta,row) then draw_search_header(f,r,s,row,y) else draw_search_match(f,r,s,row,y)
in rend_clip_pop(r) end
fun search_rows{n:nat} .<n>. (left: int(n),f: !Font,r: !Rend,s: &App_record,index: int): void =
  if left = 0 then () else let
    val source=search_source_row(s.hmeta,s.ixq,iadd(s.hscroll,index))
    val y=iadd(s.search_layout.resultsTop,imul(index,s.search_layout.rowHeight))
    val ()=if ige(source,0) then draw_search_row(f,r,s,source,y) else ()
  in if ilt(source,0) then () else search_rows(left-1,f,r,s,iadd(index,1)) end

fun search_status_text(state: int, hn: int, qlen: int, scope: int): string =
  if ieq(qlen, 0) then ""
  else if ieq(state, SEARCH_RUNNING) then "Aranıyor..."
  else if ieq(state, SEARCH_UNAVAILABLE) then "Arama başlatılamadı"
  else if ieq(state, SEARCH_PARTIAL) then "Kısmi sonuç (sınır/okuma)"
  else if ieq(hn, 0) then "Sonuç bulunamadı"
  else if ieq(scope, 1) then "Belge içi (Enter: sonraki)"
  else "Arama tamamlandı"

fun draw_sidebar_search(f: !Font, r: !Rend, s: &App_record, sidew: int,h: int): void = let
  val g=search_geometry_ex(font_document_line_height(f,font_line_h(f)),s.tb_h,sidew,h)
  val ()=s.search_layout := g
  val total=search_visible_count(s.hmeta,s.ixq)
  val ()=s.hscroll := imin(s.hscroll,imax(0,isub(total,g.rows)))
  val qn = buf_len(s.query)
  val in_bar = ige(s.hovery, g.buttonTop) andalso ilt(s.hovery, iadd(g.buttonTop, g.buttonHeight))
  val hov_seg = if not(in_bar) then ~1 else if ige(s.hoverx, SEARCH_LEFT_PIXELS) andalso ilt(s.hoverx, g.secondX) then 0
    else if ige(s.hoverx, g.secondX) andalso ilt(s.hoverx, isub(sidew, SEARCH_LEFT_PIXELS)) then 1 else ~1
  val () = ui_segmented_pair(f, r, SEARCH_LEFT_PIXELS, g.buttonTop, isub(sidew, imul(2, SEARCH_LEFT_PIXELS)), g.buttonHeight, "Kasa", "Belge", toggle_of(ieq(s.scope, SEARCH_SCOPE_DOCUMENT)), hov_seg)
  val ph = (if ieq(s.scope, 1) then "Belgede ara (Enter: bul)..." else "Kasada ara..."): string
  val () = ui_search_input_draw(f, r, SEARCH_LEFT_PIXELS,g.queryTop,isub(sidew,imul(2,SEARCH_LEFT_PIXELS)),g.queryHeight,s.query,qn,qn,s.qfocus,ph)
  val st = search_status_text(s.search_state, s.hn, qn, s.scope)
  val () = if igt(c_strlen(st), 0) then draw_s(f,r,SEARCH_LEFT_PIXELS,g.statusTop,st,col_muted()) else ()
in
  search_rows(airlock_nat(imax(0,g.rows)),f,r,s,0)
end

fun draw_inline_guides_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), r: !Rend, y: int, h: int, d: int, depth: int
): void =
  if recursion_fuel_available(recfuel) then (
    if ilt(d, depth) then let
      val gx = iadd(18, imul(d, UI_TREE_INDENT_PIXELS))
      val () = rend_rect(r, gx, y, 1, h, col_tree_guide())
    in
      draw_inline_guides_m(recfuel - 1, r, y, h, iadd(d, 1), depth)
    end else ()
  ) else ()

fun draw_tree_row(f: !Font, r: !Rend, s: &App_record, source: int, viewrow: int, sidew: int): void = let
  val depth = meta_depth(s.tmeta, source)
  val mark = meta_dir(s.tmeta, source)
  val off = meta_text_off(s.tmeta, source)
  val n = meta_text_len(s.tmeta, source)
  val is_sel = ieq(s.sel, source)
  val row_h = tree_row_h(s.fontpx)
  val row_y = iadd(tree_top_y_of(s), imul(viewrow, row_h))
in
  if is_prompt_rename(s.prompt) andalso is_sel then let
    val () = rend_rrect(r, 6, iadd(row_y, 2), imax(1, isub(sidew, 12)), imax(1, isub(row_h, 4)), 6, col_accent_soft())
    val () = if igt(depth, 0) then draw_inline_guides_m(airlock_nat(MAX_REC_FUEL), r, row_y, row_h, 0, depth) else ()
    val exp_x = iadd(14, imul(depth, UI_TREE_INDENT_PIXELS))
    val () = if is_dir_mark(mark, DirYes) then
      ui_expander(f, r, exp_x, iadd(row_y, idiv(isub(row_h, 8), 2)), toggle_of(tree_row_is_open(s, source)), Off)
    else ()
    val edit_x = iadd(22, imul(depth, UI_TREE_INDENT_PIXELS))
    val edit_w = imax(48, isub(isub(sidew, 10), edit_x))
    val cur_n = buf_len(s.promptb)
  in
    ui_line_edit_draw(f, r, edit_x, iadd(row_y, 3), edit_w, imax(20, isub(row_h, 6)), s.promptb, cur_n, cur_n, On, "")
  end else let
    var base = buf_make(DRAW_TREE_ROW_BASE_INITIAL_BYTES)
    val () = buffer_append_range(base, s.tree, off, iadd(off, n))
    val () = base_name(base, s.scratch)
    val () = if is_dir_mark(mark, DirNo) then strip_md_ext(s.scratch) else ()
    val icon = UI_ICON_NONE
    val is_hov = ige(s.hoverx, 6) andalso ilt(s.hoverx, isub(sidew, 6)) andalso ige(s.hovery, row_y) andalso ilt(s.hovery, iadd(row_y, row_h))
    val () = ui_cell(f, r, 6, row_y, isub(sidew, 12), row_h, depth,
      toggle_of(is_dir_mark(mark, DirYes)), toggle_of(tree_row_is_open(s, source)),
      icon, buffer_c_string(s.scratch), "", toggle_of(is_sel), toggle_of(is_hov))
    val flashing = ieq(source, s.tree_flash_row) andalso s.tree_flash_until_ns > 0L andalso mono_ns() < s.tree_flash_until_ns
    val () = if flashing then
      rend_rect(r, 6, iadd(row_y, 1), isub(sidew, 12), imax(1, isub(row_h, 2)), col_rgba(234, 179, 8, 95))
    else ()
  in
    buf_free(base)
  end
end

extern fun file_rows_fuel_exhausted(f: !Font, r: !Rend, s: &App_record, viewrow: int, limit: int, sidew: int): void = "mac#anth_die_void"

fun file_rows_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), f: !Font, r: !Rend, s: &App_record, viewrow: int, limit: int, sidew: int
): void =
  if recursion_fuel_available(recfuel) then (
    if ilt(viewrow, limit) then let
      val source = tree_source_for_view(s, iadd(s.treescroll, viewrow))
    in
      if ige(source, 0) then (
        draw_tree_row(f, r, s, source, viewrow, sidew);
        file_rows_with_fuel(recfuel - 1, f, r, s, iadd(viewrow, 1), limit, sidew)
      ) else ()
    end else ()
  ) else file_rows_fuel_exhausted(f, r, s, viewrow, limit, sidew)

fun draw_sidebar_files(f: !Font, r: !Rend, s: &App_record, sidew: int, h: int): void = let
  val top_y = tree_top_y_of(s)
  val visible_h = imax(0, isub(h, top_y))
  val rows = imax(1, idiv(visible_h, tree_row_h(s.fontpx)))
  val total = tree_visible_count(s)
  val () = file_rows_with_fuel(airlock_nat(MAX_REC_FUEL), f, r, s, 0, rows, sidew)
  val shover = ige(s.hoverx, isub(sidew, UI_SCROLLBAR_HIT_WIDTH)) andalso ilt(s.hoverx, sidew) andalso ige(s.hovery, top_y)
  val sdrag = is_drag_tree_scroll(s.drag)
in
  if igt(total, rows) then ui_scroll_bar(r, isub(sidew, 8), top_y, 8, visible_h,
    Vertical, total, rows, s.treescroll, toggle_of(shover), toggle_of(sdrag)) else ()
end

fun draw_config_vault_section(f: !Font, r: !Rend, s: &App_record, lay: CfgLayout): void = let
  val cw = imax(40, isub(s.sidew, 24))
  val () = ui_draw_fitted_text(f, r, 12, lay.vault_lbl_y, cw, lay.lh, 0, 0, Off, "Kasa Konumu", col_muted())
  val vn = buf_len(s.vault)
  val () =
    if igt(vn, 0) then ui_draw_fitted_buf(f, r, 12, lay.vault_path_y, cw, lay.lh, 0, 0, Off, s.vault, col_text())
    else ui_draw_fitted_text(f, r, 12, lay.vault_path_y, cw, lay.lh, 0, 0, Off, "(Seçilmedi)", col_text())
  val body_y = doc_top_y_of(s)
  val hov = ige(s.hoverx, 12) andalso ilt(s.hoverx, iadd(12, lay.vault_btn_w))
    andalso ige(s.hovery, body_y) andalso ige(s.hovery, lay.vault_btn_y) andalso ilt(s.hovery, iadd(lay.vault_btn_y, lay.btn_h))
in
  ui_button(f, r, 12, lay.vault_btn_y, lay.vault_btn_w, lay.btn_h, "Kasayı Değiştir", toggle_of(hov), On)
end

macdef UI_CFG_SLIDER_X = 12
macdef UI_CFG_SLIDER_TRACK_H = 6
macdef UI_CFG_SLIDER_HIT_PAD = 8
macdef UI_CFG_SLIDER_HIT_H = 24
macdef UI_CFG_SLIDER_KNOB_W = 14
macdef UI_CFG_SLIDER_KNOB_H = 14

fun slider_track_w(sidew: int): int = imax(80, isub(sidew, 24))

fun slider_px_from_x(x: int, sidew: int): int = let
  val tw = slider_track_w(sidew)
  val rel = imax(0, imin(tw, isub(x, UI_CFG_SLIDER_X)))
  val span = isub(UI_FONT_PX_MAX, UI_FONT_PX_MIN)
in
  iadd(UI_FONT_PX_MIN, idiv(iadd(imul(rel, span), idiv(tw, 2)), tw))
end

fun slider_hit(x: int, y: int, sidew: int, sy: int): bool = let
  val tw = slider_track_w(sidew)
  val top = isub(sy, UI_CFG_SLIDER_HIT_PAD)
in
  ige(x, UI_CFG_SLIDER_X) andalso ile(x, iadd(UI_CFG_SLIDER_X, tw))
    andalso ige(y, top) andalso ilt(y, iadd(top, UI_CFG_SLIDER_HIT_H))
end

fun draw_slider_header(f: !Font, r: !Rend, sidew: int, y: int, lh: int, title: string, px: int): void = let
  var b = buf_make(16)
  val () = buffer_append_integer(b, px)
  val () = buffer_append_string(b, " px")
  val n = buf_len(b)
  val bw = iadd(font_width_buf(f, r, b, n), 14)
  val bx = imax(UI_CFG_SLIDER_X, isub(sidew, iadd(bw, 12)))
  val lw = imax(0, isub(bx, iadd(UI_CFG_SLIDER_X, 6)))
  val () = ui_draw_fitted_text(f, r, UI_CFG_SLIDER_X, y, lw, lh, 0, 0, Off, title, col_text())
  val () = ui_badge(f, r, bx, isub(y, 2), buffer_c_string(b), col_bar(), col_accent_hi())
in
  buf_free(b)
end

fun draw_px_slider_track(r: !Rend, sx: int, sy: int, tw: int, px: int, active: Toggle): void = let
  val clamped = imax(UI_FONT_PX_MIN, imin(UI_FONT_PX_MAX, px))
  val span = isub(UI_FONT_PX_MAX, UI_FONT_PX_MIN)
  val fill_w = idiv(imul(isub(clamped, UI_FONT_PX_MIN), tw), span)
  val knob_x = imax(sx, imin(isub(iadd(sx, tw), UI_CFG_SLIDER_KNOB_W), isub(iadd(sx, fill_w), idiv(UI_CFG_SLIDER_KNOB_W, 2))))
  val knob_y = isub(sy, 4)
  val () = rend_rrect_ex(r, sx, sy, tw, UI_CFG_SLIDER_TRACK_H, 3, 3, 3, 3, col_bar(), col_bar(), 1, col_line(), 1)
  val () = if igt(fill_w, 0) then rend_rrect(r, sx, sy, fill_w, UI_CFG_SLIDER_TRACK_H, 3, col_accent()) else ()
  val kc = if is_on(active) then col_white() else col_heading()
in
  rend_rrect_ex(r, knob_x, knob_y, UI_CFG_SLIDER_KNOB_W, UI_CFG_SLIDER_KNOB_H, 7, 7, 7, 7, kc, kc, 1, col_accent_hi(), 1)
end

fun draw_config_font_sliders(f: !Font, r: !Rend, s: &App_record, lay: CfgLayout): void = let
  val tw = slider_track_w(s.sidew)
  val () = draw_slider_header(f, r, s.sidew, lay.ed_lbl_y, lay.lh, "Editör Yazı Boyutu", s.fontpx)
  val () = draw_px_slider_track(r, UI_CFG_SLIDER_X, lay.ed_sldr_y, tw, s.fontpx, toggle_of(is_drag_editor_font_slider(s.drag)))
  val () = draw_slider_header(f, r, s.sidew, lay.doc_lbl_y, lay.lh, "Dosya İçeriği Boyutu", s.doc_fontpx)
in
  draw_px_slider_track(r, UI_CFG_SLIDER_X, lay.doc_sldr_y, tw, s.doc_fontpx, toggle_of(is_drag_doc_font_slider(s.drag)))
end

fun draw_config_font_row(f: !Font, r: !Rend, s: &App_record, lay: CfgLayout, fi: int, body_y: int, h: int): void = let
  val fy = iadd(lay.font_list_y, imul(fi, lay.frow_h))
in
  if ile(iadd(fy, lay.frow_h), body_y) orelse ige(fy, h) then ()
  else let
    var pbuf = buf_make(DRAW_CONFIG_FONT_ROW_PBUF_INITIAL_BYTES)
    var nbuf = buf_make(DRAW_CONFIG_FONT_ROW_NBUF_INITIAL_BYTES)
    val poff = buf_get32(s.fmeta, imul(fi, 4))
    val plen = buf_get32(s.fmeta, iadd(imul(fi, 4), 1))
    val noff = buf_get32(s.fmeta, iadd(imul(fi, 4), 2))
    val nlen = buf_get32(s.fmeta, iadd(imul(fi, 4), 3))
    val () = buffer_append_range(pbuf, s.fpaths, poff, iadd(poff, plen))
    val () = buffer_append_range(nbuf, s.fnames, noff, iadd(noff, nlen))
    val is_sel = ieq(c_strcmp(buffer_c_string(pbuf), buffer_c_string(s.font_path)), 0)
    val f_icon = if is_sel then UI_ICON_CHECK else UI_ICON_NONE
    val rw = imax(40, isub(s.sidew, 20))
    val is_hov = ige(s.hoverx, 10) andalso ilt(s.hoverx, isub(s.sidew, 10))
      andalso ige(s.hovery, body_y) andalso ilt(s.hovery, h)
      andalso ige(s.hovery, fy) andalso ilt(s.hovery, iadd(fy, lay.frow_h))
    val () = ui_cell(f, r, 10, fy, rw, lay.frow_h, 0, Off, Off, f_icon, buffer_c_string(nbuf), "", toggle_of(is_sel), toggle_of(is_hov))
    val () = buf_free(pbuf)
  in
    buf_free(nbuf)
  end
end

extern fun font_rows_fuel_exhausted(f: !Font, r: !Rend, s: &App_record, lay: CfgLayout, fi: int, fcnt: int, body_y: int, h: int): void = "mac#anth_die_void"

fun font_rows_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, r: !Rend, s: &App_record, lay: CfgLayout, fi: int, fcnt: int, body_y: int, h: int): void =
  if recursion_fuel_available(recfuel) then (
    if ilt(fi, fcnt) then let
      val () = draw_config_font_row(f, r, s, lay, fi, body_y, h)
    in
      font_rows_with_fuel(recfuel - 1, f, r, s, lay, iadd(fi, 1), fcnt, body_y, h)
    end else ()
  ) else font_rows_fuel_exhausted(f, r, s, lay, fi, fcnt, body_y, h)

fun draw_keymap_line(f: !Font, r: !Rend, sidew: int, y: int, kb_rh: int, line: !Buf): int = let
  val n = buf_len(line)
  val bw = imax(40, isub(sidew, 24))
  val bh = imax(16, isub(kb_rh, 2))
in
  if igt(n, 0) then (
    rend_rrect(r, 12, y, bw, bh, 5, col_bar());
    ui_draw_fitted_buf(f, r, 12, y, bw, bh, 8, 8, Off, line, col_muted());
    1
  ) else 0
end

fun draw_keymap_rows_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), f: !Font, r: !Rend, s: &App_record,
  idx: int, total: int, y: int, step_y: int, shown: int
): void =
  if recursion_fuel_available(recfuel) then (
    if ilt(idx, total) andalso ilt(shown, UI_KEYMAP_MAX_SHOW) then let
      var line = buf_make(64)
      val () = keymap_format_entry(s.keymap, idx, line)
      val drew = draw_keymap_line(f, r, s.sidew, y, step_y, line)
      val () = buf_free(line)
    in
      draw_keymap_rows_m(recfuel - 1, f, r, s, iadd(idx, 1), total,
        if igt(drew, 0) then iadd(y, step_y) else y,
        step_y, iadd(shown, drew))
    end else ()
  ) else ()

fun draw_sidebar_keybindings(f: !Font, r: !Rend, s: &App_record, lay: CfgLayout): void = let
  val body_y = doc_top_y_of(s)
  val lw = imax(0, isub(lay.kb_btn_x, 18))
  val () = ui_draw_fitted_text(f, r, 12, lay.kb_y, lw, lay.btn_h, 0, 0, Off, "Klavye Kısayolları", col_heading())
  val hov = ige(s.hoverx, lay.kb_btn_x) andalso ilt(s.hoverx, iadd(lay.kb_btn_x, lay.kb_btn_w))
    andalso ige(s.hovery, body_y) andalso ige(s.hovery, lay.kb_y) andalso ilt(s.hovery, iadd(lay.kb_y, lay.btn_h))
  val () = ui_button(f, r, lay.kb_btn_x, lay.kb_y, lay.kb_btn_w, lay.btn_h, "Yenile", toggle_of(hov), Off)
  val total = keymap_count(s.keymap)
  val kb_rh = imax(24, iadd(lay.lh, 6))
in
  draw_keymap_rows_m(airlock_nat(MAX_REC_FUEL), f, r, s, 0, total, lay.kb_rows_y, kb_rh, 0)
end

fun sidebar_config_content_h(s: &App_record, lh: int): int = let
  val lay0 = config_layout_step(0, imax(18, lh), s.fontpx, s.sidew, s.fcnt)
  val shown = imin(keymap_count(s.keymap), UI_KEYMAP_MAX_SHOW)
  val kb_rh = imax(24, iadd(lay0.lh, 6))
in
  iadd(12, iadd(lay0.kb_rows_y, iadd(imul(shown, kb_rh), 16)))
end

fun sidebar_config_max_scroll(s: &App_record, h: int): int = let
  val body_h = imax(1, isub(h, doc_top_y_of(s)))
  val ch = sidebar_config_content_h(s, imax(18, s.fontpx))
in
  imax(0, isub(ch, body_h))
end

fun draw_sidebar_config(f: !Font, r: !Rend, s: &App_record, h: int): void = let
  val body_y = doc_top_y_of(s)
  val body_h = imax(1, isub(h, body_y))
  val lay = config_layout(f, s)
  val () = rend_clip_push(r, 0, body_y, imax(1, isub(s.sidew, 1)), body_h)
  val () = draw_config_vault_section(f, r, s, lay)
  val () = draw_config_font_sliders(f, r, s, lay)
  val () = ui_draw_fitted_text(f, r, UI_CFG_SLIDER_X, lay.eng_title_y, imax(40, isub(s.sidew, 24)), lay.lh, 0, 0, Off, ui_text_engine_title(f), col_muted())
  val () = font_rows_with_fuel(airlock_nat(MAX_REC_FUEL), f, r, s, lay, 0, s.fcnt, body_y, h)
  val () = draw_sidebar_keybindings(f, r, s, lay)
  val () = rend_clip_pop(r)
  val ch = sidebar_config_content_h(s, font_line_h(f))
in
  if igt(ch, body_h) then
    ui_scroll_bar(r, isub(s.sidew, 8), body_y, 7, body_h, Vertical, ch, body_h, s.settings_scroll, Off, Off)
  else ()
end

fun draw_side_frame(r: !Rend, s: &App_record, h: int): void = let
  val body_h = isub(h, s.tb_h)
  val () = rend_clip_push(r, 0, s.tb_h, s.sidew, body_h)
  val () = rend_rect(r, 0, s.tb_h, s.sidew, body_h, col_side())
  val () = if is_side_search(s.side) then () else ui_divider(r, 0, doc_top_y_of(s), s.sidew, Horizontal)
  val active_div = is_drag_split(s.drag) orelse (not(is_drag_file(s.drag)) andalso side_divider_hovered(s))
in
  if active_div then rend_rect(r, isub(s.sidew, 3), s.tb_h, 3, body_h, col_accent())
  else ui_divider(r, isub(s.sidew, 1), s.tb_h, body_h, Vertical)
end

fun side_title(sd: Sidebar): string =
  if is_side_files(sd) then "Gezgin"
  else if is_side_search(sd) then "Genel Arama"
  else "Ayarlar"

fun draw_side_title(f: !Font, r: !Rend, s: &App_record): void =
  ui_draw_fitted_text(f, r, 0, s.tb_h, s.sidew, s.hdr_h, 12, 12, Off, side_title(s.side), col_heading())
