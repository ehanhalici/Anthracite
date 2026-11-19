#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
(* Initial allocation policy; capacities are measured in bytes. *)
macdef VISUAL_PROJECTION_MAKE_BUFFER_INITIAL_BYTES = 256

staload "airlock.sats"
staload "mem.sats"
staload "flag.sats"
staload "data_ast/document/doc.sats"
staload "data_ast/syntax/ast.sats"
staload "data_ast/layout/visual_rows.sats"
staload "ui_workspace/visual/visual_layout.sats"
fun clear{n:nat} .<n>. (left: int(n),mask: !Buf,i: int): void =
  if left = 0 then () else let val ()=buf_set(mask,i,0) in clear(left-1,mask,iadd(i,1)) end
fun is_bullet_mark(d: !Doc, i: int): bool = let
  val k = doc_node_kind(d, i)
  val p_idx = doc_node_parent(d, i)
  val p_k = if ige(p_idx, 0) then doc_node_kind(d, p_idx) else KNone
in
  is_kind(k, KMark) andalso is_kind(p_k, KLi) andalso ilt(doc_find_child(d, p_idx, KTask), 0)
end

fun is_table_pipe_mark(d: !Doc, i: int): bool = let
  val k = doc_node_kind(d, i)
  val p_idx = doc_node_parent(d, i)
  val p_k = if ige(p_idx, 0) then doc_node_kind(d, p_idx) else KNone
in
  is_kind(k, KMark) andalso is_kind(p_k, KTableRow)
end

fun hidden_markup(d: !Doc, i: int): bool = let
  val k = doc_node_kind(d, i)
  val p_idx = doc_node_parent(d, i)
  val p_k = if ige(p_idx, 0) then doc_node_kind(d, p_idx) else KNone
  val h_mark = is_kind(k, KMark) andalso not(is_bullet_mark(d, i)) andalso not(is_table_pipe_mark(d, i))
in
  h_mark orelse is_kind(k, KLinkDest) orelse is_kind(k, KLinkTitle)
  orelse is_kind(k, KTableDelim) orelse is_kind(p_k, KMathb)
  orelse ine(anth_iand(doc_node_flags(d, i), FL_READ_HIDDEN), 0)
end

fun apply_callout_prefix_mask(d: !Doc, mask: !Buf, i: int, st: int): void = let
  val p_idx = doc_node_parent(d, i)
in
  if ige(p_idx, 0) andalso is_kind(doc_node_kind(d, p_idx), KCallout) andalso ige(st, 0) then let
    val ls = doc_line_start(d, doc_line_of(d, st))
  in
    if ige(ls, 0) andalso igt(st, ls) then clear(airlock_span(ls, st), mask, ls) else ()
  end else ()
end

fun apply_preview_node_mask(d: !Doc, mask: !Buf, i: int, st: int, en: int): void = let
  val k = doc_node_kind(d, i)
  val () = apply_callout_prefix_mask(d, mask, i, st)
in
  if hidden_markup(d, i) andalso ige(st, 0) andalso ilt(st, en) then
    clear(airlock_span(st, en), mask, st)
  else if is_bullet_mark(d, i) andalso ige(st, 0) andalso ilt(st, en) then
    buf_set(mask, st, 2)
  else if is_kind(k, KEscape) andalso ige(st, 0) andalso ilt(st, en) then
    buf_set(mask, st, 0)
  else if is_kind(k, KQuote) andalso ige(st, 0) then let
    val cs = doc_node_cstart(d, i)
  in
    if igt(cs, st) then clear(airlock_span(st, cs), mask, st) else ()
  end else ()
end

fun apply_node_mask(d: !Doc, key: VisualKey, mask: !Buf, i: int): void = let
  val st = doc_node_start(d, i)
  val en = doc_node_end(d, i)
  val line = doc_line_of(d, st)
  val l_hid = doc_is_line_hidden(d, line)
  val is_raw = ige(line, key.rawStart) andalso ile(line, key.rawFinish)
in
  if ieq(l_hid, 1) orelse is_on(doc_node_hidden(d, i)) then
    (if ige(st, 0) andalso ilt(st, en) then clear(airlock_span(st, en), mask, st) else ())
  else if not(is_raw) then
    apply_preview_node_mask(d, mask, i, st, en)
  else ()
end

fun nodes{n:nat} .<n>. (left: int(n), d: !Doc, key: VisualKey, mask: !Buf, i: int): void =
  if left = 0 then () else let
    val () = apply_node_mask(d, key, mask, i)
  in
    nodes(left - 1, d, key, mask, iadd(i, 1))
  end

fun emit_bullet(text: !Buf, at: int): int = let
  val () = buf_set(text, at, 226)
  val () = buf_set(text, iadd(at, 1), 128)
  val () = buf_set(text, iadd(at, 2), 162)
in
  iadd(at, 3)
end

fun project{n:nat} .<n>. (left: int(n), d: !Doc, mask: !Buf, text: !Buf, map: !Buf, i: int, at: int): int =
  if left = 0 then let val () = buf_set32(map, i, at) in at end else let
    val () = buf_set32(map, i, at)
    val m = buf_get(mask, i)
    val byte = doc_byte(d, i)
  in
    if ieq(m, 2) then
      project(left - 1, d, mask, text, map, iadd(i, 1), emit_bullet(text, at))
    else if ine(m, 0) orelse ieq(byte, 10) then let
      val () = buf_set(text, at, byte)
    in
      project(left - 1, d, mask, text, map, iadd(i, 1), iadd(at, 1))
    end else
      project(left - 1, d, mask, text, map, iadd(i, 1), at)
  end

extern fun capacity(): VisualRows = "mac#anth_die_box"
implement visual_projection_make(d, key) =
  if igt(doc_len(d), isub(MAX_REC_FUEL, 2)) then capacity() else let val n = doc_len(d)
    val mask = buf_make(imax(1, n)) val () = buf_zero(mask)
    fun fill{k:nat} .<k>. (left: int(k), mask: !Buf, i: int): void =
      if left = 0 then () else let val () = buf_set(mask, i, 1) in fill(left - 1, mask, iadd(i, 1)) end
    val () = fill(airlock_nat(n), mask, 0)
    val () = nodes(airlock_nat(doc_nnodes(d)), d, key, mask, 0)
    val text = buf_make(imax(1, imul(n, 3))) val map = buf_make(imul(iadd(n, 1), 4))
    val length = project(airlock_nat(n), d, mask, text, map, 0, 0) val () = buf_free(mask) val () = buf_set_len(text, length)
    (* nlines+1 row offsets, then the pending-line count (visual_rows_pending). *)
    val words=iadd(doc_nlines(d),2)
    val lines=buf_make(imul(words,WORD32_BYTES)) val ()=buf_zero(lines) val ()=buf_set_len(lines,imul(words,WORD32_BYTES))
  in VisualRows(text,map,lines,buf_make(VISUAL_PROJECTION_MAKE_BUFFER_INITIAL_BYTES),0,key,visual_plans_make(VISUAL_ROW_PLAN_CACHE_ENTRIES,doc_nlines(d))) end
