fun ensure_index_step(s: &App_record >> _): void = let
  val () = if is_on(s.treedirty) then let
    var trunc: int = 0
    val () = ix_walk_vault(s.vault, s.ixf, s.ixp, trunc)
  in
  end else ()
  val rem = ix_step_all(s.vault, s.ixf, s.ixs, s.ixp, s.ixb, 3000000L)
in
  s.search_state := (if rem > 0 then 1 else 0)
end

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

fun draw_tab_drag_split(f: !Font, r: !Rend, s: &App_record, ox: int, pw: int, h: int, dp: int): void = let
  val half = idiv(pw, 2)
  val mid = iadd(ox, half)
  val eh = isub(h, UI_TOPBAR_HEIGHT)
in
  if ieq(dp, 0) andalso ige(s.hoverx, mid) then
    draw_drop_target(f, r, mid, UI_TOPBAR_HEIGHT, isub(pw, half), eh, "Sag Bolmeye Tasi")
  else if ieq(dp, 1) andalso ilt(s.hoverx, mid) then
    draw_drop_target(f, r, ox, UI_TOPBAR_HEIGHT, half, eh, "Sol Bolmeye Tasi")
  else ()
end

fun draw_tab_drag_overlay(f: !Font, r: !Rend, s: &App_record, ox: int, pw: int, w: int, h: int): void =
  if is_drag_tab(s.drag) andalso ige(s.hovery, UI_TOPBAR_HEIGHT) then let
    val half = idiv(pw, 2)
    val mid = iadd(ox, half)
    val eh = isub(h, UI_TOPBAR_HEIGHT)
    val dp = if s.dragi >= 0 andalso s.dragi < buf_len(s.tab_pane) then buf_get(s.tab_pane, s.dragi) else 0
  in
    if not(is_on(s.split)) then (
      if ige(s.hoverx, mid) then draw_drop_target(f, r, mid, UI_TOPBAR_HEIGHT, isub(pw, half), eh, "Bolunmus Sayfa Ac")
      else ()
    ) else draw_tab_drag_split(f, r, s, ox, pw, h, dp)
  end else ()

fun draw_panes(f: !Font, r: !Rend, a: !App, w: int, h: int): void =
  case+ a of
  | @APP(s) => let
      val () = ensure_index_step(s)
      val () = load_font_if_needed(f, s)
      val sidew = if not(is_side_none(s.side)) then s.sidew else 0
      val ox = sidew
      val pw = isub(w, sidew)
      val () = font_set_px(f, s.fontpx)
      val () = ensure_chrome(f, r, s)
      val lh = font_line_h(f)
      val half = if is_on(s.split) then idiv(pw, 2) else pw
      val () = rend_rect(r, 0, 0, w, h, col_bg())
      val () = draw_topbar_chrome(f, r, s, w)
      val () = draw_editor_panes(f, r, s, ox, half, w, h, lh)
      val () = draw_tab_drag_overlay(f, r, s, ox, pw, w, h)
      val () = draw_topbar_mode(f, r, s, w)
    in
      fold@(a)
    end

fun ui_draw_prompt(f: !Font, r: !Rend, a: !App): void =
  case+ a of
  | @APP(s) => let
      val () = draw_prompt(f, r, s.promptb, s.prompt)
    in
      fold@(a)
    end

fun draw_vault_item(f: !Font, r: !Rend, s: &App_record, mx: int, my: int, mw: int, vi: int): void = let
  var nbuf = buf_make(DRAW_VAULT_ITEM_NBUF_INITIAL_BYTES)
  var pbuf = buf_make(DRAW_VAULT_ITEM_PBUF_INITIAL_BYTES)
  val ry = iadd(my, iadd(68, imul(vi, 26)))
  val poff = buf_get32(s.vmeta, imul(vi, 4))
  val plen = buf_get32(s.vmeta, iadd(imul(vi, 4), 1))
  val noff = buf_get32(s.vmeta, iadd(imul(vi, 4), 2))
  val nlen = buf_get32(s.vmeta, iadd(imul(vi, 4), 3))
  val () = buffer_append_range(pbuf, s.vpaths, poff, iadd(poff, plen))
  val () = buffer_append_range(nbuf, s.vnames, noff, iadd(noff, nlen))
  val is_curr = ieq(c_strcmp(buffer_c_string(pbuf), buffer_c_string(s.vault)), 0)
  val is_hov = ige(s.hoverx, iadd(mx, 16)) andalso ilt(s.hoverx, isub(iadd(mx, mw), 16)) andalso ige(s.hovery, ry) andalso ilt(s.hovery, iadd(ry, 24))
  val () = ui_cell(f, r, iadd(mx, 16), ry, isub(mw, 32), 24, 0, Off, Off, UI_ICON_FOLDER, buffer_c_string(nbuf), buffer_c_string(pbuf), toggle_of(is_curr), toggle_of(is_hov))
  val () = buf_free(nbuf)
in
  buf_free(pbuf)
end

extern fun draw_vault_items_fuel_exhausted(f: !Font, r: !Rend, s: &App_record, mx: int, my: int, mw: int, vi: int, max_cnt: int): void = "mac#anth_die_void"

fun draw_vault_items_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, r: !Rend, s: &App_record, mx: int, my: int, mw: int, vi: int, max_cnt: int): void =
  if recursion_fuel_available(recfuel) then (
    if ige(vi, max_cnt) then ()
    else let
      val () = draw_vault_item(f, r, s, mx, my, mw, vi)
    in
      draw_vault_items_with_fuel(recfuel - 1, f, r, s, mx, my, mw, iadd(vi, 1), max_cnt)
    end
  ) else draw_vault_items_fuel_exhausted(f, r, s, mx, my, mw, vi, max_cnt)

fun draw_vault_items(f: !Font, r: !Rend, s: &App_record, mx: int, my: int, mw: int, vi: int, max_cnt: int): void = draw_vault_items_with_fuel(airlock_nat(MAX_REC_FUEL), f, r, s, mx, my, mw, vi, max_cnt)

fun draw_vault_dialog_body(f: !Font, r: !Rend, s: &App_record, mx: int, my: int, mw: int): void = let
  val () = draw_s(f, r, iadd(mx, 16), iadd(my, 44), "Mevcut kasalardan birini secin veya yeni kasa olusturun:", col_muted())
  val () = draw_vault_items(f, r, s, mx, my, mw, 0, imin(s.vcnt, 6))
  val iy = iadd(my, 248)
  val () = draw_s(f, r, iadd(mx, 16), iy, "Yeni Kasa Konumu (Klasor Yolu):", col_text())
  val qlen = buf_len(s.promptb)
  val () = ui_line_edit_draw(f, r, iadd(mx, 16), iadd(iy, 20), isub(mw, 32), 26, s.promptb, qlen, qlen, On, "ornegin: /home/kullanici/Notlar")
  val by = iadd(my, 310)
  val () = ui_button(f, r, iadd(mx, 16), by, 140, 30, "Ac / Olustur", Off, On)
in
  if igt(buf_len(s.vault), 0) then ui_button(f, r, isub(iadd(mx, mw), 116), by, 100, 30, "Iptal", Off, Off) else ()
end

fun draw_vault_select(f: !Font, r: !Rend, a: !App, w: int, h: int): void =
  case+ a of
  | @APP(s) => let
      val () = if is_on(s.vault_select) then let
        val () = rend_rect(r, 0, 0, w, h, col_overlay())
        val mw = 520
        val mh = 360
        val mx = idiv(isub(w, mw), 2)
        val my = idiv(isub(h, mh), 2)
        val () = ui_pane_begin(r, mx, my, mw, mh, col_bg())
        val () = ui_pane_draw_header(f, r, mx, my, mw, "Kasa Secimi / Vault Secimi", toggle_of(igt(buf_len(s.vault), 0)))
        val () = draw_vault_dialog_body(f, r, s, mx, my, mw)
      in
      end else ()
    in
      fold@(a)
    end

fun menu_item_count(menu: MenuKind): int = case+ menu of
  | MenuNone() => 0
  | MenuText() => 4
  | MenuImage() => 3
  | MenuFileTree() => 4

fun draw_overlay_blur(
  r: !Rend, prompt: PromptKind, menu: MenuKind,
  menux: int, menuy: int, menuw: int, vault_select: Toggle, w: int, h: int
): void = let
  val menu_n = menu_item_count(menu)
  val active = not(is_prompt_none(prompt)) orelse igt(menu_n, 0) orelse is_on(vault_select)
  val () = if active then rend_capture(r) else ()
  val () = if is_on(vault_select) then rend_blur_rect(r, 0, 0, w, h, 4) else ()
  val () = if not(is_prompt_none(prompt)) then rend_blur_rect(r, 12, 68, 256, 56, 6) else ()
in
  if igt(menu_n, 0) then rend_blur_rect(r, menux, menuy,
    menuw, imul(menu_n, UI_MENU_ITEM_HEIGHT), 6) else ()
end

fun app_overlay_state(a: !App): @(Sidebar, PromptKind, MenuKind, int, int, int, Toggle) =
  case+ a of
  | @APP(s) => let
      val result = @(s.side, s.prompt, s.menu, s.menux, s.menuy, s.menuw, s.vault_select)
    in
      fold@(a);
      result
    end

implement app_draw(a, f, r, w, h) = let
  val ()=case+ a of | @APP(s) => (cache_work_begin(s.cache);fold@(a))
  val () = draw_panes(f, r, a, w, h)
  val @(show, prompt, menu, menux, menuy, menuw, vault_select) = app_overlay_state(a)
  val () = if not(is_side_none(show)) then draw_side(f, r, a, h) else ()
  val () = draw_overlay_blur(r, prompt, menu, menux, menuy, menuw, vault_select, w, h)
  val () = ui_draw_prompt(f, r, a)
  val () = ui_draw_menu(f, r, a)
in
  draw_vault_select(f, r, a, w, h)
end
implement app_work_pending(a) = case+ a of | @APP(s) => let
  val pending=cache_work_pending(s.cache)
in fold@(a); pending end
extern fun find_wiki_fuel_exhausted(doc: !Doc, caret: int, k: int): int = "mac#anth_die_int"

fun find_wiki_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), doc: !Doc, caret: int, k: int): int =
  if recursion_fuel_available(recfuel) then (
    if ige(k, doc_nnodes(doc)) then ~1
    else if ile(doc_node_start(doc,k),caret) andalso ilt(caret,doc_node_end(doc,k)) andalso
      (is_kind(doc_node_kind(doc,k),KWiki) orelse is_kind(doc_node_kind(doc,k),KEmbed)) then k
    else find_wiki_with_fuel(recfuel - 1, doc, caret, iadd(k, 1))
  ) else find_wiki_fuel_exhausted(doc, caret, k)

fun find_wiki(doc: !Doc, caret: int, k: int): int = find_wiki_with_fuel(airlock_nat(MAX_REC_FUEL), doc, caret, k)

fun open_or(rest: Tabs, owned: Buf, go: Toggle): Tabs =
  if is_on(go) then tabs_open(rest, owned)
  else let
    val () = buf_free(owned)
  in
    rest
  end

extern fun doc_seek_sub_at_fuel_exhausted(d: !Doc, n: int, a: !Buf, al: int, dp: int, ai: int): bool = "mac#anth_die_bool"

fun doc_seek_sub_at_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, n: int, a: !Buf, al: int, dp: int, ai: int
): bool =
  if recursion_fuel_available(recfuel) then (
    if ige(ai, al) then true
    else if ige(dp, n) then false
    else if ieq(doc_byte(d, dp), buf_get(a, ai)) then
      doc_seek_sub_at_with_fuel(recfuel - 1, d, n, a, al, iadd(dp, 1), iadd(ai, 1))
    else false
  ) else doc_seek_sub_at_fuel_exhausted(d, n, a, al, dp, ai)
