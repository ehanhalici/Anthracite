(* Kasa seçme penceresi: ekrana ortalı, tek sütunlu (üstte kasalar, altta yeni kasa).
   Yazı boyutu editörün yazı boyutudur; bütün dikey ölçüler satır yüksekliğinden
   türer. Uzun yollar satır sonunda kırılır (en çok VAULT_DIALOG_MAX_PATH_LINES satır,
   sığmayan kalan "…" ile biter). Çizim ve tıklama aynı geometriyi (vault_geo) kullanır. *)

macdef VAULT_DIALOG_MIN_WIDTH = 720
macdef VAULT_DIALOG_SCREEN_MARGIN = 24
macdef VAULT_DIALOG_PADDING = 32
macdef VAULT_DIALOG_RADIUS = 12
macdef VAULT_DIALOG_SECTION_GAP = 20
macdef VAULT_DIALOG_LINE_GAP = 6
macdef VAULT_DIALOG_ROW_PADDING = 10
macdef VAULT_DIALOG_ROW_GAP = 6
macdef VAULT_DIALOG_ROW_RADIUS = 8
macdef VAULT_DIALOG_ICON_SIZE = 16
macdef VAULT_DIALOG_TEXT_INSET = 44
macdef VAULT_DIALOG_CHECK_INSET = 36
macdef VAULT_DIALOG_MAX_PATH_LINES = 3
macdef VAULT_DIALOG_MAX_ROWS = 8
macdef VAULT_DIALOG_INPUT_PADDING = 9
macdef VAULT_DIALOG_BUTTON_WIDTH = 110
macdef VAULT_DIALOG_FIELD_GAP = 12
macdef VAULT_DIALOG_HINT_GAP = 14
macdef VAULT_DIALOG_CLOSE_SIZE = 28
macdef VAULT_DIALOG_WIDTH_PERCENT = 55
macdef VAULT_DIALOG_MAX_HEIGHT_PERCENT = 70

(* rows: görünen kasa sayısı; overflow: sığmayan kasa sayısı. *)
typedef VaultGeo = @{
  lh= int, mx= int, my= int, dw= int, dh= int, rows= int, overflow= int,
  list_x= int, list_w= int, rows_y= int, divider_y= int, label_y= int,
  input_y= int, input_w= int, hint_y= int
}

typedef VaultFit = @{rows= int, used= int}

fun vault_in_rect(x: int, y: int, rx: int, ry: int, rw: int, rh: int): bool =
  ige(x, rx) andalso ilt(x, iadd(rx, rw)) andalso ige(y, ry) andalso ilt(y, iadd(ry, rh))

fun vault_row_fill(s: &App_record, vi: int, name: &Buf >> _, path: &Buf >> _): void = let
  val poff = buf_get32(s.vmeta, imul(vi, 4))
  val plen = buf_get32(s.vmeta, iadd(imul(vi, 4), 1))
  val noff = buf_get32(s.vmeta, iadd(imul(vi, 4), 2))
  val nlen = buf_get32(s.vmeta, iadd(imul(vi, 4), 3))
  val () = buffer_append_range(path, s.vpaths, poff, iadd(poff, plen))
in
  buffer_append_range(name, s.vnames, noff, iadd(noff, nlen))
end

(* ---- Yol kırma ---- *)

fun vault_path_lines_loop {n:nat} .<n>. (
  left: int(n), f: !Font, r: !Rend, path: !Buf, plen: int, off: int, text_w: int, acc: int
): int =
  if left = 0 then acc
  else if ige(off, plen) then acc
  else let
    var tmp = buf_make(DRAW_VAULT_ITEM_PBUF_INITIAL_BYTES)
    val () = buffer_append_range(tmp, path, off, plen)
    val tn = buf_len(tmp)
    val fit = ui_fit_str_bytes(f, r, buf_ptr(tmp), tn, text_w)
    val () = buf_free(tmp)
  in
    vault_path_lines_loop(left - 1, f, r, path, plen, iadd(off, imax(1, fit)), text_w, iadd(acc, 1))
  end

fun vault_path_text_width(list_w: int): int =
  imax(40, isub(list_w, iadd(VAULT_DIALOG_TEXT_INSET, VAULT_DIALOG_CHECK_INSET)))

fun vault_row_lines(f: !Font, r: !Rend, s: &App_record, list_w: int, vi: int): int = let
  var nbuf = buf_make(DRAW_VAULT_ITEM_NBUF_INITIAL_BYTES)
  var pbuf = buf_make(DRAW_VAULT_ITEM_PBUF_INITIAL_BYTES)
  val () = vault_row_fill(s, vi, nbuf, pbuf)
  val plen = buf_len(pbuf)
  val lines = vault_path_lines_loop(airlock_nat(VAULT_DIALOG_MAX_PATH_LINES), f, r, pbuf, plen, 0, vault_path_text_width(list_w), 0)
  val () = buf_free(nbuf)
  val () = buf_free(pbuf)
in
  imax(1, lines)
end

fun vault_row_height(lh: int, lines: int): int =
  iadd(imul(VAULT_DIALOG_ROW_PADDING, 2), imul(lh, iadd(1, lines)))

(* ---- Geometri ---- *)

(* Görünen satırlar toplam yüksekliği avail'i aşana kadar eklenir. *)
fun vault_fit_rows {n:nat} .<n>. (
  left: int(n), f: !Font, r: !Rend, s: &App_record, list_w: int, lh: int, vi: int, used: int, avail: int
): VaultFit =
  if left = 0 then @{rows= vi, used= used}
  else if ige(vi, s.vcnt) then @{rows= vi, used= used}
  else let
    val hgt = iadd(vault_row_height(lh, vault_row_lines(f, r, s, list_w, vi)), VAULT_DIALOG_ROW_GAP)
  in
    if igt(iadd(used, hgt), avail) andalso igt(vi, 0) then @{rows= vi, used= used}
    else vault_fit_rows(left - 1, f, r, s, list_w, lh, iadd(vi, 1), iadd(used, hgt), avail)
  end

fun vault_fit_visible(f: !Font, r: !Rend, s: &App_record, list_w: int, lh: int, avail: int): VaultFit =
  if igt(s.vcnt, 0) then vault_fit_rows(airlock_nat(VAULT_DIALOG_MAX_ROWS), f, r, s, list_w, lh, 0, 0, avail)
  else @{rows= 0, used= iadd(lh, imul(VAULT_DIALOG_ROW_PADDING, 2))}

fun vault_geo(f: !Font, r: !Rend, s: &App_record, w: int, h: int): VaultGeo = let
  val lh = font_line_h(f)
  val pad = VAULT_DIALOG_PADDING
  val gap = VAULT_DIALOG_SECTION_GAP
  val dw = imin(isub(w, imul(VAULT_DIALOG_SCREEN_MARGIN, 2)), imax(VAULT_DIALOG_MIN_WIDTH, idiv(imul(w, VAULT_DIALOG_WIDTH_PERCENT), 100)))
  val list_w = isub(dw, imul(pad, 2))
  val input_h = iadd(lh, imul(VAULT_DIALOG_INPUT_PADDING, 2))
  val rows_y = iadd(iadd(pad, imul(lh, 2)), iadd(imul(gap, 2), iadd(lh, VAULT_DIALOG_LINE_GAP)))
  val below = iadd(iadd(imul(gap, 2), iadd(lh, VAULT_DIALOG_LINE_GAP)), iadd(iadd(input_h, VAULT_DIALOG_HINT_GAP), iadd(lh, pad)))
  val max_h = imin(isub(h, imul(VAULT_DIALOG_SCREEN_MARGIN, 2)), idiv(imul(h, VAULT_DIALOG_MAX_HEIGHT_PERCENT), 100))
  val avail = imax(vault_row_height(lh, 1), isub(isub(max_h, rows_y), below))
  val fit = vault_fit_visible(f, r, s, list_w, lh, avail)
  val rows = fit.rows
  val list_end = iadd(rows_y, fit.used)
  val label_y = iadd(list_end, gap)
  val input_y = iadd(label_y, iadd(lh, VAULT_DIALOG_LINE_GAP))
  val hint_y = iadd(iadd(input_y, input_h), VAULT_DIALOG_HINT_GAP)
  val dh = iadd(iadd(hint_y, lh), pad)
in
  @{lh= lh, mx= idiv(isub(w, dw), 2), my= idiv(isub(h, dh), 2), dw= dw, dh= dh,
    rows= rows, overflow= imax(0, isub(s.vcnt, rows)),
    list_x= pad, list_w= list_w, rows_y= rows_y, divider_y= isub(label_y, idiv(gap, 2)), label_y= label_y,
    input_y= input_y, input_w= isub(list_w, iadd(VAULT_DIALOG_BUTTON_WIDTH, VAULT_DIALOG_FIELD_GAP)), hint_y= hint_y}
end

fun vault_input_h(g: VaultGeo): int = iadd(g.lh, imul(VAULT_DIALOG_INPUT_PADDING, 2))
fun vault_row_x(g: VaultGeo): int = iadd(g.mx, isub(g.list_x, VAULT_DIALOG_ROW_GAP))
fun vault_row_w(g: VaultGeo): int = iadd(g.list_w, imul(VAULT_DIALOG_ROW_GAP, 2))
fun vault_button_x(g: VaultGeo): int = isub(iadd(g.mx, g.dw), iadd(VAULT_DIALOG_PADDING, VAULT_DIALOG_BUTTON_WIDTH))
fun vault_close_x(g: VaultGeo): int = isub(iadd(g.mx, g.dw), iadd(VAULT_DIALOG_PADDING, VAULT_DIALOG_CLOSE_SIZE))
fun vault_close_y(g: VaultGeo): int = iadd(g.my, isub(VAULT_DIALOG_PADDING, idiv(isub(VAULT_DIALOG_CLOSE_SIZE, g.lh), 2)))

(* i. satırın üst kenarı (kart içi), önceki satırların kırılmış yükseklikleri toplanır. *)
fun vault_row_top_loop {n:nat} .<n>. (
  left: int(n), f: !Font, r: !Rend, s: &App_record, g: VaultGeo, j: int, y: int
): int =
  if left = 0 then y
  else let
    val lines = vault_row_lines(f, r, s, g.list_w, j)
    val next = iadd(y, iadd(vault_row_height(g.lh, lines), VAULT_DIALOG_ROW_GAP))
  in
    vault_row_top_loop(left - 1, f, r, s, g, iadd(j, 1), next)
  end

fun vault_row_top(f: !Font, r: !Rend, s: &App_record, g: VaultGeo, vi: int): int =
  vault_row_top_loop(airlock_nat(imax(0, vi)), f, r, s, g, 0, g.rows_y)

(* ---- Çizim ---- *)

fun vault_section_label(f: !Font, r: !Rend, x: int, y: int, text: string): void =
  draw_s(f, r, x, y, text, col_muted())

fun vault_row_background(r: !Rend, x: int, y: int, w: int, h: int, is_current: bool, is_hover: bool): void =
  if is_current then rend_rrect(r, x, y, w, h, VAULT_DIALOG_ROW_RADIUS, col_accent_soft())
  else if is_hover then rend_rrect(r, x, y, w, h, VAULT_DIALOG_ROW_RADIUS, col_surface())
  else ()

fun draw_vault_path_lines {n:nat} .<n>. (
  left: int(n), f: !Font, r: !Rend, path: !Buf, plen: int, off: int, x: int, y: int, text_w: int, lh: int
): void =
  if left = 0 then ()
  else if ige(off, plen) then ()
  else let
    var tmp = buf_make(DRAW_VAULT_ITEM_PBUF_INITIAL_BYTES)
    val () = buffer_append_range(tmp, path, off, plen)
    val tn = buf_len(tmp)
    val fit = imax(1, ui_fit_str_bytes(f, r, buf_ptr(tmp), tn, text_w))
  in
    if ieq(left, 1) then let
      val () = ui_draw_fitted_buf(f, r, x, y, text_w, lh, 0, 0, Off, tmp, col_muted())
    in
      buf_free(tmp)
    end else let
      val () = seen_int(font_draw(f, r, x, y, buf_ptr(tmp), fit, col_muted()))
      val () = buf_free(tmp)
    in
      draw_vault_path_lines(left - 1, f, r, path, plen, iadd(off, fit), x, iadd(y, lh), text_w, lh)
    end
  end

fun draw_vault_row_texts(f: !Font, r: !Rend, g: VaultGeo, x: int, y: int, w: int, name: !Buf, path: !Buf, is_current: bool): void = let
  val tx = iadd(x, VAULT_DIALOG_TEXT_INSET)
  val ty = iadd(y, VAULT_DIALOG_ROW_PADDING)
  val tw = isub(w, iadd(VAULT_DIALOG_TEXT_INSET, VAULT_DIALOG_CHECK_INSET))
  val icon_y = iadd(ty, idiv(isub(g.lh, VAULT_DIALOG_ICON_SIZE), 2))
  val () = ui_draw_icon(f, r, UI_ICON_FOLDER, iadd(x, 16), icon_y, VAULT_DIALOG_ICON_SIZE, (if is_current then col_accent_hi() else col_muted()))
  val () = ui_draw_fitted_buf(f, r, tx, ty, tw, g.lh, 0, 0, Off, name, (if is_current then col_white() else col_text()))
  val () = draw_vault_path_lines(airlock_nat(VAULT_DIALOG_MAX_PATH_LINES), f, r, path, buf_len(path), 0, tx, iadd(ty, g.lh), tw, g.lh)
in
  if is_current then ui_draw_icon(f, r, UI_ICON_CHECK, isub(iadd(x, w), VAULT_DIALOG_CHECK_INSET), icon_y, VAULT_DIALOG_ICON_SIZE, col_accent_hi()) else ()
end

fun draw_vault_row(f: !Font, r: !Rend, s: &App_record, g: VaultGeo, vi: int): void = let
  var nbuf = buf_make(DRAW_VAULT_ITEM_NBUF_INITIAL_BYTES)
  var pbuf = buf_make(DRAW_VAULT_ITEM_PBUF_INITIAL_BYTES)
  val () = vault_row_fill(s, vi, nbuf, pbuf)
  val x = vault_row_x(g)
  val w = vault_row_w(g)
  val y = iadd(g.my, vault_row_top(f, r, s, g, vi))
  val h = vault_row_height(g.lh, vault_row_lines(f, r, s, g.list_w, vi))
  val is_current = ieq(c_strcmp(buffer_c_string(pbuf), buffer_c_string(s.vault)), 0)
  val is_hover = vault_in_rect(s.hoverx, s.hovery, x, y, w, h)
  val () = vault_row_background(r, x, y, w, h, is_current, is_hover)
  val () = draw_vault_row_texts(f, r, g, x, y, w, nbuf, pbuf, is_current)
  val () = buf_free(nbuf)
in
  buf_free(pbuf)
end

fun draw_vault_rows {n:nat} .<n>. (left: int(n), f: !Font, r: !Rend, s: &App_record, g: VaultGeo, vi: int): void =
  if left = 0 then ()
  else let
    val () = draw_vault_row(f, r, s, g, vi)
  in
    draw_vault_rows(left - 1, f, r, s, g, iadd(vi, 1))
  end

fun draw_vault_overflow(f: !Font, r: !Rend, g: VaultGeo): void =
  if igt(g.overflow, 0) then let
    var tb = buf_make(DRAW_VAULT_ITEM_NBUF_INITIAL_BYTES)
    val () = buffer_append_string(tb, "+")
    val () = buffer_append_integer(tb, g.overflow)
    val () = buffer_append_string(tb, " kasa daha")
    val tn = buf_len(tb)
    val tw = font_width_buf(f, r, tb, tn)
    val ly = iadd(g.my, isub(g.rows_y, iadd(g.lh, VAULT_DIALOG_LINE_GAP)))
    val () = draw_s(f, r, isub(iadd(g.mx, iadd(g.list_x, g.list_w)), tw), ly, buffer_c_string(tb), col_muted())
  in
    buf_free(tb)
  end else ()

fun draw_vault_list(f: !Font, r: !Rend, s: &App_record, g: VaultGeo): void = let
  val ly = iadd(g.my, isub(g.rows_y, iadd(g.lh, VAULT_DIALOG_LINE_GAP)))
  val () = vault_section_label(f, r, iadd(g.mx, g.list_x), ly, "KASALAR")
in
  if ile(g.rows, 0) then
    draw_s(f, r, iadd(g.mx, g.list_x), iadd(g.my, iadd(g.rows_y, VAULT_DIALOG_ROW_PADDING)), "Henüz kayıtlı kasa yok.", col_muted())
  else let
    val () = draw_vault_rows(airlock_nat(g.rows), f, r, s, g, 0)
  in
    draw_vault_overflow(f, r, g)
  end
end

fun draw_vault_close(f: !Font, r: !Rend, s: &App_record, g: VaultGeo): void =
  if igt(buf_len(s.vault), 0) then let
    val cx = vault_close_x(g)
    val cy = vault_close_y(g)
    val cs = VAULT_DIALOG_CLOSE_SIZE
    val hov = vault_in_rect(s.hoverx, s.hovery, cx, cy, cs, cs)
    val () = if hov then rend_rrect(r, cx, cy, cs, cs, 6, col_surface()) else ()
  in
    ui_draw_icon(f, r, UI_ICON_CLOSE, iadd(cx, 8), iadd(cy, 8), 12, (if hov then col_heading() else col_muted()))
  end else ()

fun draw_vault_new_field(f: !Font, r: !Rend, s: &App_record, g: VaultGeo): void = let
  val fx = iadd(g.mx, g.list_x)
  val py = iadd(g.my, g.input_y)
  val ih = vault_input_h(g)
  val qlen = buf_len(s.promptb)
  val () = rend_rect(r, fx, iadd(g.my, g.divider_y), g.list_w, 1, col_line())
  val () = vault_section_label(f, r, fx, iadd(g.my, g.label_y), "YENİ KASA YOLU")
  val () = ui_line_edit_draw(f, r, fx, py, g.input_w, ih, s.promptb, qlen, qlen, On, "/home/kullanici/Notlar")
  val bx = vault_button_x(g)
  val hov = vault_in_rect(s.hoverx, s.hovery, bx, py, VAULT_DIALOG_BUTTON_WIDTH, ih)
in
  ui_button(f, r, bx, py, VAULT_DIALOG_BUTTON_WIDTH, ih, "Aç", toggle_of(hov), On)
end

fun draw_vault_hint(f: !Font, r: !Rend, s: &App_record, g: VaultGeo): void =
  draw_s(f, r, iadd(g.mx, g.list_x), iadd(g.my, g.hint_y),
    (if igt(buf_len(s.vault), 0) then "Enter: aç    Esc: kapat" else "Enter: aç"), col_muted())

fun draw_vault_card(f: !Font, r: !Rend, s: &App_record, g: VaultGeo): void = let
  val rad = VAULT_DIALOG_RADIUS
  val () = ui_draw_shadow(r, g.mx, g.my, g.dw, g.dh, rad)
  val () = rend_rrect_ex(r, g.mx, g.my, g.dw, g.dh, rad, rad, rad, rad, col_side(), col_side(), 1, col_line(), 1)
  val lx = iadd(g.mx, VAULT_DIALOG_PADDING)
  val () = draw_s(f, r, lx, iadd(g.my, VAULT_DIALOG_PADDING), "Kasa seç", col_heading())
  val () = ui_draw_fitted_text(f, r, lx, iadd(g.my, iadd(VAULT_DIALOG_PADDING, iadd(g.lh, VAULT_DIALOG_LINE_GAP))),
    isub(g.dw, imul(VAULT_DIALOG_PADDING, 2)), g.lh, 0, 0, Off, "Bir klasörü kasa olarak seç ya da yenisini oluştur.", col_muted())
  val () = draw_vault_list(f, r, s, g)
  val () = draw_vault_close(f, r, s, g)
  val () = draw_vault_new_field(f, r, s, g)
in
  draw_vault_hint(f, r, s, g)
end

fun draw_vault_select(f: !Font, r: !Rend, a: !App, w: int, h: int): void =
  case+ a of
  | @APP(s) => let
      val () = if is_on(s.vault_select) then let
        val () = rend_rect(r, 0, 0, w, h, col_overlay())
        val () = font_set_px(f, s.fontpx)
        val g = vault_geo(f, r, s, w, h)
      in
        draw_vault_card(f, r, s, g)
      end else ()
    in
      fold@(a)
    end
