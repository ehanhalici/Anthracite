#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "mem.sats"
staload "flag.sats"
staload "core_platform/x11.sats"
staload "core_platform/platform.sats"
staload "core_render/render.sats"
staload "core_render/gl.sats"
staload "data_font/font.sats"
staload "ui_workspace/ui_common.sats"
staload "ui_workspace/ui_tree.sats"
staload "ui_workspace/ui_menu.sats"

implement key_is(ev, id) = x_key_is(ev, id)
implement ctrl_on(ev) = if anth_iand(ev_mods(ev), mod_ctrl()) <> 0 then 1 else 0
implement shift_on(ev) = if anth_iand(ev_mods(ev), mod_shift()) <> 0 then 1 else 0
implement key_char(ev) = ev_key_char(ev)

fun ev_text_buf(ev: &event, dst: !Buf, n: int): int =
  ev_text(ev, buf_ptr(dst), n)

staload "ui_workspace/ui_widgets.sats"

fun menu_item_y(base_y: int, idx: int): int = iadd(base_y, imul(idx, UI_MENU_ITEM_HEIGHT))


fun draw_menu_text_items(f: !Font, r: !Rend, menux: int, menuy: int, mw: int): void = let
  val () = ui_hover_label(f, r, menux, menu_item_y(menuy, MENU_TEXT_CUT), mw, UI_MENU_ITEM_HEIGHT, "Kes", Off)
  val () = ui_hover_label(f, r, menux, menu_item_y(menuy, MENU_TEXT_COPY), mw, UI_MENU_ITEM_HEIGHT, "Kopyala", Off)
  val () = ui_hover_label(f, r, menux, menu_item_y(menuy, MENU_TEXT_PASTE), mw, UI_MENU_ITEM_HEIGHT, "Yapıştır", Off)
  val () = ui_hover_label(f, r, menux, menu_item_y(menuy, MENU_TEXT_CLEAR), mw, UI_MENU_ITEM_HEIGHT, "Biçimlendirmeyi Temizle", Off)
in
end

fun draw_menu_image_items(f: !Font, r: !Rend, menux: int, menuy: int, mw: int): void = let
  val () = ui_hover_label(f, r, menux, menu_item_y(menuy, MENU_IMG_COPY), mw, UI_MENU_ITEM_HEIGHT, "Görseli Kopyala", Off)
  val () = ui_hover_label(f, r, menux, menu_item_y(menuy, MENU_IMG_REVEAL), mw, UI_MENU_ITEM_HEIGHT, "Dosya Konumunu Aç", Off)
  val () = ui_hover_label(f, r, menux, menu_item_y(menuy, MENU_IMG_DELETE), mw, UI_MENU_ITEM_HEIGHT, "Dokümandan Kaldır", Off)
in
end

fun draw_menu_tree_items(f: !Font, r: !Rend, menux: int, menuy: int, mw: int): void = let
  val () = ui_hover_label(f, r, menux, menu_item_y(menuy, MENU_TREE_NEW_FILE), mw, UI_MENU_ITEM_HEIGHT, "Yeni Dosya Oluştur", Off)
  val () = ui_hover_label(f, r, menux, menu_item_y(menuy, MENU_TREE_NEW_FOLDER), mw, UI_MENU_ITEM_HEIGHT, "Yeni Klasör Oluştur", Off)
  val () = ui_hover_label(f, r, menux, menu_item_y(menuy, MENU_TREE_RENAME), mw, UI_MENU_ITEM_HEIGHT, "Yeniden Adlandır", Off)
  val () = ui_hover_label(f, r, menux, menu_item_y(menuy, MENU_TREE_DELETE), mw, UI_MENU_ITEM_HEIGHT, "Sil", Off)
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
      ) else k
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

fun edit_insert_typed(b: &Buf >> Buf, ev: &event, scratch: &Buf >> Buf): void = let
  val cap = buf_cap(scratch)
  val raw_n = ev_text_buf(ev, scratch, cap)
  val n = filter_text(scratch, raw_n)
  var j: int = 0
in
  while (ilt(j, n)) (
    let
      val by = buf_get(scratch, j)
    in
      if ige(by, 32) andalso ine(by, 127) then buf_push(b, by) else ();
      j := iadd(j, 1)
    end
  )
end

implement edit_line(b, ev, scratch) =
  if ieq(ctrl_on(ev), 1) then EditNone
  else if ieq(key_is(ev, KEY_BACKSPACE), 1) then edit_backspace(b)
  else if ieq(key_is(ev, KEY_RETURN), 1) then EditSubmit
  else if ieq(key_is(ev, KEY_ESCAPE), 1) then EditCancel
  else let
    val () = edit_insert_typed(b, ev, scratch)
  in
    EditNone
  end

implement act_prompt(dir, cur, name, kind) =
  if is_prompt_newfile(kind) then do_create(dir, name, 0)
  else if is_prompt_newfolder(kind) then do_create(dir, name, 1)
  else if is_prompt_rename(kind) then do_rename(cur, name)
  else let
    val () = seen_buf(dir)
    val () = seen_buf(cur)
    val () = seen_buf(name)
  in
  end
