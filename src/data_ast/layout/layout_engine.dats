#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "airlock.sats"
staload "core_runtime/performance.sats"
staload "flag.sats"
staload "data_ast/document/doc.sats"
staload "data_ast/layout/layout_internal.sats"
staload "data_ast/layout/doc_visual.sats"
macdef MATH_BLOCK_PADDING_PIXELS = 12
implement doc_math_block_height(lh) = iadd(lh,MATH_BLOCK_PADDING_PIXELS)

extern fun assign_lines_fuel_exhausted(d: !Doc, lh: int, line: int, y: int, is_read: int, wc: int): int = "mac#anth_die_int"

fun line_source_rows(d: !Doc, line: int, wc: int): int = let
  val nlines = doc_nlines(d)
  val st = doc_line_start(d, line)
  val en = if iadd(line, 1) < nlines then doc_line_start(d, iadd(line, 1)) else doc_len(d)
  val raw_len = isub(en, st)
  val llen = (if igt(raw_len, 0) andalso ieq(doc_byte(d, isub(en, 1)), CHAR_LF) then isub(raw_len, 1) else raw_len) : int
  val cols = doc_codepoints(d, st, iadd(st, llen))
  val actual=doc_visual_line_rows(d,line)
in if igt(actual,0) then actual else if wc > 0 andalso igt(cols,wc) then idiv(iadd(cols,isub(wc,1)),wc) else 1 end

fun line_heading_extra(k: NodeKind, lh: int): int =
  if is_kind(k, KH1) then iadd(idiv(imul(lh, 3), 4), 24)
  else if is_kind(k, KH2) then iadd(idiv(lh, 2), 18)
  else if is_kind(k, KH3) then iadd(idiv(lh, 4), 14)
  else if is_kind(k, KH4) then 12
  else if is_kind(k, KH5) then 8
  else 0

fun advance_node_cursor {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, cur: int, nn: int, st: int
): int =
  if recursion_fuel_available(recfuel) then (
    if cur >= nn then nn
    else if doc_node_start(d, cur) < st then
      advance_node_cursor(recfuel - 1, d, iadd(cur, 1), nn, st)
    else cur
  ) else cur

fun line_scan_extras {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, i: int, nn: int, st: int, en: int, lh: int, is_read: int, acc_w: int, acc_h: int
): @(int, int) =
  if recursion_fuel_available(recfuel) then (
    if i >= nn then @(acc_w, acc_h)
    else let
      val ns = doc_node_start(d, i)
    in
      if ns >= en then @(acc_w, acc_h)
      else let
        val k = doc_node_kind(d, i)
        val h = doc_node_height(d, i)
        val is_widget = is_kind(k, KImage) orelse is_kind(k, KEmbed) orelse is_kind(k, KMathb)
        val wh = if is_kind(k, KMathb) andalso ieq(h, 0) then doc_math_block_height(lh) else h
        val use_w = if is_off(doc_node_hidden(d, i)) andalso is_widget andalso igt(wh, acc_w) then wh else acc_w
        val ex = if ieq(is_read, 1) then line_heading_extra(k, lh) else 0
        val use_h = imax(acc_h, ex)
      in
        line_scan_extras(recfuel - 1, d, iadd(i, 1), nn, st, en, lh, is_read, use_w, use_h)
      end
    end
  ) else @(acc_w, acc_h)

fun line_calc_step(d: !Doc, line: int, nn: int, lh: int, is_read: int, wc: int, cur: &int >> _): int = let
  val hid = doc_is_line_hidden(d, line)
in
  if ieq(hid, 1) then 0
  else let
    val st = doc_line_start(d, line)
    val en = if ilt(iadd(line, 1), doc_nlines(d)) then doc_line_start(d, iadd(line, 1)) else doc_len(d)
    val rows = line_source_rows(d, line, wc)
    val () = cur := advance_node_cursor(airlock_nat(MAX_REC_FUEL), d, cur, nn, st)
    val @(extra, hpad) = line_scan_extras(airlock_nat(MAX_REC_FUEL), d, cur, nn, st, en, lh, is_read, 0, 0)
  in
    if ieq(is_read, 1) andalso igt(extra, 0) then
      iadd(extra, hpad)
    else
      iadd(iadd(imul(rows, lh), extra), hpad)
  end
end

fun assign_lines_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, lh: int, line: int, y: int, is_read: int, wc: int, cur: &int >> _
): int =
  if recursion_fuel_available(recfuel) then (
    if ige(line, doc_nlines(d)) then y
    else let
      val step = line_calc_step(d, line, doc_nnodes(d), lh, is_read, wc, cur)
      val () = doc_layout_store_line(d, line, y, step)
    in
      assign_lines_with_fuel(recfuel - 1, d, lh, iadd(line, 1), iadd(y, step), is_read, wc, cur)
    end
  ) else assign_lines_fuel_exhausted(d, lh, line, y, is_read, wc)

fun assign_lines(d: !Doc, lh: int, line: int, y: int): int = let
  var cur: int = 0
in
  assign_lines_with_fuel(airlock_nat(MAX_REC_FUEL), d, lh, line, y, 0, 80, cur)
end

extern fun stamp_nodes_fuel_exhausted(d: !Doc, lh: int, is_read: int, wc: int, i: int): void = "mac#anth_die_void"

fun stamp_height(d: !Doc,i: int,k: NodeKind): void =
  if not(doc_visual_active(d)) orelse is_inline(k) orelse is_kind(k,KImage) orelse is_kind(k,KEmbed)
    orelse is_kind(k,KMathb) then ()
  else let
    val first=doc_line_of(d,doc_node_start(d,i))
    val finish=doc_line_of(d,imax(doc_node_start(d,i),isub(doc_node_end(d,i),1)))
    val height=isub(iadd(doc_line_y(d,finish),doc_line_step(d,finish)),doc_line_y(d,first))
  in doc_set(d,i,NF_HEIGHT,imax(0,height)) end

fun stamp_y(d: !Doc,lh: int,is_read: int,wc: int,i: int): int = let
  val line=doc_line_of(d,doc_node_start(d,i)) val ly=doc_line_y(d,line) val k=doc_node_kind(d,i)
in if (is_kind(k,KImage) orelse is_kind(k,KEmbed)) andalso ieq(is_read,0) then
  iadd(ly,imul(line_source_rows(d,line,wc),lh)) else ly end

fun stamp_nodes_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, lh: int, is_read: int, wc: int, i: int
): void =
  if recursion_fuel_available(recfuel) then (
    if ige(i, doc_nnodes(d)) then ()
    else let
      val k = doc_node_kind(d, i)
      val y=stamp_y(d,lh,is_read,wc,i)
      val () = doc_layout_store_node_y(d, i, y)
      val () = stamp_height(d,i,k)
    in
      stamp_nodes_with_fuel(recfuel - 1, d, lh, is_read, wc, iadd(i, 1))
    end
  ) else stamp_nodes_fuel_exhausted(d, lh, is_read, wc, i)

fun stamp_nodes(d: !Doc, lh: int, is_read: int, wc: int, i: int): void =
  stamp_nodes_with_fuel(airlock_nat(MAX_REC_FUEL), d, lh, is_read, wc, i)

extern fun fill_liney_fuel_exhausted(d: !Doc, i: int, nlines: int, lh: int, y: int, wc: int): int = "mac#anth_die_int"

fun plain_line_step(d: !Doc, i: int, lh: int, wc: int): int = imul(line_source_rows(d,i,wc),lh)

fun fill_liney_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, i: int, nlines: int, lh: int, y: int, wc: int
): int =
  if recursion_fuel_available(recfuel) then (
    if ilt(i, nlines) then let
      val step = plain_line_step(d, i, lh, wc)
      val () = doc_layout_store_line(d, i, y, step)
    in
      fill_liney_with_fuel(recfuel - 1, d, iadd(i, 1), nlines, lh, iadd(y, step), wc)
    end else y
  ) else fill_liney_fuel_exhausted(d, i, nlines, lh, y, wc)

fun fill_plain_lines(d: !Doc, lh: int, nlines: int, wc: int): int =
  fill_liney_with_fuel(airlock_nat(MAX_REC_FUEL), d, 0, nlines, lh, 0, wc)

fun doc_layout_calc(d: !Doc, lh: int, n: int, is_read: int, colw: int): int = let
  val wc = doc_wrap_cols(colw)
in
  if is_off(doc_is_md(d)) orelse ieq(n, 0) then
    fill_plain_lines(d, lh, doc_nlines(d), wc)
  else let
    val () = doc_layout_ast_prepare(d, lh)
    var cur: int = 0
    val t = assign_lines_with_fuel(airlock_nat(MAX_REC_FUEL), d, lh, 0, 0, is_read, wc, cur)
    val () = stamp_nodes(d, lh, is_read, wc, 0)
  in
    t
  end
end

implement doc_get_wrap(d) = let
  val wrap = doc_layout_cached_wrap(d)
in
  if igt(wrap, 0) then wrap else 80
end

implement doc_wrap_cols(colw) = let
  val width = isub(colw, 80)
in
  if width <= 180 then 25 else imin(120, idiv(width, 9))
end

implement doc_layout_mode(d, line_height, is_read, colw) = let
  val lh = if ilt(line_height, 8) then 8 else line_height
  val version = doc_layout_version(d)
  val wrap = doc_wrap_cols(colw)
  val key = iadd(lh, imul(wrap, 1000))
in
  if doc_layout_cache_match(d, version, key, is_read) then
    doc_layout_cache_height(d)
  else let
    val () = performance_note(PERF_LAYOUT_BUILDS, 1)
    val height = doc_layout_calc(d, lh, doc_nnodes(d), is_read, colw)
    val () = doc_visual_index(d)
    val () = doc_layout_cache_store(d, version, key, height, is_read, wrap)
  in
    height
  end
end

implement doc_layout(d, line_height) =
  doc_layout_mode(d, line_height, 0, 800)
