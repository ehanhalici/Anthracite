extern fun draw_tabrow_impl_fuel_exhausted(f: !Font, r: !Rend, ts: Tabs, x: int, active: int, i: int): Tabs = "mac#anth_die_box"

fun draw_tabrow_pane_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), f: !Font, r: !Rend, ts: Tabs, x: int, active: int, i: int,
  filter: int, tab_pane: !Buf
): Tabs =
  if recursion_fuel_available(recfuel) then (
    case+ ts of
    | ~TNil() => TNil()
    | ~TCons(doc, path, title, sc, rest) => let
        val match = tab_pane_match(filter, tab_pane, i)
        val tab_w = (if match then tab_item_width(f, r, title) else 0)
        val bx = x
        val next_x = (if match then iadd(bx, iadd(tab_w, 4)) else bx)
        val () = if match then draw_tab_frame(f, r, title, bx, tab_w, i, active) else ()
        val () = touch_doc(doc)
        val () = seen_int(sc)
        val rest2 = draw_tabrow_pane_with_fuel(recfuel - 1, f, r, rest, next_x, active, iadd(i, 1), filter, tab_pane)
      in
        TCons(doc, path, title, sc, rest2)
      end
  ) else draw_tabrow_impl_fuel_exhausted(f, r, ts, x, active, i)

implement draw_tabrow_pane(f, r, ts, x, active, i, filter, tab_pane) =
  draw_tabrow_pane_with_fuel(airlock_nat(MAX_REC_FUEL), f, r, ts, x, active, i, filter, tab_pane)

implement draw_tabrow(f, r, ts, x, active, i) = let
  var empty_b = buf_make(DRAW_TABROW_EMPTY_B_INITIAL_BYTES)
  val res = draw_tabrow_pane(f, r, ts, x, active, i, ~1, empty_b)
  val () = buf_free(empty_b)
in
  res
end

extern fun tab_hit_test_impl_fuel_exhausted(f: !Font, r: !Rend, ts: !Tabs, x: int, click_x: int, i: int, out_ti: &int >> _, out_close: &bool >> _): void = "mac#anth_die_void"

fun tab_hit_step(f: !Font, r: !Rend, title: !Buf, x: int, click_x: int, i: int, out_ti: &int >> _, out_close: &bool >> _): int = let
  val tlen = buf_len(title)
  val tw = if igt(tlen, 0) then font_width_buf(f, r, title, tlen) else 0
  val tab_w = imin(200, imax(100, iadd(tw, 36)))
  val close_x = isub(iadd(x, tab_w), 24)
in
  if ige(click_x, x) andalso ilt(click_x, iadd(x, tab_w)) then (
    out_ti := i; out_close := ige(click_x, close_x); tab_w
  ) else tab_w
end

fun tab_hit_test_pane_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), f: !Font, r: !Rend, ts: !Tabs, x: int, click_x: int, i: int,
  filter: int, tab_pane: !Buf, out_ti: &int >> _, out_close: &bool >> _
): void =
  if recursion_fuel_available(recfuel) then (
    case+ ts of
    | TNil() => ()
    | TCons(_, _, title, _, rest) =>
        if tab_pane_match(filter, tab_pane, i) then let
          val tab_w = tab_hit_step(f, r, title, x, click_x, i, out_ti, out_close)
        in
          if ige(out_ti, 0) then ()
          else tab_hit_test_pane_with_fuel(recfuel - 1, f, r, rest, iadd(x, iadd(tab_w, 4)), click_x, iadd(i, 1), filter, tab_pane, out_ti, out_close)
        end else tab_hit_test_pane_with_fuel(recfuel - 1, f, r, rest, x, click_x, iadd(i, 1), filter, tab_pane, out_ti, out_close)
  ) else tab_hit_test_impl_fuel_exhausted(f, r, ts, x, click_x, i, out_ti, out_close)

implement tab_hit_test_pane(f, r, ts, start_x, click_x, filter, tab_pane, out_ti, out_close) =
  tab_hit_test_pane_with_fuel(airlock_nat(MAX_REC_FUEL), f, r, ts, start_x, click_x, 0, filter, tab_pane, out_ti, out_close)

implement tab_hit_test(f, r, ts, start_x, click_x, out_ti, out_close) = let
  var empty_b = buf_make(TAB_HIT_TEST_EMPTY_B_INITIAL_BYTES)
  val () = tab_hit_test_pane(f, r, ts, start_x, click_x, ~1, empty_b, out_ti, out_close)
  val () = buf_free(empty_b)
in
end

implement tab_find_at_x(f, r, ts, start_x, hover_x, filter, tab_pane) = let
  var ti: int = ~1
  var close: bool = false
  val () = tab_hit_test_pane(f, r, ts, start_x, hover_x, filter, tab_pane, ti, close)
in
  ti
end

fun seal_cs(c: &Cache >> _, scratch: &Buf >> _): void = let
  val saved = c
  val () = c := saved
in
  seen_buf(scratch)
end

fun img_fit_dims(iw: int, ih: int, mw: int, mh: int, out_w: &int >> _, out_h: &int >> _): void =
  if iw <= mw andalso ih <= mh then (out_w := iw; out_h := ih)
  else let
    val fit_h = imax(1, idiv(imul(ih, mw), iw))
  in
    if fit_h <= mh then (out_w := mw; out_h := fit_h)
    else (out_h := mh; out_w := imax(1, idiv(imul(iw, mh), ih)))
  end

fun draw_image_viewer_info(
  f: !Font, r: !Rend, path: !Buf, ox: int, oy: int, pw: int, ph: int, iw: int, ih: int, scratch: &Buf >> _
): void = let
  val () = buffer_clear(scratch)
  val () = base_name(path, scratch)
  val () = buffer_append_string(scratch, " (")
  val () = buffer_append_integer(scratch, iw)
  val () = buffer_append_string(scratch, "x")
  val () = buffer_append_integer(scratch, ih)
  val () = buffer_append_string(scratch, ")")
  val slen = buf_len(scratch)
  val tw = font_width_buf(f, r, scratch, slen)
  val tx = iadd(ox, idiv(isub(pw, tw), 2))
  val ty = isub(iadd(oy, ph), 28)
in
  seen_int(font_draw_buf(f, r, tx, ty, scratch, slen, col_muted()))
end

fun draw_image_viewer_tex(
  f: !Font, r: !Rend, path: !Buf, ox: int, oy: int, pw: int, ph: int,
  tex: uint, iw: int, ih: int, scratch: &Buf >> _
): void = let
  val mw = imax(32, isub(pw, 64))
  val mh = imax(32, isub(ph, 80))
  var dw: int = 0
  var dh: int = 0
  val () = img_fit_dims(iw, ih, mw, mh, dw, dh)
  val qx = iadd(ox, idiv(isub(pw, dw), 2))
  val qy = iadd(oy, idiv(isub(ph, dh), 2))
  val () = rend_quad(r, tex, ShadeRgba, qx, qy, dw, dh, 0.0, 0.0, 1.0, 1.0, col_white())
  val () = ui_draw_border(r, qx, qy, dw, dh, 1, col_line())
in
  draw_image_viewer_info(f, r, path, ox, oy, pw, ph, iw, ih, scratch)
end

fun draw_image_viewer_failed(f: !Font, r: !Rend, path: !Buf, ox: int, oy: int, pw: int, ph: int, scratch: &Buf >> _): void = let
  val p = buffer_c_string(path)
  val () = log_warn_at("src/ui_workspace/render/ui_render.dats", 1108, "VIEWER", "Gorsel yuklenemedi", p)
  val () = buffer_clear(scratch)
  val () = buffer_append_string(scratch, "Gorsel yuklenemedi: ")
  val () = base_name(path, scratch)
  val slen = buf_len(scratch)
  val tw = font_width_buf(f, r, scratch, slen)
  val tx = iadd(ox, idiv(isub(pw, tw), 2))
  val ty = iadd(oy, idiv(ph, 2))
in
  seen_int(font_draw_buf(f, r, tx, ty, scratch, slen, col_muted()))
end

implement draw_image_viewer(f, r, path, ox, oy, pw, ph, c, scratch) = let
  val () = rend_rect(r, ox, oy, pw, ph, col_bg())
  var iw: int = 0
  var ih: int = 0
  val tex = ensure_tex(c, path, r, iw, ih)
in
  if ine(texture_is_valid(tex), 0) andalso igt(iw, 0) andalso igt(ih, 0) then
    draw_image_viewer_tex(f, r, path, ox, oy, pw, ph, tex, iw, ih, scratch)
  else
    draw_image_viewer_failed(f, r, path, ox, oy, pw, ph, scratch)
end

fun draw_tab_content(
  f: !Font, r: !Rend, doc: !Doc, path: !Buf, ox: int, oy: int, pw: int, ph: int,
  sc: int, lh: int, vault: !Buf, c: &Cache >> _, scratch: &Buf >> _, viewmode: ViewMode
): int =
  if is_image_path(path) then
    (draw_image_viewer(f, r, path, ox, oy, pw, ph, c, scratch); sc)
  else
    draw_document_scrolled(f, r, doc, ox, oy, pw, ph, sc, lh, vault, c, scratch, viewmode)

extern fun draw_focus_impl_fuel_exhausted(f: !Font, r: !Rend, ts: Tabs, idx: int, ox: int, oy: int, pw: int, ph: int, lh: int, vault: !Buf, c: &Cache >> _, scratch: &Buf >> _, i: int, viewmode: ViewMode): Tabs = "mac#anth_die_box"

fun pending_anchor_scroll(f: !Font,r: !Rend,doc: !Doc,ox: int,pw: int,ph: int,lh: int,
  vault: !Buf,cache: &Cache >> _,scroll: int,mode: ViewMode): int = let
  val line=doc_take_jump(doc)
in if ilt(line,0) then scroll else let
    val colx=editor_colx(f,r,ox,pw)
    val width=if font_text_active(f) then imax(1,imin(column_w(pw),isub(iadd(ox,pw),iadd(colx,16)))) else column_w(pw)
    val line_height=if font_text_active(f) then font_document_line_height(f,lh) else lh
    val height=prepare_document_layout(f,doc,cache,r,vault,line_height,width,mode)
  in imin(imax(0,isub(height,ph)),imax(0,isub(doc_line_y(doc,line),idiv(ph,3)))) end end

fun draw_focus_impl_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, r: !Rend, ts: Tabs, idx: int, ox: int, oy: int, pw: int, ph: int, lh: int, vault: !Buf, c: &Cache >> _, scratch: &Buf >> _, i: int, viewmode: ViewMode): Tabs =
  if recursion_fuel_available(recfuel) then (
    case+ ts of
    | ~TNil() => let
        val () = seal_cs(c, scratch)
      in
        TNil()
      end
    | ~TCons(doc, path, title, sc, rest) => let
        val scroll=if ieq(i,idx) then pending_anchor_scroll(f,r,doc,ox,pw,ph,lh,vault,c,sc,viewmode) else sc
        val adjusted = if ieq(i, idx) then draw_tab_content(f, r, doc, path, ox, oy, pw, ph, scroll, lh, vault, c, scratch, viewmode) else scroll
        val rest2 = draw_focus_impl_with_fuel(recfuel - 1, f, r, rest, idx, ox, oy, pw, ph, lh, vault, c, scratch, iadd(i, 1), viewmode)
      in
        TCons(doc, path, title, adjusted, rest2)
      end
  ) else draw_focus_impl_fuel_exhausted(f, r, ts, idx, ox, oy, pw, ph, lh, vault, c, scratch, i, viewmode)

fun draw_focus_impl(f: !Font, r: !Rend, ts: Tabs, idx: int, ox: int, oy: int, pw: int, ph: int, lh: int, vault: !Buf, c: &Cache >> _, scratch: &Buf >> _, i: int, viewmode: ViewMode): Tabs = draw_focus_impl_with_fuel(airlock_nat(MAX_REC_FUEL), f, r, ts, idx, ox, oy, pw, ph, lh, vault, c, scratch, i, viewmode)

implement draw_right(f, r, ts, split, idx, ox, oy, pw, ph, lh, vault, c, scratch, viewmode) =
  if is_on(split) then draw_focus(f, r, ts, idx, ox, oy, pw, ph, lh, vault, c, scratch, 0, viewmode)
  else let
    val () = seal_cs(c, scratch)
  in
    ts
  end

implement draw_focus(f, r, ts, idx, ox, oy, pw, ph, lh, vault, c, scratch, i, viewmode) = draw_focus_impl(f, r, ts, idx, ox, oy, pw, ph, lh, vault, c, scratch, i, viewmode)

extern fun node_covering_impl_fuel_exhausted(d: !Doc, y: int, oy: int, scroll: int, i: int, best: int): int = "mac#anth_die_int"

fun task_hit_height(d: !Doc,i: int): int = let
  val line=doc_line_of(d,doc_node_start(d,i))
in idiv(doc_line_step(d,line),imax(1,doc_visual_line_rows(d,line))) end

fun node_covering_impl_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), d: !Doc, y: int, oy: int, scroll: int, i: int, best: int): int =
  if recursion_fuel_available(recfuel) then (
    if ige(i, doc_nnodes(d)) then best
    else let
      val k = doc_node_kind(d, i)
    in
      if is_on(doc_node_hidden(d,i)) orelse (is_inline(k) andalso not(is_kind(k,KEmbed))) then node_covering_impl_with_fuel(recfuel - 1, d, y, oy, scroll, iadd(i, 1), best)
      else let
        val sy = isub(isub(iadd(oy,doc_node_y(d,i)),scroll),if is_kind(k,KEmbed) then 4 else 0)
        val h = if is_kind(k,KTask) then task_hit_height(d,i) else doc_node_height(d, i)
        val best2 = if igt(h, 0) andalso ige(y, sy) andalso ilt(y, iadd(sy, h)) then i else best
      in
        if (is_kind(k,KTask) orelse is_kind(k,KEmbed)) andalso ieq(best2,i) then i else
          node_covering_impl_with_fuel(recfuel - 1, d, y, oy, scroll, iadd(i, 1), best2)
      end
    end
  ) else node_covering_impl_fuel_exhausted(d, y, oy, scroll, i, best)
