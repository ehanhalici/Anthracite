fun tree_expander_hit(s: &App_record, source: int, x: int): bool =
  if ilt(source, 0) then false
  else let
    val depth = meta_depth(s.tmeta, source)
    val expander_x = iadd(6, imul(depth, UI_TREE_INDENT_PIXELS))
  in
    is_dir_mark(meta_dir(s.tmeta, source), DirYes)
      andalso ige(x, expander_x) andalso ilt(x, iadd(expander_x, 16))
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
fun draw_search_header(f: !Font,r: !Rend,s: &App_record,row: int,y: int): void = let
  val at=imul(row,SEARCH_RESULT_WORDS) val off=buf_get32(s.hmeta,iadd(at,SEARCH_RESULT_TEXT))
  val length=buf_get32(s.hmeta,iadd(at,SEARCH_RESULT_LENGTH)) val root=buf_len(s.vault)
  val relative=igt(length,root) andalso search_relative_prefix(airlock_nat(imax(0,root)),s.hits,off,s.vault,0)
  val skip=if relative then iadd(root,1) else 0 var label: Buf=buf_make(0)
  val ()=buffer_append_range(label,s.hits,iadd(off,skip),iadd(off,length))
  val ()=if ieq(length,0) then buffer_append_string(label,"Adsız belge") else ()
  val expanded=if ilt(row,buf_len(s.ixq)) then ine(buf_get(s.ixq,row),1) else true
  val g=s.search_layout
  val ()=ui_cell(f,r,SEARCH_LEFT_PIXELS,y,isub(s.sidew,imul(2,SEARCH_LEFT_PIXELS)),g.rowHeight,0,On,
    toggle_of(expanded),UI_ICON_FILE,buffer_c_string(label),"",Off,Off)
in buf_free(label) end
fun draw_search_match(f: !Font,r: !Rend,s: &App_record,row: int,y: int): void = let
  val at=imul(row,SEARCH_RESULT_WORDS) val off=buf_get32(s.hmeta,iadd(at,SEARCH_RESULT_TEXT))
  val length=buf_get32(s.hmeta,iadd(at,SEARCH_RESULT_LENGTH))
  val match=imin(length,imax(0,buf_get32(s.hmeta,iadd(at,SEARCH_RESULT_MATCH))))
  val count=imin(isub(length,match),imax(0,buf_get32(s.hmeta,iadd(at,SEARCH_RESULT_MATCH_LENGTH))))
  val ()=if ieq(row,s.selected_search_row) then rend_rect(r,SEARCH_LEFT_PIXELS,y,
    isub(s.sidew,imul(2,SEARCH_LEFT_PIXELS)),s.search_layout.rowHeight,col_sel()) else ()
  val first=hit_text(s.hits,off,match,f,r,SEARCH_CHILD_INDENT_PIXELS,y,col_muted())
  val second=hit_text(s.hits,iadd(off,match),count,f,r,iadd(SEARCH_CHILD_INDENT_PIXELS,first),y,col_hightxt())
in seen_int(hit_text(s.hits,iadd(off,iadd(match,count)),isub(length,iadd(match,count)),f,r,
  iadd(SEARCH_CHILD_INDENT_PIXELS,iadd(first,second)),y,col_muted())) end
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
  val () = ui_button(f, r, SEARCH_LEFT_PIXELS,g.buttonTop,g.buttonWidth,g.buttonHeight,"Kasa",Off,toggle_of(ieq(s.scope,SEARCH_SCOPE_VAULT)))
  val () = ui_button(f, r, g.secondX,g.secondY,g.buttonWidth,g.buttonHeight,"Belge",Off,toggle_of(ieq(s.scope,SEARCH_SCOPE_DOCUMENT)))
  val ph = (if ieq(s.scope, 1) then "Belgede ara (Enter: bul)..." else "Kasada ara..."): string
  val () = ui_line_edit_draw(f, r, SEARCH_LEFT_PIXELS,g.queryTop,isub(sidew,imul(2,SEARCH_LEFT_PIXELS)),g.queryHeight,s.query,qn,qn,s.qfocus,ph)
  val st = search_status_text(s.search_state, s.hn, qn, s.scope)
  val () = if igt(c_strlen(st), 0) then draw_s(f,r,SEARCH_LEFT_PIXELS,g.statusTop,st,col_muted()) else ()
in
  search_rows(airlock_nat(imax(0,g.rows)),f,r,s,0)
end

fun draw_tree_row(f: !Font, r: !Rend, s: &App_record, source: int, viewrow: int, sidew: int): void = let
  val depth = meta_depth(s.tmeta, source)
  val mark = meta_dir(s.tmeta, source)
  val off = meta_text_off(s.tmeta, source)
  val n = meta_text_len(s.tmeta, source)
  var base = buf_make(DRAW_TREE_ROW_BASE_INITIAL_BYTES)
  val () = buffer_append_range(base, s.tree, off, iadd(off, n))
  val () = base_name(base, s.scratch)
  val () = if is_dir_mark(mark, DirNo) then strip_md_ext(s.scratch) else ()
  val icon = if is_dir_mark(mark, DirYes) then UI_ICON_FOLDER else UI_ICON_FILE
  val is_sel = ieq(s.sel, source)
  val row_h = tree_row_h(s.fontpx)
  val row_y = iadd(tree_top_y_of(s), imul(viewrow, row_h))
  val is_hov = ige(s.hoverx, 6) andalso ilt(s.hoverx, isub(sidew, 6)) andalso ige(s.hovery, row_y) andalso ilt(s.hovery, iadd(row_y, row_h))
  val () = ui_cell(f, r, 6, row_y, isub(sidew, 12), row_h, depth,
    toggle_of(is_dir_mark(mark, DirYes)), toggle_of(tree_row_is_open(s, source)),
    icon, buffer_c_string(s.scratch), "", toggle_of(is_sel), toggle_of(is_hov))
  val flashing = ieq(source, s.tree_flash_row) andalso s.tree_flash_until_ns > 0L andalso mono_ns() < s.tree_flash_until_ns
  val () = if flashing then
    rend_rect(r, 6, iadd(row_y, 1), isub(sidew, 12), imax(1, isub(row_h, 2)), col_rgba(234, 179, 8, 95))
  else ()
  val () = buf_free(base)
in
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
  val () = draw_s(f, r, 12, lay.vault_lbl_y, "Kasa", col_muted())
  val vn = buf_len(s.vault)
  val () =
    if igt(vn, 0) then seen_int(font_draw_buf(f, r, 12, lay.vault_path_y, s.vault, imin(vn, 28), col_text()))
    else seen_int(font_draw(f, r, 12, lay.vault_path_y, c_str_ptr("(Secilmedi)"), 10, col_text()))
  val () = ui_button(f, r, 12, lay.vault_btn_y, lay.vault_btn_w, lay.btn_h, "Kasayi Degistir", Off, Off)
in
end

macdef UI_CFG_SLIDER_X = 12
macdef UI_CFG_SLIDER_TRACK_H = 6
macdef UI_CFG_SLIDER_HIT_PAD = 6
macdef UI_CFG_SLIDER_HIT_H = 22
macdef UI_CFG_SLIDER_KNOB_W = 10
macdef UI_CFG_SLIDER_KNOB_H = 16

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

fun draw_px_badge(f: !Font, r: !Rend, sidew: int, y: int, px: int): void = let
  var b = buf_make(16)
  val () = buffer_append_integer(b, px)
  val () = buffer_append_string(b, " px")
  val n = buf_len(b)
  val bw = iadd(font_width_buf(f, r, b, n), 12)
  val bx = imax(12, isub(sidew, iadd(bw, 12)))
  val () = ui_badge(f, r, bx, isub(y, 2), buffer_c_string(b), col_bar(), col_accent())
in
  buf_free(b)
end

fun draw_px_slider_track(r: !Rend, sx: int, sy: int, tw: int, px: int, active: Toggle): void = let
  val clamped = imax(UI_FONT_PX_MIN, imin(UI_FONT_PX_MAX, px))
  val span = isub(UI_FONT_PX_MAX, UI_FONT_PX_MIN)
  val fill_w = idiv(imul(isub(clamped, UI_FONT_PX_MIN), tw), span)
  val knob_x = imax(sx, imin(isub(iadd(sx, tw), UI_CFG_SLIDER_KNOB_W), isub(iadd(sx, fill_w), idiv(UI_CFG_SLIDER_KNOB_W, 2))))
  val knob_y = isub(sy, 5)
  val () = rend_rect(r, sx, sy, tw, UI_CFG_SLIDER_TRACK_H, col_bar())
  val () = ui_draw_border(r, sx, sy, tw, UI_CFG_SLIDER_TRACK_H, 1, col_line())
  val () = if igt(fill_w, 0) then rend_rect(r, sx, sy, fill_w, UI_CFG_SLIDER_TRACK_H, col_accent()) else ()
  val () = rend_rect(r, knob_x, knob_y, UI_CFG_SLIDER_KNOB_W, UI_CFG_SLIDER_KNOB_H, if is_on(active) then col_white() else col_heading())
in
  ui_draw_border(r, knob_x, knob_y, UI_CFG_SLIDER_KNOB_W, UI_CFG_SLIDER_KNOB_H, 1, col_accent())
end

fun draw_config_font_sliders(f: !Font, r: !Rend, s: &App_record, lay: CfgLayout): void = let
  val tw = slider_track_w(s.sidew)
  val () = draw_s(f, r, UI_CFG_SLIDER_X, lay.ed_lbl_y, "Editör Yazı Boyutu", col_text())
  val () = draw_px_badge(f, r, s.sidew, lay.ed_lbl_y, s.fontpx)
  val () = draw_px_slider_track(r, UI_CFG_SLIDER_X, lay.ed_sldr_y, tw, s.fontpx, toggle_of(is_drag_editor_font_slider(s.drag)))
  val () = draw_s(f, r, UI_CFG_SLIDER_X, lay.doc_lbl_y, "Dosya İçeriği Boyutu", col_text())
  val () = draw_px_badge(f, r, s.sidew, lay.doc_lbl_y, s.doc_fontpx)
in
  draw_px_slider_track(r, UI_CFG_SLIDER_X, lay.doc_sldr_y, tw, s.doc_fontpx, toggle_of(is_drag_doc_font_slider(s.drag)))
end

fun draw_config_font_row(f: !Font, r: !Rend, s: &App_record, lay: CfgLayout, fi: int): void = let
  var pbuf = buf_make(DRAW_CONFIG_FONT_ROW_PBUF_INITIAL_BYTES)
  var nbuf = buf_make(DRAW_CONFIG_FONT_ROW_NBUF_INITIAL_BYTES)
  val fy = iadd(lay.font_list_y, imul(fi, lay.frow_h))
  val poff = buf_get32(s.fmeta, imul(fi, 4))
  val plen = buf_get32(s.fmeta, iadd(imul(fi, 4), 1))
  val noff = buf_get32(s.fmeta, iadd(imul(fi, 4), 2))
  val nlen = buf_get32(s.fmeta, iadd(imul(fi, 4), 3))
  val () = buffer_append_range(pbuf, s.fpaths, poff, iadd(poff, plen))
  val () = buffer_append_range(nbuf, s.fnames, noff, iadd(noff, nlen))
  val is_sel = ieq(c_strcmp(buffer_c_string(pbuf), buffer_c_string(s.font_path)), 0)
  val f_icon = if is_sel then UI_ICON_CHECK else UI_ICON_CHECK_EMPTY
  val rw = imax(80, isub(s.sidew, 24))
  val is_hov = ige(s.hoverx, 12) andalso ilt(s.hoverx, isub(s.sidew, 12)) andalso ige(s.hovery, fy) andalso ilt(s.hovery, iadd(fy, lay.frow_h))
  val () = ui_cell(f, r, 12, fy, rw, lay.frow_h, 0, Off, Off, f_icon, buffer_c_string(nbuf), "", toggle_of(is_sel), toggle_of(is_hov))
  val () = buf_free(pbuf)
  val () = buf_free(nbuf)
in
end

extern fun font_rows_fuel_exhausted(f: !Font, r: !Rend, s: &App_record, lay: CfgLayout, fi: int, fcnt: int): void = "mac#anth_die_void"

fun font_rows_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, r: !Rend, s: &App_record, lay: CfgLayout, fi: int, fcnt: int): void =
  if recursion_fuel_available(recfuel) then (
    if ilt(fi, fcnt) andalso ilt(fi, 12) then let
      val () = draw_config_font_row(f, r, s, lay, fi)
    in
      font_rows_with_fuel(recfuel - 1, f, r, s, lay, iadd(fi, 1), fcnt)
    end else ()
  ) else font_rows_fuel_exhausted(f, r, s, lay, fi, fcnt)

fun draw_keymap_line(f: !Font, r: !Rend, y: int, line: !Buf): int = let
  val n = buf_len(line)
in
  if igt(n, 0) then (seen_int(font_draw_buf(f, r, 12, y, line, n, col_muted())); 1) else 0
end

fun draw_keymap_rows_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), f: !Font, r: !Rend, s: &App_record,
  idx: int, total: int, y: int, step_y: int, shown: int
): void =
  if recursion_fuel_available(recfuel) then (
    if ilt(idx, total) andalso ilt(shown, UI_KEYMAP_MAX_SHOW) then let
      var line = buf_make(64)
      val () = keymap_format_entry(s.keymap, idx, line)
      val drew = draw_keymap_line(f, r, y, line)
      val () = buf_free(line)
    in
      draw_keymap_rows_m(recfuel - 1, f, r, s, iadd(idx, 1), total,
        if igt(drew, 0) then iadd(y, step_y) else y,
        step_y, iadd(shown, drew))
    end else ()
  ) else ()

fun draw_sidebar_keybindings(f: !Font, r: !Rend, s: &App_record, lay: CfgLayout): void = let
  val () = draw_s(f, r, 12, lay.kb_y, "Klavye Kisayollari", col_text())
  val () = ui_button(f, r, lay.kb_btn_x, isub(lay.kb_y, 3), lay.kb_btn_w, lay.btn_h, "Yenile", Off, Off)
  val total = keymap_count(s.keymap)
in
  draw_keymap_rows_m(airlock_nat(MAX_REC_FUEL), f, r, s, 0, total, lay.kb_rows_y, lay.lh, 0)
end

fun draw_sidebar_config(f: !Font, r: !Rend, s: &App_record): void = let
  val lay = config_layout(f, s)
  val () = draw_config_vault_section(f, r, s, lay)
  val () = draw_config_font_sliders(f, r, s, lay)
  val () = draw_s(f, r, UI_CFG_SLIDER_X, lay.eng_title_y, ui_text_engine_title(f), col_text())
  val () = font_rows_with_fuel(airlock_nat(MAX_REC_FUEL), f, r, s, lay, 0, s.fcnt)
in
  draw_sidebar_keybindings(f, r, s, lay)
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
  if is_side_files(sd) then "Dosya Gezgini Aç/Kapa"
  else if is_side_search(sd) then "Genel Arama"
  else "Ayarlar"

fun draw_side_title(f: !Font, r: !Rend, s: &App_record): void = let
  val ty = iadd(s.tb_h, imax(0, idiv(isub(s.hdr_h, font_line_h(f)), 2)))
  val () = draw_s(f, r, 12, ty, side_title(s.side), col_heading())
in
end
