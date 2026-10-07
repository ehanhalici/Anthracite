#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "mem.sats"
staload "core_platform/x11.sats"
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

staload "ui_workspace/ui_widgets.sats"

implement draw_menu(f, r, menu, menux, menuy) = let
  val n = if ieq(menu, 1) then 4 else if ieq(menu, 2) then 3 else if ieq(menu, 3) then 4 else 0
  val mw = 230
  val mh = imul(n, 24)
  val () = if igt(n, 0) then ui_pane_begin(r, menux, menuy, mw, mh, col_menu()) else ()
in
  if ieq(menu, 1) then let
    val () = ui_hover_label(f, r, menux, iadd(menuy, 0), mw, 24, "Kes", 0)
    val () = ui_hover_label(f, r, menux, iadd(menuy, 24), mw, 24, "Kopyala", 0)
    val () = ui_hover_label(f, r, menux, iadd(menuy, 48), mw, 24, "Yapıştır", 0)
    val () = ui_hover_label(f, r, menux, iadd(menuy, 72), mw, 24, "Biçimlendirmeyi Temizle", 0)
  in
  end else if ieq(menu, 2) then let
    val () = ui_hover_label(f, r, menux, iadd(menuy, 0), mw, 24, "Görseli Kopyala", 0)
    val () = ui_hover_label(f, r, menux, iadd(menuy, 24), mw, 24, "Dosya Konumunu Aç", 0)
    val () = ui_hover_label(f, r, menux, iadd(menuy, 48), mw, 24, "Dokümandan Kaldır", 0)
  in
  end else if ieq(menu, 3) then let
    val () = ui_hover_label(f, r, menux, iadd(menuy, 0), mw, 24, "Yeni Dosya Oluştur", 0)
    val () = ui_hover_label(f, r, menux, iadd(menuy, 24), mw, 24, "Yeni Klasör Oluştur", 0)
    val () = ui_hover_label(f, r, menux, iadd(menuy, 48), mw, 24, "Yeniden Adlandır", 0)
    val () = ui_hover_label(f, r, menux, iadd(menuy, 72), mw, 24, "Sil", 0)
  in
  end else ()
end

implement draw_prompt(f, r, b, prompt) =
  if ieq(prompt, 0) then let
    val _n = buf_len(b)
  in
  end else let
    val title =
      if ieq(prompt, 1) then "Yeni Dosya:"
      else if ieq(prompt, 2) then "Yeni Klasör:"
      else "Yeniden Adlandır:"
    val () = ui_pane_begin(r, 12, 68, 256, 56, col_menu())
    val _dt = draw_s(f, r, 18, 72, title, col_accent())
    val n = buf_len(b)
    val () = ui_line_edit_draw(f, r, 16, 92, 248, 26, b, n, n, 1, "Isim girin...")
  in
  end

fun buf_utf8_prev(p: ptr, n: int): int =
  if n <= 1 then 0
  else let
    fun back(p: ptr, n: int, k: int, limit: int): int =
      if k <= 0 then 0
      else if limit <= 0 then k
      else let
        val by = mem_byte(p, n, isub(k, 1))
      in
        if by < 128 orelse by >= 192 then isub(k, 1)
        else back(p, n, isub(k, 1), isub(limit, 1))
      end
  in
    back(p, n, n, 4)
  end

implement edit_line(b, ev, scratch) =
  if ieq(ctrl_on(ev), 1) then 0
  else if ieq(key_is(ev, 4), 1) then let
    val n = buf_len(b)
  in
    if igt(n, 0) then let
      val p = buf_ptr(b)
      val prev = buf_utf8_prev(p, n)
      val () = buf_set_len(b, prev)
    in
      1
    end else 1
  end else if ieq(key_is(ev, 8), 1) then 2
  else if ieq(key_is(ev, 10), 1) then 3
  else let
    val cap = buf_cap(scratch)
    val n = ev_text(ev, buf_ptr(scratch), cap)
    var i: int = 0
    var has_esc: int = 0
  in
    while (ilt(i, n)) (
      let
        val by = mem_byte(buf_ptr(scratch), cap, i)
      in
        if ieq(by, 27) then has_esc := 1 else ();
        i := iadd(i, 1)
      end
    );
    if ieq(has_esc, 1) then 0
    else let
      var j: int = 0
    in
      while (ilt(j, n)) (
        let
          val by = mem_byte(buf_ptr(scratch), cap, j)
        in
          if ige(by, 32) andalso ine(by, 127) then buf_push(b, by) else ();
          j := iadd(j, 1)
        end
      );
      0
    end
  end

implement act_prompt(dir, cur, name, kind) =
  if ieq(kind, 1) then do_create(dir, name, 0)
  else if ieq(kind, 2) then do_create(dir, name, 1)
  else if ieq(kind, 3) then do_rename(cur, name)
  else let
    val _a = buf_len(dir)
    val _b = buf_len(cur)
    val _c = buf_len(name)
  in
  end
