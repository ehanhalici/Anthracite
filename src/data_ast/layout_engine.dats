#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

staload "airlock.sats"
staload "flag.sats"
staload "data_ast/doc.sats"
staload "data_ast/layout_internal.sats"
staload "data_ast/doc_visual.sats"

extern fun assign_lines_exh(d: !Doc, lh: int, line: int, y: int, is_read: int, wc: int): int = "mac#anth_die_int"

fun line_source_rows(d: !Doc, line: int, wc: int): int = let
  val nlines = doc_nlines(d)
  val st = doc_line_start(d, line)
  val en = if iadd(line, 1) < nlines then doc_line_start(d, iadd(line, 1)) else doc_len(d)
  val raw_len = isub(en, st)
  val llen = (if igt(raw_len, 0) andalso ieq(doc_byte(d, isub(en, 1)), 10) then isub(raw_len, 1) else raw_len) : int
  val cols = doc_codepoints(d, st, iadd(st, llen))
  val actual=doc_visual_line_rows(d,line)
in if igt(actual,0) then actual else if wc > 0 andalso igt(cols,wc) then idiv(iadd(cols,isub(wc,1)),wc) else 1 end

fun line_calc_step(d: !Doc, line: int, n: int, lh: int, is_read: int, wc: int): int = let
  val st=doc_line_start(d,line)
  val en=if ilt(iadd(line,1),doc_nlines(d)) then doc_line_start(d,iadd(line,1)) else doc_len(d)
  val rows=line_source_rows(d,line,wc)
  val hid = doc_layout_line_hidden(d, st, en, n)
  val extra = if ieq(hid, 1) then 0 else doc_layout_widget_height(d, st, en, n)
  val hpad = (if ieq(hid, 1) orelse ieq(is_read, 0) then 0 else doc_layout_heading_padding(d, st, en, n, lh))
in
  if ieq(hid, 1) then 0
  else if ieq(is_read, 1) andalso igt(extra, 0) then
    iadd(extra, hpad)
  else
    iadd(iadd(imul(rows, lh), extra), hpad)
end

fun assign_lines_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, lh: int, line: int, y: int, is_read: int, wc: int
): int =
  if recfuel > 0 then (
    if ige(line, doc_nlines(d)) then y
    else let
      val step = line_calc_step(d, line, doc_nnodes(d), lh, is_read, wc)
      val () = doc_layout_store_line(d, line, y, step)
    in
      assign_lines_m(recfuel - 1, d, lh, iadd(line, 1), iadd(y, step), is_read, wc)
    end
  ) else assign_lines_exh(d, lh, line, y, is_read, wc)

fun assign_lines(d: !Doc, lh: int, line: int, y: int): int =
  assign_lines_m(airlock_nat(MAX_REC_FUEL), d, lh, line, y, 0, 80)

extern fun stamp_nodes_exh(d: !Doc, lh: int, is_read: int, wc: int, i: int): void = "mac#anth_die_void"

fun stamp_height(d: !Doc,i: int,k: NodeKind): void =
  if not(doc_visual_active(d)) orelse is_kind(k,KImage) orelse is_kind(k,KEmbed) orelse is_kind(k,KMathb) then ()
  else let
    val first=doc_line_of(d,doc_node_start(d,i))
    val finish=doc_line_of(d,imax(doc_node_start(d,i),isub(doc_node_end(d,i),1)))
    val height=isub(iadd(doc_line_y(d,finish),doc_line_step(d,finish)),doc_line_y(d,first))
  in doc_set(d,i,NF_HEIGHT,imax(0,height)) end

fun stamp_y(d: !Doc,lh: int,is_read: int,wc: int,i: int): int = let
  val line=doc_line_of(d,doc_node_start(d,i)) val ly=doc_line_y(d,line) val k=doc_node_kind(d,i)
in if (is_kind(k,KImage) orelse is_kind(k,KEmbed)) andalso ieq(is_read,0) then
  iadd(ly,imul(line_source_rows(d,line,wc),lh)) else ly end

fun stamp_nodes_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, lh: int, is_read: int, wc: int, i: int
): void =
  if recfuel > 0 then (
    if ige(i, doc_nnodes(d)) then ()
    else let
      val k = doc_node_kind(d, i)
      val y=stamp_y(d,lh,is_read,wc,i)
      val () = doc_layout_store_node_y(d, i, y)
      val () = stamp_height(d,i,k)
    in
      stamp_nodes_m(recfuel - 1, d, lh, is_read, wc, iadd(i, 1))
    end
  ) else stamp_nodes_exh(d, lh, is_read, wc, i)

fun stamp_nodes(d: !Doc, lh: int, is_read: int, wc: int, i: int): void =
  stamp_nodes_m(airlock_nat(MAX_REC_FUEL), d, lh, is_read, wc, i)

extern fun fill_liney_exh(d: !Doc, i: int, nlines: int, lh: int, y: int, wc: int): int = "mac#anth_die_int"

fun plain_line_step(d: !Doc, i: int, lh: int, wc: int): int = imul(line_source_rows(d,i,wc),lh)

fun fill_liney_m {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, i: int, nlines: int, lh: int, y: int, wc: int
): int =
  if recfuel > 0 then (
    if ilt(i, nlines) then let
      val step = plain_line_step(d, i, lh, wc)
      val () = doc_layout_store_line(d, i, y, step)
    in
      fill_liney_m(recfuel - 1, d, iadd(i, 1), nlines, lh, iadd(y, step), wc)
    end else y
  ) else fill_liney_exh(d, i, nlines, lh, y, wc)

fun fill_plain_lines(d: !Doc, lh: int, nlines: int, wc: int): int =
  fill_liney_m(airlock_nat(MAX_REC_FUEL), d, 0, nlines, lh, 0, wc)

fun doc_layout_calc(d: !Doc, lh: int, n: int, is_read: int, colw: int): int = let
  val wc = doc_wrap_cols(colw)
in
  if is_off(doc_is_md(d)) orelse ieq(n, 0) then
    fill_plain_lines(d, lh, doc_nlines(d), wc)
  else let
    val () = doc_layout_ast_prepare(d, lh)
    val t = assign_lines_m(airlock_nat(MAX_REC_FUEL), d, lh, 0, 0, is_read, wc)
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
    val height = doc_layout_calc(d, lh, doc_nnodes(d), is_read, colw)
    val () = doc_layout_cache_store(d, version, key, height, is_read, wrap)
  in
    height
  end
end

implement doc_layout(d, line_height) =
  doc_layout_mode(d, line_height, 0, 800)
