#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "mem.sats"
staload "airlock.sats"
staload "flag.sats"
staload "core_platform/x11.sats"
staload "core_platform/platform.sats"
staload "core_render/render.sats"
staload "core_render/gl.sats"
staload "data_font/font.sats"
staload "ui_workspace/ui_common.sats"
staload "ui_workspace/ui_tree.sats"
staload "ui_workspace/ui_menu.sats"

implement key_is(ev, k) = ieq(x_key_is(ev, key_id(k)), 1)
implement ctrl_on(ev) = anth_iand(ev_mods(ev), mod_ctrl()) <> 0
implement shift_on(ev) = anth_iand(ev_mods(ev), mod_shift()) <> 0
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

staload "ui_workspace/ui_widgets.sats"

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

implement draw_menu(f, r, menu, menux, menuy) = let
  val n = if is_menu_text(menu) then 4
          else if is_menu_image(menu) then 3
          else if is_menu_filetree(menu) then 4
          else 0
  val mw = UI_MENU_WIDTH
  val mh = imul(n, UI_MENU_ITEM_HEIGHT)
  val () = if igt(n, 0) then ui_pane_begin(r, menux, menuy, mw, mh, col_menu()) else ()
in
  if is_menu_text(menu) then draw_menu_text_items(f, r, menux, menuy, mw)
  else if is_menu_image(menu) then draw_menu_image_items(f, r, menux, menuy, mw)
  else if is_menu_filetree(menu) then draw_menu_tree_items(f, r, menux, menuy, mw)
  else ()
end

implement draw_prompt(f, r, b, prompt) =
  if is_prompt_none(prompt) then let
    val () = seen_buf(b)
  in
  end else let
    val title =
      if is_prompt_newfile(prompt) then "Yeni Dosya:"
      else if is_prompt_newfolder(prompt) then "Yeni Klasör:"
      else "Yeniden Adlandır:"
    val () = ui_pane_begin(r, 12, 68, 256, 56, col_menu())
    val () = draw_s(f, r, 18, 72, title, col_accent())
    val n = buf_len(b)
    val () = ui_line_edit_draw(f, r, 16, 92, 248, 26, b, n, n, On, "Isim girin...")
  in
  end

extern fun utf8_menu_back_exh(b: !Buf, n: int, k: int): int = "mac#anth_die_int"

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
      ) else utf8_menu_back_exh(b, n, k)
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

extern fun push_typed_exh(b: &Buf >> Buf, scratch: !Buf, j: int, n: int): void = "mac#anth_die_void"

fun push_typed_m {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), b: &Buf >> Buf, scratch: !Buf, j: int, n: int): void =
  if recfuel > 0 then (
    if ilt(j, n) then let
      val by = buf_get(scratch, j)
      val () = if ige(by, 32) andalso ine(by, 127) then buf_push(b, by) else ()
    in
      push_typed_m(recfuel - 1, b, scratch, iadd(j, 1), n)
    end else ()
  ) else push_typed_exh(b, scratch, j, n)

fun edit_insert_typed(b: &Buf >> Buf, ev: &event, scratch: &Buf >> Buf): void = let
  val cap = buf_cap(scratch)
  val raw_n = ev_text_buf(ev, scratch, cap)
  val n = filter_text(scratch, raw_n)
in
  push_typed_m(airlock_nat(MAX_REC_FUEL), b, scratch, 0, n)
end

implement edit_line(b, ev, scratch) =
  if ctrl_on(ev) then EditNone
  else if key_is(ev, KeyBackspace) then edit_backspace(b)
  else if key_is(ev, KeyReturn) then EditSubmit
  else if key_is(ev, KeyEscape) then EditCancel
  else let
    val () = edit_insert_typed(b, ev, scratch)
  in
    EditNone
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
