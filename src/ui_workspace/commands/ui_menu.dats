#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "mem.sats"
staload "airlock.sats"
staload "flag.sats"
staload "os/fs.sats"
staload "core_platform/x11.sats"
staload "core_platform/platform.sats"
staload "core_render/render.sats"
staload "core_render/gl.sats"
staload "data_font/resources/font.sats"
staload "ui_workspace/common/ui_common.sats"
staload "ui_workspace/tree/ui_tree.sats"
staload "ui_workspace/commands/ui_menu.sats"

implement key_is(ev, k) = ieq(x_key_is(ev, key_id(k)), 1)
implement ctrl_on(ev) = anth_iand(ev_mods(ev), mod_ctrl()) <> 0
implement shift_on(ev) = anth_iand(ev_mods(ev), mod_shift()) <> 0
implement alt_on(ev) = anth_iand(ev_mods(ev), mod_alt()) <> 0
implement key_char(ev) = ev_key_char(ev)

implement text_row(t) = case+ t of
  | TextCut() => 0
  | TextCopy() => 1
  | TextPaste() => 2
  | TextClear() => 3

implement image_row(t) = case+ t of
  | ImageCopy() => 0
  | ImageReveal() => 1
  | ImageDelete() => 2

implement tree_row(t) = case+ t of
  | TreeNewFile() => 0
  | TreeNewFolder() => 1
  | TreeRename() => 2
  | TreeDelete() => 3

fun ev_text_buf(ev: &event, dst: !Buf, n: int): int =
  ev_text(ev, buf_ptr(dst), n)

staload "ui_workspace/widgets/ui_widgets.sats"

fun menu_item_y(base_y: int, idx: int): int = iadd(base_y, imul(idx, UI_MENU_ITEM_HEIGHT))


fun draw_menu_text_items(f: !Font, r: !Rend, menux: int, menuy: int, mw: int): void = let
  val () = ui_hover_label(f, r, menux, menu_item_y(menuy, text_row(TextCut)), mw, UI_MENU_ITEM_HEIGHT, "Kes", Off)
  val () = ui_hover_label(f, r, menux, menu_item_y(menuy, text_row(TextCopy)), mw, UI_MENU_ITEM_HEIGHT, "Kopyala", Off)
  val () = ui_hover_label(f, r, menux, menu_item_y(menuy, text_row(TextPaste)), mw, UI_MENU_ITEM_HEIGHT, "Yapıştır", Off)
  val () = ui_hover_label(f, r, menux, menu_item_y(menuy, text_row(TextClear)), mw, UI_MENU_ITEM_HEIGHT, "Biçimlendirmeyi Temizle", Off)
in
end

fun draw_menu_image_items(f: !Font, r: !Rend, menux: int, menuy: int, mw: int): void = let
  val () = ui_hover_label(f, r, menux, menu_item_y(menuy, image_row(ImageCopy)), mw, UI_MENU_ITEM_HEIGHT, "Görseli Kopyala", Off)
  val () = ui_hover_label(f, r, menux, menu_item_y(menuy, image_row(ImageReveal)), mw, UI_MENU_ITEM_HEIGHT, "Dosya Konumunu Aç", Off)
  val () = ui_hover_label(f, r, menux, menu_item_y(menuy, image_row(ImageDelete)), mw, UI_MENU_ITEM_HEIGHT, "Dokümandan Kaldır", Off)
in
end

fun draw_menu_tree_items(f: !Font, r: !Rend, menux: int, menuy: int, mw: int): void = let
  val () = ui_hover_label(f, r, menux, menu_item_y(menuy, tree_row(TreeNewFile)), mw, UI_MENU_ITEM_HEIGHT, "Yeni Dosya Oluştur", Off)
  val () = ui_hover_label(f, r, menux, menu_item_y(menuy, tree_row(TreeNewFolder)), mw, UI_MENU_ITEM_HEIGHT, "Yeni Klasör Oluştur", Off)
  val () = ui_hover_label(f, r, menux, menu_item_y(menuy, tree_row(TreeRename)), mw, UI_MENU_ITEM_HEIGHT, "Yeniden Adlandır", Off)
  val () = ui_hover_label(f, r, menux, menu_item_y(menuy, tree_row(TreeDelete)), mw, UI_MENU_ITEM_HEIGHT, "Sil", Off)
in
end

implement draw_menu(f, r, menu, menux, menuy, menuw) = let
  val n = if is_menu_text(menu) then 4
          else if is_menu_image(menu) then 3
          else if is_menu_filetree(menu) then 4
          else 0
  val mw = if igt(menuw, 0) then menuw else UI_MENU_WIDTH
  val mh = imul(n, UI_MENU_ITEM_HEIGHT)
  val () = if igt(n, 0) then ui_pane_begin(r, menux, menuy, mw, mh, col_menu_pane()) else ()
in
  if is_menu_text(menu) then draw_menu_text_items(f, r, menux, menuy, mw)
  else if is_menu_image(menu) then draw_menu_image_items(f, r, menux, menuy, mw)
  else if is_menu_filetree(menu) then draw_menu_tree_items(f, r, menux, menuy, mw)
  else ()
end

implement is_sub_none(s) = case+ s of | SubNone() => true | _ => false

implement sub_menu_eq(a, b) =
  case+ (a, b) of
  | (SubNone(), SubNone()) => true
  | (SubFormat(), SubFormat()) => true
  | (SubParagraph(), SubParagraph()) => true
  | (SubInsert(), SubInsert()) => true
  | (_, _) => false

implement menu_var_count(mv) =
  case+ mv of
  | MenuVarEditText() => 10
  | MenuVarImage() => 3
  | MenuVarReadText() => 2
  | MenuVarTreeItem() => 5
  | MenuVarTreeEmpty() => 2

implement menu_sub_count(sub) =
  case+ sub of
  | SubNone() => 0
  | SubFormat() => 4
  | SubParagraph() => 9
  | SubInsert() => 6

fun var_sep_before(mv: MenuVariant, i: int): bool =
  case+ mv of
  | MenuVarEditText() => ieq(i, 2) orelse ieq(i, 5)
  | MenuVarTreeItem() => ieq(i, 4)
  | _ => false

fun sub_sep_before(sub: SubmenuL1, i: int): bool =
  case+ sub of | SubParagraph() => ieq(i, 3) | _ => false

fun var_sep_count_before(mv: MenuVariant, i: int): int =
  case+ mv of
  | MenuVarEditText() => if ige(i, 5) then 2 else if ige(i, 2) then 1 else 0
  | MenuVarTreeItem() => if ige(i, 4) then 1 else 0
  | _ => 0

fun sub_sep_count_before(sub: SubmenuL1, i: int): int =
  case+ sub of | SubParagraph() => if ige(i, 3) then 1 else 0 | _ => 0

implement menu_var_row_y(mv, idx) =
  iadd(UI_MENU_PAD_Y, iadd(imul(idx, UI_MENU_ITEM_HEIGHT), imul(var_sep_count_before(mv, idx), UI_MENU_SEP_H)))

implement menu_sub_row_y(sub, idx) =
  iadd(UI_MENU_PAD_Y, iadd(imul(idx, UI_MENU_ITEM_HEIGHT), imul(sub_sep_count_before(sub, idx), UI_MENU_SEP_H)))

implement menu_var_height(mv) = let
  val n = menu_var_count(mv)
in
  if igt(n, 0) then iadd(menu_var_row_y(mv, n), UI_MENU_PAD_Y) else 0
end

implement menu_sub_height(sub) = let
  val n = menu_sub_count(sub)
in
  if igt(n, 0) then iadd(menu_sub_row_y(sub, n), UI_MENU_PAD_Y) else 0
end

fun edit_text_action(i: int): ContextAction =
  if ieq(i, 0) then CtxWikiLink
  else if ieq(i, 1) then CtxExtLink
  else if ieq(i, 5) then CtxCut
  else if ieq(i, 6) then CtxCopy
  else if ieq(i, 7) then CtxPaste
  else if ieq(i, 8) then CtxPastePlain
  else if ieq(i, 9) then CtxSelectAll
  else CtxNone

fun tree_item_action(i: int): ContextAction =
  if ieq(i, 0) then CtxTreeNewNote
  else if ieq(i, 1) then CtxTreeNewDir
  else if ieq(i, 2) then CtxTreeDuplicate
  else if ieq(i, 3) then CtxTreeRename
  else if ieq(i, 4) then CtxTreeDelete
  else CtxNone

implement menu_var_action(mv, idx) =
  case+ mv of
  | MenuVarEditText() => edit_text_action(idx)
  | MenuVarImage() =>
      if ieq(idx, 0) then CtxImgCopy else if ieq(idx, 1) then CtxImgReveal else if ieq(idx, 2) then CtxImgRemove else CtxNone
  | MenuVarReadText() =>
      if ieq(idx, 0) then CtxCopy else if ieq(idx, 1) then CtxSelectAll else CtxNone
  | MenuVarTreeItem() => tree_item_action(idx)
  | MenuVarTreeEmpty() =>
      if ieq(idx, 0) then CtxTreeNewNote else if ieq(idx, 1) then CtxTreeNewDir else CtxNone

fun sub_para_action(i: int): ContextAction =
  if ieq(i, 0) then CtxBulletList
  else if ieq(i, 1) then CtxNumberList
  else if ieq(i, 2) then CtxTaskList
  else if ieq(i, 3) then CtxHeading1
  else if ieq(i, 4) then CtxHeading2
  else if ieq(i, 5) then CtxHeading3
  else if ieq(i, 6) then CtxHeading4
  else if ieq(i, 7) then CtxHeading5
  else if ieq(i, 8) then CtxHeading6
  else CtxNone

fun sub_insert_action(i: int): ContextAction =
  if ieq(i, 0) then CtxFootnote
  else if ieq(i, 1) then CtxTable
  else if ieq(i, 2) then CtxCallout
  else if ieq(i, 3) then CtxHr
  else if ieq(i, 4) then CtxCodeBlock
  else if ieq(i, 5) then CtxMathBlock
  else CtxNone

implement menu_sub_action(sub, idx) =
  case+ sub of
  | SubNone() => CtxNone
  | SubFormat() =>
      if ieq(idx, 0) then CtxBold else if ieq(idx, 1) then CtxItalic
      else if ieq(idx, 2) then CtxStrike else if ieq(idx, 3) then CtxHighlight else CtxNone
  | SubParagraph() => sub_para_action(idx)
  | SubInsert() => sub_insert_action(idx)

implement menu_var_submenu(mv, idx) =
  case+ mv of
  | MenuVarEditText() =>
      if ieq(idx, 2) then SubFormat
      else if ieq(idx, 3) then SubParagraph
      else if ieq(idx, 4) then SubInsert
      else SubNone
  | _ => SubNone

fun edit_text_label(i: int): string =
  if ieq(i, 0) then "Bağlantı ekle"
  else if ieq(i, 1) then "Dış bağlantı ekle"
  else if ieq(i, 2) then "Biçimlendirme"
  else if ieq(i, 3) then "Paragraf"
  else if ieq(i, 4) then "Ekle"
  else if ieq(i, 5) then "Kes"
  else if ieq(i, 6) then "Kopyala"
  else if ieq(i, 7) then "Yapıştır"
  else if ieq(i, 8) then "Düz metin olarak yapıştır"
  else "Tümünü seç"

fun tree_item_label(i: int): string =
  if ieq(i, 0) then "Yeni not"
  else if ieq(i, 1) then "Yeni klasör"
  else if ieq(i, 2) then "Kopyasını oluştur"
  else if ieq(i, 3) then "Yeniden adlandır"
  else "Sil"

implement menu_var_label(mv, idx) =
  case+ mv of
  | MenuVarEditText() => edit_text_label(idx)
  | MenuVarImage() =>
      if ieq(idx, 0) then "Görseli Kopyala" else if ieq(idx, 1) then "Dosya Konumunu Aç" else "Dokümandan Kaldır"
  | MenuVarReadText() =>
      if ieq(idx, 0) then "Kopyala" else "Tümünü seç"
  | MenuVarTreeItem() => tree_item_label(idx)
  | MenuVarTreeEmpty() =>
      if ieq(idx, 0) then "Yeni not" else "Yeni klasör"

fun sub_para_label(i: int): string =
  if ieq(i, 0) then "Madde işaretli liste"
  else if ieq(i, 1) then "Numaralı liste"
  else if ieq(i, 2) then "[x] İşaretli liste"
  else if ieq(i, 3) then "Başlık 1"
  else if ieq(i, 4) then "Başlık 2"
  else if ieq(i, 5) then "Başlık 3"
  else if ieq(i, 6) then "Başlık 4"
  else if ieq(i, 7) then "Başlık 5"
  else "Başlık 6"

fun sub_insert_label(i: int): string =
  if ieq(i, 0) then "Dipnot"
  else if ieq(i, 1) then "Tablo"
  else if ieq(i, 2) then "Çağrı"
  else if ieq(i, 3) then "Yatay çizgi"
  else if ieq(i, 4) then "Kod bloğu"
  else "Matematik bloğu"

implement menu_sub_label(sub, idx) =
  case+ sub of
  | SubNone() => ""
  | SubFormat() =>
      if ieq(idx, 0) then "Kalın" else if ieq(idx, 1) then "İtalik"
      else if ieq(idx, 2) then "Üstü çizgili" else "Vurgula"
  | SubParagraph() => sub_para_label(idx)
  | SubInsert() => sub_insert_label(idx)

implement menu_var_row_for_sub(mv, sub) =
  case+ mv of
  | MenuVarEditText() =>
      (case+ sub of | SubFormat() => 2 | SubParagraph() => 3 | SubInsert() => 4 | SubNone() => ~1)
  | _ => ~1

fun hit_root_m {rem:nat} .<rem>. (
  rem: int(rem), mv: MenuVariant, my: int, i: int, y: int
): int =
  if rem = 0 then ~1
  else let
    val ry = iadd(my, menu_var_row_y(mv, i))
  in
    if ige(y, ry) andalso ilt(y, iadd(ry, UI_MENU_ITEM_HEIGHT)) then i
    else hit_root_m(rem - 1, mv, my, iadd(i, 1), y)
  end

fun hit_sub_m {rem:nat} .<rem>. (
  rem: int(rem), sub: SubmenuL1, sy: int, i: int, y: int
): int =
  if rem = 0 then ~1
  else let
    val ry = iadd(sy, menu_sub_row_y(sub, i))
  in
    if ige(y, ry) andalso ilt(y, iadd(ry, UI_MENU_ITEM_HEIGHT)) then i
    else hit_sub_m(rem - 1, sub, sy, iadd(i, 1), y)
  end

implement menu_hit_root(mv, mx, my, mw, x, y) = let
  val n = menu_var_count(mv)
in
  if ile(n, 0) orelse ilt(x, mx) orelse ige(x, iadd(mx, mw)) then ~1
  else hit_root_m(airlock_nat(n), mv, my, 0, y)
end

implement menu_hit_sub(sub, sx, sy, sw, x, y) = let
  val n = menu_sub_count(sub)
in
  if ile(n, 0) orelse ilt(x, sx) orelse ige(x, iadd(sx, sw)) then ~1
  else hit_sub_m(airlock_nat(n), sub, sy, 0, y)
end

implement menu_sub_pos(mv, sub, mx, my, mw, sub_w, w, h, sx, sy, sw) = let
  val r_idx = menu_var_row_for_sub(mv, sub)
  val sw_val = imin(imax(40, isub(w, 8)), imax(UI_MENU_SUB_MIN_WIDTH, sub_w))
  val sh = menu_sub_height(sub)
  val right_x = isub(iadd(mx, mw), 4)
  val sx_raw = if ile(iadd(right_x, sw_val), isub(w, 4)) then right_x else imax(4, iadd(isub(mx, sw_val), 4))
  val max_sx = imax(4, isub(w, iadd(sw_val, 4)))
  val y_off = if ige(r_idx, 0) then isub(menu_var_row_y(mv, r_idx), UI_MENU_PAD_Y) else 0
  val sy_raw = iadd(my, y_off)
  val max_sy = imax(4, isub(h, iadd(sh, 4)))
in
  sx := imax(4, imin(max_sx, sx_raw)); sy := imax(4, imin(max_sy, sy_raw)); sw := sw_val
end

implement menu_clamp_root(mv, mx, my, mw, w, h) = let
  val mh = menu_var_height(mv)
  val max_x = imax(4, isub(w, iadd(mw, 4)))
  val max_y = imax(4, isub(h, iadd(mh, 4)))
in
  mx := imax(4, imin(max_x, mx));
  my := imax(4, imin(max_y, my))
end

fun measure_var_w_m {rem:nat} .<rem>. (
  rem: int(rem), f: !Font, r: !Rend, mv: MenuVariant, i: int, best: int
): int =
  if rem = 0 then best
  else let
    val lbl = menu_var_label(mv, i)
    val tw = font_width(f, r, c_str_ptr(lbl), c_strlen(lbl))
    val has_sub = not(is_sub_none(menu_var_submenu(mv, i)))
    val pr = if has_sub then UI_MENU_SUB_PAD_R else UI_MENU_PAD_R
    val rw = iadd(UI_MENU_PAD_L, iadd(tw, pr))
  in
    measure_var_w_m(rem - 1, f, r, mv, iadd(i, 1), imax(best, rw))
  end

implement menu_var_measure_width(f, r, mv) =
  measure_var_w_m(airlock_nat(menu_var_count(mv)), f, r, mv, 0, UI_MENU_WIDTH)

fun measure_sub_w_m {rem:nat} .<rem>. (
  rem: int(rem), f: !Font, r: !Rend, sub: SubmenuL1, i: int, best: int
): int =
  if rem = 0 then best
  else let
    val lbl = menu_sub_label(sub, i)
    val tw = font_width(f, r, c_str_ptr(lbl), c_strlen(lbl))
    val rw = iadd(UI_MENU_PAD_L, iadd(tw, UI_MENU_PAD_R))
  in
    measure_sub_w_m(rem - 1, f, r, sub, iadd(i, 1), imax(best, rw))
  end

implement menu_sub_measure_width(f, r, sub) =
  measure_sub_w_m(airlock_nat(menu_sub_count(sub)), f, r, sub, 0, UI_MENU_SUB_MIN_WIDTH)

implement menu_compute_width(f, r) = let
  val r1 = imax(menu_var_measure_width(f, r, MenuVarEditText), menu_var_measure_width(f, r, MenuVarImage))
  val r2 = imax(r1, menu_var_measure_width(f, r, MenuVarTreeItem))
  val s1 = imax(menu_sub_measure_width(f, r, SubFormat), menu_sub_measure_width(f, r, SubParagraph))
in
  imax(r2, imax(s1, menu_sub_measure_width(f, r, SubInsert)))
end

fun draw_menu_row(
  f: !Font, r: !Rend, px: int, iy: int, pw: int, label: string,
  has_sep: bool, is_hov: bool, has_sub: bool, is_danger: bool
): void = let
  val () = if has_sep then ui_divider(r, iadd(px, 10), isub(iy, 5), imax(1, isub(pw, 20)), Horizontal) else ()
  val pill_col = if is_danger then col_danger_soft() else col_accent_soft()
  val () = if is_hov then rend_rrect(r, iadd(px, 6), iadd(iy, 2), imax(1, isub(pw, 12)), isub(UI_MENU_ITEM_HEIGHT, 4), 6, pill_col) else ()
  val tc = if is_danger then col_danger() else if is_hov then col_white() else col_text()
  val pad_r = if has_sub then UI_MENU_SUB_PAD_R else UI_MENU_PAD_R
  val () = ui_draw_fitted_text(f, r, px, iy, pw, UI_MENU_ITEM_HEIGHT, UI_MENU_PAD_L, pad_r, Off, label, tc)
in
  if has_sub then ui_draw_icon(f, r, UI_ICON_CHEVRON_RIGHT, isub(iadd(px, pw), 20), iadd(iy, idiv(isub(UI_MENU_ITEM_HEIGHT, 8), 2)), 8, if is_hov then col_white() else col_muted())
  else ()
end

fun var_is_danger(mv: MenuVariant, i: int): bool =
  case+ mv of
  | MenuVarTreeItem() => ieq(i, 4)
  | MenuVarImage() => ieq(i, 2)
  | _ => false

fun draw_root_rows_m {n:nat} .<n>. (
  left: int(n), f: !Font, r: !Rend, mv: MenuVariant, sub: SubmenuL1,
  mx: int, my: int, mw: int, idx: int, hit_i: int
): void =
  if left = 0 then ()
  else let
    val row_sub = menu_var_submenu(mv, idx)
    val sub_open = not(is_sub_none(sub)) andalso sub_menu_eq(row_sub, sub)
    val iy = iadd(my, menu_var_row_y(mv, idx))
    val () = draw_menu_row(f, r, mx, iy, mw, menu_var_label(mv, idx),
      var_sep_before(mv, idx), ieq(hit_i, idx) orelse sub_open, not(is_sub_none(row_sub)), var_is_danger(mv, idx))
  in
    draw_root_rows_m(left - 1, f, r, mv, sub, mx, my, mw, iadd(idx, 1), hit_i)
  end

fun draw_sub_rows_m {n:nat} .<n>. (
  left: int(n), f: !Font, r: !Rend, sub: SubmenuL1,
  sx: int, sy: int, sw: int, idx: int, hit_i: int
): void =
  if left = 0 then ()
  else let
    val iy = iadd(sy, menu_sub_row_y(sub, idx))
    val () = draw_menu_row(f, r, sx, iy, sw, menu_sub_label(sub, idx),
      sub_sep_before(sub, idx), ieq(hit_i, idx), false, false)
  in
    draw_sub_rows_m(left - 1, f, r, sub, sx, sy, sw, iadd(idx, 1), hit_i)
  end

implement draw_menu_v2(f, r, mv, sub, mx, my, mw, sx, sy, sw, hx, hy) = let
  val n = menu_var_count(mv)
  val mh = menu_var_height(mv)
  val hit_r = menu_hit_root(mv, mx, my, mw, hx, hy)
  val () = if igt(n, 0) then (
    ui_pane_begin(r, mx, my, mw, mh, col_menu());
    draw_root_rows_m(airlock_nat(n), f, r, mv, sub, mx, my, mw, 0, hit_r)
  ) else ()
  val sn = menu_sub_count(sub)
  val sh = menu_sub_height(sub)
  val hit_s = menu_hit_sub(sub, sx, sy, sw, hx, hy)
in
  if igt(sn, 0) then (
    ui_pane_begin(r, sx, sy, sw, sh, col_menu());
    draw_sub_rows_m(airlock_nat(sn), f, r, sub, sx, sy, sw, 0, hit_s)
  ) else ()
end

implement draw_prompt(f, r, b, prompt) =
  if is_prompt_newfile(prompt) orelse is_prompt_newfolder(prompt) then let
    val title = if is_prompt_newfile(prompt) then "Yeni Dosya:" else "Yeni Klasör:"
    val () = ui_pane_begin(r, 12, 68, 256, 56, col_menu())
    val () = draw_s(f, r, 18, 72, title, col_accent_hi())
    val n = buf_len(b)
    val () = ui_line_edit_draw(f, r, 16, 92, 248, 26, b, n, n, On, "İsim girin...")
  in
  end else seen_buf(b)

extern fun utf8_menu_back_fuel_exhausted(b: !Buf, n: int, k: int): int = "mac#anth_die_int"

fun buf_utf8_prev(b: !Buf, n: int): int =
  if n <= 1 then 0
  else let
    fun back {lim:nat} .<lim>. (b: !Buf, n: int, k: int, lim: int(lim)): int =
      if lim > 0 then (
        if k <= 0 then 0
        else let
          val by = buf_get(b, isub(k, 1))
        in
          if by < 128 orelse by >= 192 then isub(k, 1)
          else back(b, n, isub(k, 1), lim - 1)
        end
      ) else utf8_menu_back_fuel_exhausted(b, n, k)
  in
    back(b, n, n, 4)
  end


fun edit_backspace(b: &Buf >> Buf): EditResult = let
  val n = buf_len(b)
in
  if igt(n, 0) then let
    val prev = buf_utf8_prev(b, n)
    val () = buf_set_len(b, prev)
  in
    EditChanged
  end else EditChanged
end

extern fun push_typed_fuel_exhausted(b: &Buf >> Buf, scratch: !Buf, j: int, n: int): void = "mac#anth_die_void"

fun push_typed_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), b: &Buf >> Buf, scratch: !Buf, j: int, n: int): void =
  if recursion_fuel_available(recfuel) then (
    if ilt(j, n) then let
      val by = buf_get(scratch, j)
      val () = if ige(by, 32) andalso ine(by, 127) then buf_push(b, by) else ()
    in
      push_typed_with_fuel(recfuel - 1, b, scratch, iadd(j, 1), n)
    end else ()
  ) else push_typed_fuel_exhausted(b, scratch, j, n)

fun edit_insert_typed(b: &Buf >> Buf, ev: &event, scratch: &Buf >> Buf): int = let
  val before = buf_len(b)
  val cap = buf_cap(scratch)
  val raw_n = ev_text_buf(ev, scratch, cap)
  val n = filter_text(scratch, raw_n)
  val () = push_typed_with_fuel(airlock_nat(MAX_REC_FUEL), b, scratch, 0, n)
in
  isub(buf_len(b), before)
end

implement edit_line(b, ev, scratch) =
  if ctrl_on(ev) then EditNone
  else if key_is(ev, KeyBackspace) then edit_backspace(b)
  else if key_is(ev, KeyReturn) then EditSubmit
  else if key_is(ev, KeyEscape) then EditCancel
  else let
    val added = edit_insert_typed(b, ev, scratch)
  in
    if igt(added, 0) then EditChanged else EditNone
  end

implement act_prompt(dir, cur, name, kind) =
  if is_prompt_newfile(kind) then do_create(dir, name, false)
  else if is_prompt_newfolder(kind) then do_create(dir, name, true)
  else if is_prompt_rename(kind) then do_rename(cur, name)
  else let
    val () = seen_buf(dir)
    val () = seen_buf(cur)
    val () = seen_buf(name)
  in
  end
