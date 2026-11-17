#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
(* Initial allocation policy; capacities are measured in bytes. *)
macdef VISUAL_WRAP_FILL_SCRATCH_INITIAL_BYTES = 256
macdef SHAPE_UNITS_PER_PIXEL = 64

staload "airlock.sats"
staload "os/fs.sats"
staload "mem.sats"
staload "core_runtime/performance.sats"
staload "data_ast/document/doc.sats"
staload "data_ast/syntax/ast.sats"
staload "data_ast/layout/visual_rows.sats"
staload "data_font/resources/font.sats"
staload "data_font/resources/private/font_storage.sats"
staload "core_render/render.sats"
staload "data_font/text/font_text.sats"
staload "data_font/text/span/font_span.sats"
staload "data_font/text/span/font_span_types.sats"
staload "data_font/native/text/native_text_analysis.sats"
staload "data_font/native/text/native_text_analysis_types.sats"
staload "ui_workspace/visual/visual_layout.sats"
extern fun exhausted(): int = "mac#anth_die_int"
extern fun fill_exhausted(rows: &VisualRows >> VisualRows): void = "mac#anth_die_void"
datavtype ExactRow = ExactRow of (int, int, Option_vt(FontSpanLayout))

fun units_to_pixels(units: int): int =
  if ile(units, 0) then 0
  else iadd(idiv(units, SHAPE_UNITS_PER_PIXEL), if ieq(imod(units, SHAPE_UNITS_PER_PIXEL), 0) then 0 else 1)

fun span_pixels(layout: !FontSpanLayout): int =
  units_to_pixels(font_span_width(layout))

fun span_extent_pixels(advances: !Buf, base: int, a: int, b: int): int = let
  val ia = imax(0, isub(a, base))
  val ib = imax(ia, isub(b, base))
in units_to_pixels(isub(buf_get32(advances, ib), buf_get32(advances, ia))) end

fun boundary{n:nat} .<n>. (fuel: int(n),flags: !Buf,i: int,endpos: int): int =
  if fuel = 0 then exhausted() else if ige(i,endpos) orelse ine(buf_get(flags,i),0) then i
  else boundary(fuel-1,flags,iadd(i,1),endpos)
(* Prefix advances select a candidate without reshaping overlapping prefixes.
   Logical source positions, not visual bidi caret coordinates, are monotonic. *)
fun fit{n:nat} .<n>. (fuel: int(n),flags: !Buf,advances: !Buf,base: int,start: int,
  stop: int,p: int,last: int,allowed: int,width: int): int =
  if fuel = 0 then exhausted() else let
    val extent=isub(buf_get32(advances,isub(p,base)),buf_get32(advances,isub(start,base)))
    val pixels=units_to_pixels(extent)
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
fun exact_row_fallback(advances: !Buf, base: int, a: int, b: int): ExactRow =
  ExactRow(b, span_extent_pixels(advances, base, a, b), None_vt())

fun exact_row{n:nat} .<n>. (
  fuel: int(n), f: !Font, analysis: !NativeTextAnalysis, flags: !Buf, advances: !Buf,
  base: int, a: int, b: int, target: int
): ExactRow =
  if not(recursion_fuel_available(fuel)) then exact_row_fallback(advances, base, a, b)
  else case+ font_text_line_plan(f, analysis, isub(a, base), isub(b, base)) of
    | ~FontSpanRejected(error) => exact_row_fallback(advances, base, a, b)
    | ~FontSpanAccepted(layout) => let
        val width = span_pixels(layout)
      in
        if ile(width, target) then ExactRow(b, width, Some_vt(layout))
        else let
          val prev = iadd(base, previous(airlock_nat(MAX_REC_FUEL), flags, isub(isub(b, base), 1), isub(a, base), isub(a, base)))
        in
          if ile(prev, a) then ExactRow(b, width, Some_vt(layout))
          else let val () = font_span_dispose(layout) in
            exact_row(fuel - 1, f, analysis, flags, advances, base, a, prev, target)
          end
        end
      end
fun is_specialized_block(k: NodeKind): bool =
  is_kind(k, KQuote) orelse is_kind(k, KCallout) orelse is_kind(k, KCode)
  orelse is_kind(k, KTable) orelse is_kind(k, KTableRow) orelse is_kind(k, KTableCell)

fun advance_wrap_cursor{n:nat} .<n>. (fuel: int(n), d: !Doc, cur: int, nn: int, pos: int): int =
  if fuel = 0 then cur
  else if cur >= nn then nn
  else if doc_node_end(d, cur) <= pos orelse not(is_specialized_block(doc_node_kind(d, cur))) then
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

typedef RowStyle = @{px=int,height=int,ascent=int,top=int}

fun append_known(rows: &VisualRows >> VisualRows,a: int,b: int,line: int,ordinal: int,width: int,rs: RowStyle): void =
  visual_rows_append(rows,@{start=a,finish=b,width=width,line=line,ordinal=ordinal,
    px=rs.px,height=rs.height,ascent=rs.ascent,top=rs.top})

fun put_opt_layout(plans: !VisualPlans, count: int, opt: Option_vt(FontSpanLayout)): void =
  case+ opt of
  | ~None_vt() => ()
  | ~Some_vt(layout) =>
      if ilt(count, VISUAL_ROW_PLAN_CACHE_ENTRIES) then visual_plans_put(plans, count, layout)
      else font_span_dispose(layout)

fun row_fit_measure(
  f: !Font, analysis: !NativeTextAnalysis, flags: !Buf, advances: !Buf,
  base: int, a: int, candidate: int, b: int, target_w: int
): ExactRow = let
  val approx_w = span_extent_pixels(advances, base, a, candidate)
  val on_break = ige(candidate, b) orelse ige(buf_get(flags, isub(candidate, base)), 3)
in
  if on_break andalso ile(approx_w, target_w) then ExactRow(candidate, approx_w, None_vt())
  else exact_row(airlock_nat(MAX_REC_FUEL), f, analysis, flags, advances, base, a, candidate, target_w)
end

fun line_rows{n:nat} .<n>. (fuel: int(n),f: !Font,rows: &VisualRows >> VisualRows,analysis: !NativeTextAnalysis,flags: !Buf,advances: !Buf,
  base: int,a: int,b: int,line: int,ordinal: int,target_w: int,rs: RowStyle): void =
  if fuel = 0 then fill_exhausted(rows) else if ige(a,b) then () else let
    val+ VisualRows(text,map,lines,data,count,key,plans)=rows
    val next=iadd(base,boundary(airlock_nat(MAX_REC_FUEL),flags,iadd(isub(a,base),1),isub(b,base)))
    val candidate=fit(airlock_nat(MAX_REC_FUEL),flags,advances,base,a,b,next,a,a,target_w)
    val+ ~ExactRow(endpos,width,opt_layout)=row_fit_measure(f,analysis,flags,advances,base,a,candidate,b,target_w)
    val ()=put_opt_layout(plans,count,opt_layout)
    val next_a=imax(iadd(a,1),endpos)
    val ()=append_known(rows,a,next_a,line,ordinal,width,rs)
  in line_rows(fuel-1,f,rows,analysis,flags,advances,base,next_a,b,line,iadd(ordinal,1),target_w,rs) end

fun mandatory_inside{n:nat} .<n>. (left: int(n),flags: !Buf,index: int): bool =
  if left = 0 then false else ieq(buf_get(flags,index),5) orelse mandatory_inside(left-1,flags,iadd(index,1))
fun wrap_single(f: !Font,rows: &VisualRows >> _,analysis: !NativeTextAnalysis,layout: FontSpanLayout,
  line: int,a: int,b: int,target: int,rs: RowStyle): void = let
  val (flags,advances)=font_span_wrap_metrics(layout,isub(b,a)) val width=span_pixels(layout)
  val simple=ile(width,target) andalso not(mandatory_inside(airlock_nat(imax(0,isub(isub(b,a),1))),flags,1))
  val ()=if simple then let val+ VisualRows(t,m,l,data,count,key,plans)=rows
      val ()=put_opt_layout(plans,count,Some_vt(layout))
    in append_known(rows,a,b,line,0,width,rs) end
    else let val ()=font_span_dispose(layout)
    in line_rows(airlock_nat(MAX_REC_FUEL),f,rows,analysis,flags,advances,a,a,b,line,0,target,rs) end
  val ()=buf_free(flags)
in buf_free(advances) end
fun wrap_analyzed(f: !Font,rows: &VisualRows >> _,analysis: NativeTextAnalysis,source: !Buf,line: int,a: int,b: int,target: int,rs: RowStyle): void = let
  val ()=case+ font_text_line_plan(f,analysis,0,isub(b,a)) of
    | ~FontSpanAccepted(layout) => wrap_single(f,rows,analysis,layout,line,a,b,target,rs)
    | ~FontSpanRejected(error) => let val (flags,advances)=font_text_wrap_metrics(f,source,isub(b,a))
        val ()=line_rows(airlock_nat(MAX_REC_FUEL),f,rows,analysis,flags,advances,a,a,b,line,0,target,rs)
        val ()=buf_free(flags)
      in buf_free(advances) end
  val+ VisualRows(t,m,l,data,count,key,plans)=rows
  val bytes=native_text_analysis_memory_bytes(analysis)
in visual_paragraph_put(plans,line,VisualParagraph(analysis,a,isub(b,a),bytes)) end
fun line_row_style(d: !Doc,key: VisualKey,line: int): RowStyle = let
  val prev=ilt(line,key.rawStart) orelse igt(line,key.rawFinish)
  val hk=if prev then doc_line_heading_kind(d,line) else KNone
  val @(snum,sden)=doc_heading_scale_of(hk)
in
  if prev andalso igt(snum,sden) then let
    val rpx=imax(1,imin(96,idiv(imul(key.px,snum),sden)))
    val rh=imax(1,idiv(imul(key.height,rpx),imax(1,key.px)))
    val rasc=imax(1,idiv(imul(key.ascent,rpx),imax(1,key.px)))
  in @{px=rpx,height=rh,ascent=rasc,top=doc_heading_top_pad_of(hk)} end
  else @{px=key.px,height=key.height,ascent=key.ascent,top=0}
end
fun wrap_projected_line(f: !Font,r: !Rend,rows: &VisualRows >> _,line: int,a: int,b: int,target_w: int,rs: RowStyle,scratch: &Buf >> _): void = let
  val+ VisualRows(text,map,lines,data,count,key,plans)=rows
  val ()=buf_set_len(scratch,0) val ()=buf_append_at(scratch,text,a,isub(b,a))
  val old_px=font_get_px(f)
  val ()=font_set_px_val(f,rs.px)
  val ()=case+ font_text_paragraph_analysis(f,scratch,isub(b,a)) of
    | ~NativeAnalysisRejected(error) => append_known(rows,a,b,line,0,0,rs)
    | ~NativeAnalysisAccepted(analysis) => wrap_analyzed(f,rows,analysis,scratch,line,a,b,target_w,rs)
in
  font_set_px_val(f,old_px)
end
(* Appends the rows of one source line. exact=false records a placeholder row
   instead of shaping (VISUAL_ROW_PENDING_WIDTH) and returns 1 for it. *)
fun one(f: !Font,r: !Rend,d: !Doc,rows: &VisualRows >> VisualRows,line: int,cur: &int >> _,scratch: &Buf >> _,exact: bool): int = let
  val st=doc_line_start(d,line)
  val raw=if ilt(iadd(line,1),doc_nlines(d)) then doc_line_start(d,iadd(line,1)) else doc_len(d)
  val en0=if igt(raw,st) andalso ieq(doc_byte(d,isub(raw,1)),CHAR_LF) then isub(raw,1) else raw
  val en=if igt(en0,st) andalso ieq(doc_byte(d,isub(en0,1)),CHAR_CR) then isub(en0,1) else en0
  val a=visual_rows_offset(rows,st) val b=visual_rows_offset(rows,en)
  val+ VisualRows(text,map,lines,data,count,key,plans)=rows val ()=buf_set32(lines,line,count)
  val nn = doc_nnodes(d)
  val () = cur := advance_wrap_cursor(airlock_nat(MAX_REC_FUEL), d, cur, nn, st)
  val k = block_kind_at(airlock_nat(MAX_REC_FUEL), d, st, cur, nn, KNone)
  val target_w = line_target_width_kind(k, key.width)
  val rs = line_row_style(d, key, line)
  val in_scope=ilt(st,key.sourceFinish) andalso igt(raw,key.sourceStart)
in if ile(b,a) orelse not(in_scope) then let val ()=append_known(rows,a,imax(a,b),line,0,0,rs) in 0 end
  else if not(exact) then let val ()=append_known(rows,a,b,line,0,VISUAL_ROW_PENDING_WIDTH,rs) in 1 end
  else let val ()=performance_note(PERF_WRAP_LINES,1) val ()=wrap_projected_line(f,r,rows,line,a,b,target_w,rs,scratch) in 0 end end

fun close_lines(rows: !VisualRows,line: int): void = let
  val+ VisualRows(t,m,l,data,count,key,plans)=rows in buf_set32(l,line,count) end

fun lines{n:nat} .<n>. (left: int(n),f: !Font,r: !Rend,d: !Doc,rows: &VisualRows >> VisualRows,i: int,
  cur: &int >> _,scratch: &Buf >> _,exact: bool,pending: int): int =
  if left = 0 then let val ()=close_lines(rows,i) in pending end
  else let val p=one(f,r,d,rows,i,cur,scratch,exact)
  in lines(left-1,f,r,d,rows,iadd(i,1),cur,scratch,exact,iadd(pending,p)) end

fun fill(f: !Font,r: !Rend,d: !Doc,rows: &VisualRows >> VisualRows,exact: bool): void = let
  val () = performance_note(PERF_WRAP_BUILDS, 1)
  var scratch = buf_make(VISUAL_WRAP_FILL_SCRATCH_INITIAL_BYTES)
  var cur: int = 0
  val pending = lines(airlock_nat(doc_nlines(d)), f, r, d, rows, 0, cur, scratch, exact, 0)
  val () = visual_rows_set_pending(rows, pending)
in
  buf_free(scratch)
end
implement visual_wrap_fill(f,r,d,rows) = fill(f,r,d,rows,true)
implement visual_wrap_build(f,r,d,rows,exact) = fill(f,r,d,rows,exact)

(* Splicing: rows of lines that stay as they are are block-copied from the old
   storage, chosen pending lines are shaped in place. Row indices after the
   first shaped line shift, so cached plans from there on are dropped first. *)
fun copy_line(rows: &VisualRows >> VisualRows,old_lines: !Buf,old_data: !Buf,line: int): void = let
  val first=buf_get32(old_lines,line) val count=isub(buf_get32(old_lines,iadd(line,1)),first)
  val+ ~VisualRows(t,m,l,data0,n,k,plans)=rows var data: Buf=data0
  val ()=buf_set32(l,line,n)
  val row_bytes=imul(VISUAL_ROW_WORDS,WORD32_BYTES)
  val ()=buf_ensure(data,imul(iadd(n,count),row_bytes))
  val ()=buf_copy_range(data,imul(n,row_bytes),old_data,imul(first,row_bytes),imul(count,row_bytes))
in rows := VisualRows(t,m,l,data,iadd(n,count),k,plans) end

fun old_pending(old_lines: !Buf,old_data: !Buf,line: int): bool = let
  val first=buf_get32(old_lines,line)
in ilt(first,buf_get32(old_lines,iadd(line,1)))
  andalso ieq(buf_get32(old_data,iadd(imul(first,VISUAL_ROW_WORDS),VISUAL_ROW_WIDTH)),VISUAL_ROW_PENDING_WIDTH) end

fun within_budget(deadline: lint,wrapped: int): bool =
  ieq(wrapped,0) orelse deadline = 0L orelse mono_ns() < deadline

fun forget_plans_once(rows: !VisualRows,wrapped: int): void =
  if igt(wrapped,0) then () else let val+ VisualRows(t,m,l,data,count,key,plans)=rows
  in visual_plans_forget_from(plans,count) end

fun splice{n:nat} .<n>. (left: int(n),f: !Font,r: !Rend,d: !Doc,rows: &VisualRows >> VisualRows,
  old_lines: !Buf,old_data: !Buf,line: int,range: VisualLineRange,deadline: lint,
  cur: &int >> _,scratch: &Buf >> _,wrapped: VisualWrapped): VisualWrapped =
  if left = 0 then let val ()=close_lines(rows,line) in wrapped end else let
    val chosen=ige(line,range.first) andalso ile(line,range.last) andalso old_pending(old_lines,old_data,line)
      andalso within_budget(deadline,wrapped.count)
    val ()=if chosen then let val ()=forget_plans_once(rows,wrapped.count)
        in seen_int(one(f,r,d,rows,line,cur,scratch,true)) end
      else copy_line(rows,old_lines,old_data,line)
    val next: VisualWrapped=if chosen then
        @{count=iadd(wrapped.count,1),first=if ieq(wrapped.count,0) then line else wrapped.first,last=line}
      else wrapped
  in splice(left-1,f,r,d,rows,old_lines,old_data,iadd(line,1),range,deadline,cur,scratch,next) end

fun has_pending_in{n:nat} .<n>. (left: int(n),rows: !VisualRows,line: int): bool =
  if left = 0 then false else visual_rows_line_pending(rows,line) orelse has_pending_in(left-1,rows,iadd(line,1))

implement visual_wrap_lines(f,r,d,rows,range,deadline) = let
  val nlines=doc_nlines(d)
  val first=imax(0,range.first) val last=imin(isub(nlines,1),range.last)
  val nothing: VisualWrapped= @{count=0,first=0,last= ~1}
in if ile(visual_rows_pending(rows),0) orelse igt(first,last)
    orelse not(has_pending_in(airlock_nat(iadd(isub(last,first),1)),rows,first)) then nothing else let
  val before=visual_rows_pending(rows)
  val+ ~VisualRows(t,m,old_lines,old_data,n,k,plans)=rows
  val fresh_lines=buf_make(buf_len(old_lines)) val ()=buf_zero(fresh_lines) val ()=buf_set_len(fresh_lines,buf_len(old_lines))
  var target=VisualRows(t,m,fresh_lines,buf_make(imax(VISUAL_WRAP_FILL_SCRATCH_INITIAL_BYTES,buf_cap(old_data))),0,k,plans)
  var scratch = buf_make(VISUAL_WRAP_FILL_SCRATCH_INITIAL_BYTES)
  var cur: int = 0
  val bounded: VisualLineRange= @{first=first,last=last}
  val wrapped=splice(airlock_nat(nlines),f,r,d,target,old_lines,old_data,0,bounded,deadline,cur,scratch,nothing)
  val ()=visual_rows_set_pending(target,isub(before,wrapped.count))
  val ()=buf_free(scratch) val ()=buf_free(old_lines) val ()=buf_free(old_data)
  val ()=rows := target
in wrapped end end
