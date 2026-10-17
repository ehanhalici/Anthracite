fun node_covering_impl(d: !Doc, y: int, oy: int, scroll: int, i: int, best: int): int = node_covering_impl_with_fuel(airlock_nat(MAX_REC_FUEL), d, y, oy, scroll, i, best)

implement node_covering(d, y, oy, scroll, i, best) = node_covering_impl(d, y, oy, scroll, i, best)

fun utf8_char_sz(d: !Doc, i: int, maxlen: int): int =
  if i >= maxlen then 1
  else let
    val b = doc_byte(d, i)
  in
    if b < 128 then 1
    else if b < 224 then (if i + 2 <= maxlen then 2 else maxlen - i)
    else if b < 240 then (if i + 3 <= maxlen then 3 else maxlen - i)
    else (if i + 4 <= maxlen then 4 else maxlen - i)
  end


fun click_char_width(f: !Font, r: !Rend, d: !Doc, i0: int, clen: int, scratch: &Buf >> _): int = let
  val scap = buf_cap(scratch)
  val n = doc_slice_buf(d, i0, iadd(i0, clen), scratch, scap)
in
  imax(font_width_buf(f, r, scratch, n), 1)
end

extern fun click_walk_fuel_exhausted(f: !Font, r: !Rend, d: !Doc, i0: int, len: int, pen: int, x: int, scratch: &Buf >> _): int = "mac#anth_die_int"

fun click_walk_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, r: !Rend, d: !Doc, i0: int, len: int, pen: int, x: int, scratch: &Buf >> _): int =
  if recursion_fuel_available(recfuel) then (
    if ilt(i0, len) andalso ine(doc_byte(d, i0), CHAR_LF) andalso ilt(pen, x) then let
      val clen = utf8_char_sz(d, i0, len)
      val cw = click_char_width(f, r, d, i0, clen, scratch)
    in
      if pen + cw / 2 >= x then i0
      else click_walk_with_fuel(recfuel - 1, f, r, d, iadd(i0, clen), len, iadd(pen, cw), x, scratch)
    end else i0
  ) else click_walk_fuel_exhausted(f, r, d, i0, len, pen, x, scratch)

fun click_place(f: !Font, r: !Rend, d: !Doc, x: int, rst: int, ren: int, colx: int, scratch: &Buf >> _, keep: Toggle): void = let
  val pfx = row_quote_prefix(d, rst)
  val p_rst = iadd(rst, pfx)
  val p_ren = imax(p_rst, ren)
  val base_x = row_base_pos(f, r, d, p_rst, p_ren, colx, scratch)
  val scap = buf_cap(scratch)
  val llen = doc_slice_buf(d, p_rst, p_ren, scratch, scap)
  val target_x = isub(x, base_x)
  val off = anth_ui_click_off(f, r, buf_ptr(scratch), llen, target_x)
  val i0 = iadd(p_rst, off)
in
  if is_on(keep) then doc_set_caret_extend(d, i0) else doc_set_caret_move(d, i0)
end

fun clicked_source_row(d: !Doc,line: int,docy: int,lh: int): @(int,int) = let
  val start=doc_line_start(d,line)
  val finish=if ilt(iadd(line,1),doc_nlines(d)) then doc_line_start(d,iadd(line,1)) else doc_len(d)
  val width=doc_get_wrap(d)
  val row=if width > 0 andalso igt(lh,0) then idiv(imax(0,isub(docy,doc_line_y(d,line))),lh) else 0
  val row_start=if width > 0 then doc_advance_cps(d,start,finish,imul(row,width)) else start
  val row_finish=if width > 0 then doc_advance_cps(d,row_start,finish,width) else finish
in @(row_start,row_finish) end

fun click_doc(f: !Font, r: !Rend, d: !Doc, x: int, y: int, ox: int, pw: int, oy: int, scroll: int, lh: int, scratch: &Buf >> _, keep: Toggle, hitk: &NodeKind >> _, hiti: &int >> _): void = let
  val docy = iadd(isub(y, oy), scroll)
  val line = imax(0, line_at_y_fast(d, docy, lh))
  val colx = editor_colx(f, r, ox, pw)
  val arr_min = gutter_num_end_x(f, r, colx)
  val is_arrow_col = ige(x, arr_min) andalso ilt(x, colx)
  val f_ni = (if is_arrow_col then doc_line_node_foldable(d, line) else ~1) : int
  val ni = (if ige(f_ni, 0) then f_ni else node_covering_impl(d, y, oy, scroll, 0, ~1)) : int
  val hk = (if ige(ni, 0) then doc_node_kind(d, ni) else KNone) : NodeKind
  val () = (hitk := hk; hiti := ni)
  val @(rst,ren)=clicked_source_row(d,line,docy,lh)
in
  if ige(ni, 0) andalso (is_kind(hk, KImage) orelse is_kind(hk, KEmbed)) then doc_set_caret_move(d, doc_node_start(d, ni))
  else if doc_visual_active(d) then let
    val target=visual_click_source(f,d,x,y,colx,oy,scroll,lh,scratch)
  in if is_on(keep) then doc_set_caret_extend(d,target) else doc_set_caret_move(d,target) end
  else click_place(f, r, d, x, rst, ren, colx, scratch, keep)
end

fun click_if(f: !Font, r: !Rend, doc: !Doc, x: int, y: int, ox: int, pw: int, sc: int, lh: int, scratch: &Buf >> _, keep: Toggle, hitk: &NodeKind >> _, hiti: &int >> _, go: Toggle): void =
  if is_on(go) then click_doc(f, r, doc, x, y, ox, pw, 36, sc, lh, scratch, keep, hitk, hiti) else buffer_preserve(scratch)

fun click_stop(rest: Tabs, scratch: &Buf >> _): Tabs = let
  val () = buffer_preserve(scratch)
in
  rest
end

extern fun tabs_click_impl_fuel_exhausted(f: !Font, r: !Rend, ts: Tabs, idx: int, x: int, y: int, ox: int, pw: int, scroll_hint: int, lh: int, scratch: &Buf >> _, keep: Toggle, hitk: &NodeKind >> _, hiti: &int >> _, i: int): Tabs = "mac#anth_die_box"

fun tabs_click_impl_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), f: !Font, r: !Rend, ts: Tabs, idx: int, x: int, y: int, ox: int, pw: int, scroll_hint: int, lh: int, scratch: &Buf >> _, keep: Toggle, hitk: &NodeKind >> _, hiti: &int >> _, i: int): Tabs =
  if recursion_fuel_available(recfuel) then (
    case+ ts of
    | ~TNil() => TNil()
    | ~TCons(doc, path, title, sc, rest) => let
        val () = click_if(f, r, doc, x, y, ox, pw, sc, lh, scratch, keep, hitk, hiti, toggle_of(ieq(i, idx)))
      in
        if ieq(i, idx) then TCons(doc, path, title, sc, click_stop(rest, scratch)) else TCons(doc, path, title, sc, tabs_click_impl_with_fuel(recfuel - 1, f, r, rest, idx, x, y, ox, pw, scroll_hint, lh, scratch, keep, hitk, hiti, iadd(i, 1)))
      end
  ) else tabs_click_impl_fuel_exhausted(f, r, ts, idx, x, y, ox, pw, scroll_hint, lh, scratch, keep, hitk, hiti, i)

fun tabs_click_impl(f: !Font, r: !Rend, ts: Tabs, idx: int, x: int, y: int, ox: int, pw: int, scroll_hint: int, lh: int, scratch: &Buf >> _, keep: Toggle, hitk: &NodeKind >> _, hiti: &int >> _, i: int): Tabs = tabs_click_impl_with_fuel(airlock_nat(MAX_REC_FUEL), f, r, ts, idx, x, y, ox, pw, scroll_hint, lh, scratch, keep, hitk, hiti, i)

implement tabs_click(f, r, ts, idx, x, y, ox, pw, scroll_hint, lh, scratch, keep, hitk, hiti, i) = tabs_click_impl(f, r, ts, idx, x, y, ox, pw, scroll_hint, lh, scratch, keep, hitk, hiti, i)

implement draw_nodes(f, r, d, ox, oy, pw, ph, scroll, lh, vault, c, scratch, i, py, pa, viewmode) = let
  var px: int = column_x(ox, pw)
  var pl: int = ~1
in
  draw_nodes_impl(f, r, d, ox, oy, pw, ph, scroll, lh, vault, c, scratch, i, py, pa, px, pl, viewmode)
end
