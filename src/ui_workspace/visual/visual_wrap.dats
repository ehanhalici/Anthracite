#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
(* Initial allocation policy; capacities are measured in bytes. *)
macdef VISUAL_WRAP_FILL_SCRATCH_INITIAL_BYTES = 256
macdef SHAPE_UNITS_PER_PIXEL = 64

staload "airlock.sats"
staload "mem.sats"
staload "core_runtime/performance.sats"
staload "data_ast/document/doc.sats"
staload "data_ast/layout/visual_rows.sats"
staload "data_font/resources/font.sats"
staload "core_render/render.sats"
staload "data_font/text/font_text.sats"
staload "data_font/text/span/font_span.sats"
staload "data_font/text/span/font_span_types.sats"
staload "data_font/native/text/native_text_analysis.sats"
staload "data_font/native/text/native_text_analysis_types.sats"
staload "ui_workspace/visual/visual_layout.sats"
extern fun exhausted(): int = "mac#anth_die_int"
extern fun fill_exhausted(rows: &VisualRows >> VisualRows): void = "mac#anth_die_void"
extern fun row_shape_failed(): FontSpanLayout = "mac#anth_die_box"
datavtype ExactRow = ExactRow of (int,int,FontSpanLayout)
fun shape_line(f: !Font,analysis: !NativeTextAnalysis,start: int,finish: int): FontSpanLayout =
  case+ font_text_line_plan(f,analysis,start,finish) of
  | ~FontSpanAccepted(layout) => layout | ~FontSpanRejected(error) => row_shape_failed()
fun span_pixels(layout: !FontSpanLayout): int = let val units=font_span_width(layout)
in iadd(idiv(units,SHAPE_UNITS_PER_PIXEL),if ieq(imod(units,SHAPE_UNITS_PER_PIXEL),0) then 0 else 1) end
fun boundary{n:nat} .<n>. (fuel: int(n),flags: !Buf,i: int,endpos: int): int =
  if fuel = 0 then exhausted() else if ige(i,endpos) orelse ine(buf_get(flags,i),0) then i
  else boundary(fuel-1,flags,iadd(i,1),endpos)
(* Prefix advances select a candidate without reshaping overlapping prefixes.
   Logical source positions, not visual bidi caret coordinates, are monotonic. *)
fun fit{n:nat} .<n>. (fuel: int(n),flags: !Buf,advances: !Buf,base: int,start: int,
  stop: int,p: int,last: int,allowed: int,width: int): int =
  if fuel = 0 then exhausted() else let
    val extent=isub(buf_get32(advances,isub(p,base)),buf_get32(advances,isub(start,base)))
    val pixels=iadd(idiv(extent,SHAPE_UNITS_PER_PIXEL),if ieq(imod(extent,SHAPE_UNITS_PER_PIXEL),0) then 0 else 1)
  in if igt(pixels,width) then if igt(allowed,start) then allowed else if igt(last,start) then last else p
    else if ige(p,stop) orelse ieq(buf_get(flags,isub(p,base)),5) then p else let
      val best=if ieq(buf_get(flags,isub(p,base)),3) then p else allowed
      val next=iadd(base,boundary(airlock_nat(MAX_REC_FUEL),flags,iadd(isub(p,base),1),isub(stop,base)))
    in fit(fuel-1,flags,advances,base,start,stop,next,p,best,width) end end
fun previous{n:nat} .<n>. (fuel: int(n),flags: !Buf,p: int,lower: int,best: int): int =
  if fuel = 0 then exhausted() else if ile(p,lower) then best
  else if ige(buf_get(flags,p),3) then p
  else previous(fuel-1,flags,isub(p,1),lower,if ieq(best,lower) andalso igt(buf_get(flags,p),0) then p else best)
(* Joining/kerning can change at a row edge: shape the actual row and shrink
   if needed. A single oversized cluster is allowed, ensuring forward progress. *)
fun exact_row{n:nat} .<n>. (fuel: int(n),f: !Font,analysis: !NativeTextAnalysis,flags: !Buf,base: int,a: int,b: int,target: int): ExactRow =
  if fuel = 0 then let val ignored=exhausted() in ExactRow(b,0,row_shape_failed()) end else let
    val layout=shape_line(f,analysis,isub(a,base),isub(b,base)) val width=span_pixels(layout)
  in if ile(width,target) then ExactRow(b,width,layout) else let
      val prev=iadd(base,previous(airlock_nat(MAX_REC_FUEL),flags,isub(isub(b,base),1),isub(a,base),isub(a,base)))
    in if ile(prev,a) then ExactRow(b,width,layout) else let val ()=font_span_dispose(layout)
      in exact_row(fuel-1,f,analysis,flags,base,a,prev,target) end end end
fun is_specialized_block(k: NodeKind): bool =
  is_kind(k, KQuote) orelse is_kind(k, KCallout) orelse is_kind(k, KCode)
  orelse is_kind(k, KTable) orelse is_kind(k, KTableRow) orelse is_kind(k, KTableCell)

fun advance_wrap_cursor{n:nat} .<n>. (fuel: int(n), d: !Doc, cur: int, nn: int, pos: int): int =
  if fuel = 0 then cur
  else if cur >= nn then nn
  else if doc_node_end(d, cur) <= pos then
    advance_wrap_cursor(fuel - 1, d, iadd(cur, 1), nn, pos)
  else cur

fun block_kind_at{n:nat} .<n>. (fuel: int(n), d: !Doc, pos: int, i: int, nn: int, best_k: NodeKind): NodeKind =
  if fuel = 0 then best_k
  else if i >= nn then best_k
  else let
    val st = doc_node_start(d, i)
  in
    if st > pos then best_k
    else let
      val en = doc_node_end(d, i)
      val covers = ilt(pos, en)
      val k = doc_node_kind(d, i)
      val new_k = if covers andalso is_specialized_block(k) then k else best_k
    in
      block_kind_at(fuel - 1, d, pos, iadd(i, 1), nn, new_k)
    end
  end

fun line_target_width_kind(k: NodeKind, default_w: int): int =
  if is_kind(k, KQuote) orelse is_kind(k, KCallout) then imax(32, isub(default_w, 24))
  else if is_kind(k, KCode) then imax(32, isub(default_w, 16))
  else default_w

fun append_known(rows: &VisualRows >> VisualRows,a: int,b: int,line: int,ordinal: int,width: int): void =
  visual_rows_append(rows,@{start=a,finish=b,width=width,line=line,ordinal=ordinal})

fun line_rows{n:nat} .<n>. (fuel: int(n),f: !Font,rows: &VisualRows >> VisualRows,analysis: !NativeTextAnalysis,flags: !Buf,advances: !Buf,
  base: int,a: int,b: int,line: int,ordinal: int,target_w: int): void =
  if fuel = 0 then fill_exhausted(rows) else if ige(a,b) then () else let
    val+ VisualRows(text,map,lines,data,count,key,plans)=rows
    val next=iadd(base,boundary(airlock_nat(MAX_REC_FUEL),flags,iadd(isub(a,base),1),isub(b,base)))
    val candidate=fit(airlock_nat(MAX_REC_FUEL),flags,advances,base,a,b,next,a,a,target_w)
    val+ ~ExactRow(endpos,width,layout)=exact_row(airlock_nat(MAX_REC_FUEL),f,analysis,flags,base,a,candidate,target_w)
    val ()=visual_plans_put(plans,count,layout)
    val ()=append_known(rows,a,endpos,line,ordinal,width)
  in line_rows(fuel-1,f,rows,analysis,flags,advances,base,endpos,b,line,iadd(ordinal,1),target_w) end

fun mandatory_inside{n:nat} .<n>. (left: int(n),flags: !Buf,index: int): bool =
  if left = 0 then false else ieq(buf_get(flags,index),5) orelse mandatory_inside(left-1,flags,iadd(index,1))
fun wrap_single(f: !Font,rows: &VisualRows >> _,analysis: !NativeTextAnalysis,layout: FontSpanLayout,
  line: int,a: int,b: int,target: int): void = let
  val (flags,advances)=font_span_wrap_metrics(layout,isub(b,a)) val width=span_pixels(layout)
  val simple=ile(width,target) andalso not(mandatory_inside(airlock_nat(imax(0,isub(isub(b,a),1))),flags,1))
  val ()=if simple then let val+ VisualRows(t,m,l,data,count,key,plans)=rows
      val ()=visual_plans_put(plans,count,layout)
    in append_known(rows,a,b,line,0,width) end
    else let val ()=font_span_dispose(layout)
    in line_rows(airlock_nat(MAX_REC_FUEL),f,rows,analysis,flags,advances,a,a,b,line,0,target) end
  val ()=buf_free(flags)
in buf_free(advances) end
fun wrap_analyzed(f: !Font,rows: &VisualRows >> _,analysis: NativeTextAnalysis,source: !Buf,line: int,a: int,b: int,target: int): void = let
  val ()=case+ font_text_line_plan(f,analysis,0,isub(b,a)) of
    | ~FontSpanAccepted(layout) => wrap_single(f,rows,analysis,layout,line,a,b,target)
    | ~FontSpanRejected(error) => let val (flags,advances)=font_text_wrap_metrics(f,source,isub(b,a))
        val ()=line_rows(airlock_nat(MAX_REC_FUEL),f,rows,analysis,flags,advances,a,a,b,line,0,target)
        val ()=buf_free(flags)
      in buf_free(advances) end
  val+ VisualRows(t,m,l,data,count,key,plans)=rows
  val bytes=native_text_analysis_memory_bytes(analysis)
in visual_paragraph_put(plans,line,VisualParagraph(analysis,a,isub(b,a),bytes)) end
fun wrap_projected_line(f: !Font,r: !Rend,rows: &VisualRows >> _,line: int,a: int,b: int,target_w: int,scratch: &Buf >> _): void = let
  val+ VisualRows(text,map,lines,data,count,key,plans)=rows
  val ()=buf_set_len(scratch,0) val ()=buf_append_at(scratch,text,a,isub(b,a))
in case+ font_text_paragraph_analysis(f,scratch,isub(b,a)) of
  | ~NativeAnalysisRejected(error) => fill_exhausted(rows)
  | ~NativeAnalysisAccepted(analysis) => wrap_analyzed(f,rows,analysis,scratch,line,a,b,target_w) end
fun one(f: !Font,r: !Rend,d: !Doc,rows: &VisualRows >> VisualRows,line: int,cur: &int >> _,scratch: &Buf >> _): void = let
  val st=doc_line_start(d,line)
  val raw=if ilt(iadd(line,1),doc_nlines(d)) then doc_line_start(d,iadd(line,1)) else doc_len(d)
  val en=if igt(raw,st) andalso ieq(doc_byte(d,isub(raw,1)),CHAR_LF) then isub(raw,1) else raw
  val a=visual_rows_offset(rows,st) val b=visual_rows_offset(rows,en)
  val+ VisualRows(text,map,lines,data,count,key,plans)=rows val ()=buf_set32(lines,line,count)
  val nn = doc_nnodes(d)
  val () = cur := advance_wrap_cursor(airlock_nat(MAX_REC_FUEL), d, cur, nn, st)
  val k = block_kind_at(airlock_nat(MAX_REC_FUEL), d, st, cur, nn, KNone)
  val target_w = line_target_width_kind(k, key.width)
  val in_scope=ilt(st,key.sourceFinish) andalso igt(raw,key.sourceStart)
in if ieq(a,b) orelse not(in_scope) then append_known(rows,a,b,line,0,0)
  else wrap_projected_line(f,r,rows,line,a,b,target_w,scratch) end

fun lines{n:nat} .<n>. (left: int(n),f: !Font,r: !Rend,d: !Doc,rows: &VisualRows >> VisualRows,i: int,cur: &int >> _,scratch: &Buf >> _): void =
  if left = 0 then let val+ VisualRows(t,m,l,data,count,key,plans)=rows in buf_set32(l,i,count) end
  else let val ()=one(f,r,d,rows,i,cur,scratch) in lines(left-1,f,r,d,rows,iadd(i,1),cur,scratch) end

implement visual_wrap_fill(f,r,d,rows) = let
  val () = performance_note(PERF_WRAP_BUILDS, 1)
  var scratch = buf_make(VISUAL_WRAP_FILL_SCRATCH_INITIAL_BYTES)
  var cur: int = 0
  val () = lines(airlock_nat(doc_nlines(d)), f, r, d, rows, 0, cur, scratch)
in
  buf_free(scratch)
end
