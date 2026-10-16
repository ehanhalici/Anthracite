fun tree_expander_hit(s: &App_record, source: int, x: int): bool =
  if ilt(source, 0) then false
  else let
    val depth = meta_depth(s.tmeta, source)
    val expander_x = iadd(6, imul(depth, 14))
  in
    is_dir_mark(meta_dir(s.tmeta, source), DirYes)
      andalso ige(x, expander_x) andalso ilt(x, iadd(expander_x, 14))
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

fun draw_search_plain_hit(f: !Font, r: !Rend, hits: !Buf, hmeta: !Buf, row: int, scroll: int): void = let
  val vrow = isub(row, scroll)
  val off = buf_get32(hmeta, iadd(imul(row, 4), 1))
  val n = buf_get32(hmeta, iadd(imul(row, 4), 2))
  val () = seen_int(hit_text(hits, off, n, f, r, 12, iadd(100, imul(vrow, 18)), col_accent()))
in
end

fun draw_search_marked_hit(f: !Font, r: !Rend, hits: !Buf, hmeta: !Buf, row: int, scroll: int): void = let
  val vrow = isub(row, scroll)
  val moff = buf_get32(hmeta, imul(row, 4))
  val off = buf_get32(hmeta, iadd(imul(row, 4), 1))
  val n = buf_get32(hmeta, iadd(imul(row, 4), 2))
  val ml = buf_get32(hmeta, iadd(imul(row, 4), 3))
  val y = iadd(100, imul(vrow, 18))
  val a1 = hit_text(hits, off, moff, f, r, 20, y, col_muted())
  val a2 = hit_text(hits, iadd(off, moff), ml, f, r, iadd(20, a1), y, col_hightxt())
  val () = seen_int(hit_text(hits, iadd(off, iadd(moff, ml)), isub(n, iadd(moff, ml)), f, r, iadd(20, iadd(a1, a2)), y, col_muted()))
in
end

fun draw_search_row(f: !Font, r: !Rend, hits: !Buf, hmeta: !Buf, row: int, scroll: int): void =
  if ilt(buf_get32(hmeta, imul(row, 4)), 0) then draw_search_plain_hit(f, r, hits, hmeta, row, scroll)
  else draw_search_marked_hit(f, r, hits, hmeta, row, scroll)

extern fun search_rows_fuel_exhausted(f: !Font, r: !Rend, s: &App_record, row: int, hn: int): void = "mac#anth_die_void"

fun search_rows_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, r: !Rend, s: &App_record, row: int, hn: int): void =
  if recfuel > 0 then (
    if ilt(row, hn) andalso ilt(isub(row, s.hscroll), 30) then let
      val () = if ige(row, s.hscroll) then draw_search_row(f, r, s.hits, s.hmeta, row, s.hscroll) else ()
    in
      search_rows_with_fuel(recfuel - 1, f, r, s, iadd(row, 1), hn)
    end else ()
  ) else search_rows_fuel_exhausted(f, r, s, row, hn)

fun search_status_text(state: int, hn: int, qlen: int, scope: int): string =
  if ieq(qlen, 0) then ""
  else if ieq(state, 1) then "Indeksleniyor..."
  else if ieq(state, 2) then "Kısmi sonuç..."
  else if ieq(hn, 0) andalso ieq(scope, 0) then "Sonuç bulunamadı"
  else if ieq(scope, 1) then "Belge içi (Enter: sonraki)"
  else "Arama tamamlandı"

fun draw_sidebar_search(f: !Font, r: !Rend, s: &App_record, sidew: int): void = let
  val qn = buf_len(s.query)
  val () = ui_button(f, r, 8, 40, 56, 22, "Kasa", Off, toggle_of(ieq(s.scope, 0)))
  val () = ui_button(f, r, 68, 40, 56, 22, "Belge", Off, toggle_of(ieq(s.scope, 1)))
  val ph = (if ieq(s.scope, 1) then "Belgede ara (Enter: bul)..." else "Kasada ara..."): string
  val () = ui_line_edit_draw(f, r, 8, 68, isub(sidew, 16), 24, s.query, qn, qn, s.qfocus, ph)
  val st = search_status_text(s.search_state, s.hn, qn, s.scope)
  val () = if igt(c_strlen(st), 0) then draw_s(f, r, 12, 96, st, col_muted()) else ()
in
  search_rows_with_fuel(airlock_nat(MAX_REC_FUEL), f, r, s, s.hscroll, s.hn)
end

fun draw_tree_row(f: !Font, r: !Rend, s: &App_record, source: int, viewrow: int, sidew: int): void = let
  val depth = meta_depth(s.tmeta, source)
  val mark = meta_dir(s.tmeta, source)
  val off = meta_text_off(s.tmeta, source)
  val n = meta_text_len(s.tmeta, source)
  var base = buf_make(DRAW_TREE_ROW_BASE_INITIAL_BYTES)
  val () = buffer_append_range(base, s.tree, off, iadd(off, n))
  val () = base_name(base, s.scratch)
  val icon = if is_dir_mark(mark, DirYes) then UI_ICON_FOLDER else UI_ICON_FILE
  val is_sel = ieq(s.sel, source)
  val row_y = iadd(72, imul(viewrow, UI_TREE_ROW_HEIGHT))
  val is_hov = ige(s.hoverx, 6) andalso ilt(s.hoverx, isub(sidew, 6)) andalso ige(s.hovery, row_y) andalso ilt(s.hovery, iadd(row_y, UI_TREE_ROW_HEIGHT))
  val () = ui_cell(f, r, 6, row_y, isub(sidew, 12), UI_TREE_ROW_HEIGHT, depth,
    toggle_of(is_dir_mark(mark, DirYes)), toggle_of(tree_row_is_open(s, source)),
    icon, buffer_c_string(s.scratch), "", toggle_of(is_sel), toggle_of(is_hov))
  val () = buf_free(base)
in
end

extern fun file_rows_fuel_exhausted(f: !Font, r: !Rend, s: &App_record, viewrow: int, limit: int, sidew: int): void = "mac#anth_die_void"

fun file_rows_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), f: !Font, r: !Rend, s: &App_record, viewrow: int, limit: int, sidew: int
): void =
  if recfuel > 0 then (
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
  val visible_h = imax(0, isub(h, 72))
  val rows = idiv(visible_h, UI_TREE_ROW_HEIGHT)
  val total = tree_visible_count(s)
  val () = file_rows_with_fuel(airlock_nat(MAX_REC_FUEL), f, r, s, 0, rows, sidew)
in
  if igt(total, rows) then ui_scroll_bar(r, isub(sidew, 7), 72, 6, visible_h,
    Vertical, total, rows, s.treescroll, Off, Off) else ()
end

fun draw_config_vault_section(f: !Font, r: !Rend, s: &App_record): void = let
  val () = draw_s(f, r, 12, 76, "Kasa", col_muted())
  val vn = buf_len(s.vault)
  val () =
    if igt(vn, 0) then seen_int(font_draw_buf(f, r, 12, 94, s.vault, imin(vn, 28), col_text()))
    else seen_int(font_draw(f, r, 12, 94, c_str_ptr("(Secilmedi)"), 10, col_text()))
  val () = ui_button(f, r, 12, 122, 150, 22, "Kasayi Degistir", Off, Off)
in
end

fun draw_config_font_size(f: !Font, r: !Rend, s: &App_record): void = let
  val () = draw_s(f, r, 12, 154, "Yazi Boyutu (tikla)", col_text())
  val pxlab = if ieq(s.fontpx, 18) then "18 px" else if ieq(s.fontpx, 24) then "24 px" else "28 px"
  val () = ui_badge(f, r, 190, 152, pxlab, col_bar(), col_accent())
in
end

fun draw_config_font_row(f: !Font, r: !Rend, s: &App_record, fi: int): void = let
  var pbuf = buf_make(DRAW_CONFIG_FONT_ROW_PBUF_INITIAL_BYTES)
  var nbuf = buf_make(DRAW_CONFIG_FONT_ROW_NBUF_INITIAL_BYTES)
  val fy = iadd(210, imul(fi, 22))
  val poff = buf_get32(s.fmeta, imul(fi, 4))
  val plen = buf_get32(s.fmeta, iadd(imul(fi, 4), 1))
  val noff = buf_get32(s.fmeta, iadd(imul(fi, 4), 2))
  val nlen = buf_get32(s.fmeta, iadd(imul(fi, 4), 3))
  val () = buffer_append_range(pbuf, s.fpaths, poff, iadd(poff, plen))
  val () = buffer_append_range(nbuf, s.fnames, noff, iadd(noff, nlen))
  val is_sel = ieq(c_strcmp(buffer_c_string(pbuf), buffer_c_string(s.font_path)), 0)
  val f_icon = if is_sel then UI_ICON_CHECK else UI_ICON_CHECK_EMPTY
  val is_hov = ige(s.hoverx, 12) andalso ilt(s.hoverx, 268) andalso ige(s.hovery, fy) andalso ilt(s.hovery, iadd(fy, 22))
  val () = ui_cell(f, r, 12, fy, 256, 22, 0, Off, Off, f_icon, buffer_c_string(nbuf), "", toggle_of(is_sel), toggle_of(is_hov))
  val () = buf_free(pbuf)
  val () = buf_free(nbuf)
in
end

extern fun font_rows_fuel_exhausted(f: !Font, r: !Rend, s: &App_record, fi: int, fcnt: int): void = "mac#anth_die_void"

fun font_rows_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, r: !Rend, s: &App_record, fi: int, fcnt: int): void =
  if recfuel > 0 then (
    if ilt(fi, fcnt) andalso ilt(fi, 12) then let
      val () = draw_config_font_row(f, r, s, fi)
    in
      font_rows_with_fuel(recfuel - 1, f, r, s, iadd(fi, 1), fcnt)
    end else ()
  ) else font_rows_fuel_exhausted(f, r, s, fi, fcnt)

fun draw_sidebar_config(f: !Font, r: !Rend, s: &App_record): void = let
  val () = draw_config_vault_section(f, r, s)
  val () = draw_config_font_size(f, r, s)
  val () = draw_s(f, r, 12, 186, ui_text_engine_title(f), col_text())
in
  font_rows_with_fuel(airlock_nat(MAX_REC_FUEL), f, r, s, 0, s.fcnt)
end

fun draw_side_frame(r: !Rend, sidew: int, h: int): void = let
  val body_h = isub(h, UI_TOPBAR_HEIGHT)
  val () = rend_scissor(r, 0, UI_TOPBAR_HEIGHT, sidew, body_h)
  val () = rend_rect(r, 0, UI_TOPBAR_HEIGHT, sidew, body_h, col_side())
  val () = ui_divider(r, 0, 64, sidew, Horizontal)
  val () = ui_divider(r, isub(sidew, 1), UI_TOPBAR_HEIGHT, body_h, Vertical)
in
end

fun side_title(sd: Sidebar): string =
  if is_side_files(sd) then "Dosya Gezgini Aç/Kapa"
  else if is_side_search(sd) then "Genel Arama"
  else "Ayarlar"

fun draw_side_title(f: !Font, r: !Rend, sd: Sidebar): void = let
  val () = draw_s(f, r, 12, 44, side_title(sd), col_heading())
in
end

