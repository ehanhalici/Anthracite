fun ensure_index_step(s: &App_record >> _): void = search_job_step(s)

fun draw_tab_drag_buf(f: !Font, r: !Rend, w: int, hx: int, hy: int, tbuf: !Buf): void = let
  val n = buf_len(tbuf)
  val tw = if igt(n, 0) then font_width_buf(f, r, tbuf, n) else 40
  val gw = imin(UI_TAB_FIXED_WIDTH, imax(64, iadd(tw, 20)))
  val gx = imax(4, imin(isub(w, iadd(gw, 4)), iadd(hx, 10)))
  val gy = imax(4, iadd(hy, 8))
  val () = ui_draw_shadow(r, gx, gy, gw, 24, 4)
  val () = rend_rect(r, gx, gy, gw, 24, col_menu())
  val () = ui_draw_border(r, gx, gy, gw, 24, 1, col_accent())
in
  if igt(n, 0) then seen_int(font_draw_buf(f, r, iadd(gx, 8), iadd(gy, 3), tbuf, n, col_heading())) else ()
end

fun draw_tab_drag_ghost(f: !Font, r: !Rend, s: &App_record, w: int): void =
  if ige(s.dragi, 0) andalso ilt(s.dragi, tabs_len(s.tabs)) then let
    var tbuf = buf_make(64)
    val () = tabs_get_title(s.tabs, s.dragi, tbuf)
    val () = draw_tab_drag_buf(f, r, w, s.hoverx, s.hovery, tbuf)
  in
    buf_free(tbuf)
  end else ()

fun draw_tab_drag_split_bar(f: !Font, r: !Rend, s: &App_record, ox: int, pw: int, h: int, dp: int): void = let
  val half = idiv(pw, 2)
  val mid = iadd(ox, half)
  val th = s.tb_h
  val on_bar = ilt(s.hovery, th)
  val y0 = if on_bar then 2 else th
  val h0 = if on_bar then isub(th, 4) else isub(h, th)
in
  if ieq(dp, 0) andalso ige(s.hoverx, mid) then (
    if on_bar then ui_draw_border(r, iadd(mid, 4), y0, isub(pw, iadd(half, 8)), h0, 2, col_accent())
    else draw_drop_target(f, r, mid, y0, isub(pw, half), h0, "Sag Bolmeye Tasi")
  ) else if ieq(dp, 1) andalso ilt(s.hoverx, mid) then (
    if on_bar then ui_draw_border(r, ox, y0, isub(half, 4), h0, 2, col_accent())
    else draw_drop_target(f, r, ox, y0, half, h0, "Sol Bolmeye Tasi")
  ) else ()
end

fun draw_tab_drag_overlay(f: !Font, r: !Rend, s: &App_record, ox: int, pw: int, w: int, h: int): void =
  if is_drag_tab(s.drag) then let
    val half = idiv(pw, 2)
    val mid = iadd(ox, half)
    val th = s.tb_h
    val eh = isub(h, th)
    val dp = if s.dragi >= 0 andalso s.dragi < buf_len(s.tab_pane) then buf_get(s.tab_pane, s.dragi) else 0
    val () = if not(is_on(s.split)) then (
      if ige(s.hoverx, mid) andalso ige(s.hovery, th) then
        draw_drop_target(f, r, mid, th, isub(pw, half), eh, "Bolunmus Sayfa Ac")
      else ()
    ) else draw_tab_drag_split_bar(f, r, s, ox, pw, h, dp)
  in
    draw_tab_drag_ghost(f, r, s, w)
  end else ()

fun draw_panes(f: !Font, r: !Rend, a: !App, w: int, h: int): void =
  case+ a of
  | @APP(s) => let
      val () = ensure_index_step(s)
      val () = load_font_if_needed(f, s)
      val () = font_set_px(f, s.fontpx)
      val () = ensure_chrome(f, r, s)
      val () = if not(is_side_none(s.side)) then let
        val max_sw = imax(UI_SIDEBAR_MIN_WIDTH, isub(w, 260))
      in if igt(s.sidew, max_sw) then s.sidew := max_sw else () end else ()
      val sidew = if not(is_side_none(s.side)) then s.sidew else 0
      val ox = sidew
      val pw = imax(1, isub(w, sidew))
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

typedef OverlaySnap = @{
  side= Sidebar, prompt= PromptKind, menu= MenuKind, mv= MenuVariant, sub= SubmenuL1,
  mx= int, my= int, mw= int, sx= int, sy= int, sw= int,
  vault_select= Toggle
}

fun draw_overlay_blur(r: !Rend, ov: OverlaySnap, w: int, h: int): void = let
  val menu_open = not(is_menu_none(ov.menu))
  val mh = if menu_open then menu_var_height(ov.mv) else 0
  val sub_open = menu_open andalso not(is_sub_none(ov.sub)) andalso igt(menu_sub_count(ov.sub), 0)
  val sh = if sub_open then menu_sub_height(ov.sub) else 0
  val floating_p = is_prompt_newfile(ov.prompt) orelse is_prompt_newfolder(ov.prompt)
  val active = floating_p orelse igt(mh, 0) orelse is_on(ov.vault_select)
  val () = if active then rend_capture(r) else ()
  val () = if is_on(ov.vault_select) then rend_blur_rect(r, 0, 0, w, h, 8) else ()
  val () = if floating_p then rend_blur_rect(r, 12, 68, 256, 56, 6) else ()
  val () = if igt(mh, 0) then rend_blur_rect(r, ov.mx, ov.my, ov.mw, mh, 6) else ()
in
  if igt(sh, 0) then rend_blur_rect(r, ov.sx, ov.sy, ov.sw, sh, 6) else ()
end

fun app_overlay_state(a: !App): OverlaySnap =
  case+ a of
  | @APP(s) => let
      val mw = if igt(s.menuw, 0) then s.menuw else UI_MENU_WIDTH
      val result: OverlaySnap = @{
        side= s.side, prompt= s.prompt, menu= s.menu, mv= s.menu_var, sub= s.menu_sub,
        mx= s.menux, my= s.menuy, mw= mw, sx= s.menu_sub_x, sy= s.menu_sub_y, sw= s.menu_sub_w,
        vault_select= s.vault_select
      }
    in
      fold@(a);
      result
    end

fun draw_app_hover_overlays(f: !Font, r: !Rend, a: !App, w: int, h: int): void =
  case+ a of
  | @APP(s) => let
      val () = draw_file_drag_overlay(f, r, s, w, h)
      val () = draw_tab_tooltip(f, r, s, w)
    in
      fold@(a)
    end

implement app_draw(a, f, r, w, h) = let
  val t_draw = performance_now_ns()
  val ()=case+ a of | @APP(s) => let
    val ()= (s.last_w := w; s.last_h := h)
    val ()=if s.flash_until_ns > 0L then
      (if mono_ns() >= s.flash_until_ns then s.flash_until_ns := 0L else ()) else ()
    val ()=if s.tree_flash_until_ns > 0L then
      (if mono_ns() >= s.tree_flash_until_ns then (s.tree_flash_until_ns := 0L; s.tree_flash_row := ~1) else ()) else ()
    val ()=cache_work_begin(s.cache)
  in fold@(a) end
  val t_panes = performance_now_ns()
  val () = draw_panes(f, r, a, w, h)
  val () = performance_phase_end(PERF_PHASE_DRAW_PANES, t_panes)
  val ov = app_overlay_state(a)
  val t_side = performance_now_ns()
  val () = if not(is_side_none(ov.side)) then draw_side(f, r, a, h) else ()
  val () = performance_phase_end(PERF_PHASE_DRAW_SIDEBAR, t_side)
  val t_over = performance_now_ns()
  val () = draw_app_hover_overlays(f, r, a, w, h)
  val () = draw_overlay_blur(r, ov, w, h)
  val () = ui_draw_prompt(f, r, a)
  val () = ui_draw_menu(f, r, a)
  val () = draw_vault_select(f, r, a, w, h)
  val () = performance_phase_end(PERF_PHASE_DRAW_OVERLAYS, t_over)
in
  performance_phase_end(PERF_PHASE_APP_DRAW, t_draw)
end
implement app_work_pending(a) = case+ a of | @APP(s) => let
  val pending=cache_work_pending(s.cache)
  val searching=is_side_search(s.side) andalso ieq(s.search_state,SEARCH_RUNNING)
  val now = mono_ns()
  val expired: bool=if s.flash_until_ns > 0L then now >= s.flash_until_ns else false
  val tree_expired: bool=if s.tree_flash_until_ns > 0L then now >= s.tree_flash_until_ns else false
in fold@(a); pending orelse searching orelse expired orelse tree_expired end
implement app_idle_wait(a) = case+ a of | @APP(s) => let
  val now = mono_ns()
  val d1 = search_flash_wait(now, s.flash_until_ns)
  val d2 = search_flash_wait(now, s.tree_flash_until_ns)
  val delay = if ieq(d1, 0) orelse ieq(d2, 0) then 0
    else if ilt(d1, 0) then d2
    else if ilt(d2, 0) then d1
    else imin(d1, d2)
in fold@(a); delay end
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

extern fun doc_seek_sub_at_fuel_exhausted(d: !Doc, n: int, a: !Buf, al: int, dp: int, ai: int): bool = "mac#anth_die_int"

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
