#include "data_font/text/span/font_span_internal.hats"
macdef WRAP_PREFIX_MAX_SOURCE_BYTES = 536870910
fun break_code(b: LineBreak): int = case+ b of
  | BreakForbidden() => 1 | BreakOptional() => 3 | BreakMandatory() => 5
fun flags_fill{n:nat} .<n>. (left: int(n),a: !NativeTextAnalysis,flags: !Buf,i: int): void =
  if left = 0 then () else let val+ NativeTextAnalysis(text,bidi,scripts,breaks,graphemes,source_length)=a
    val ()=if native_text_analysis_grapheme(a,i) then
      buf_set(flags,scalar_start(text,i),break_code(native_text_analysis_break(a,i))) else ()
  in flags_fill(left-1,a,flags,iadd(i,1)) end
fun parts_fill{n:nat} .<n>. (left: int(n),layout: !FontSpanLayout,flags: !Buf,advances: !Buf,i: int,length: int): void =
  if left = 0 then () else let
    val part=font_span_part(layout,i)
    val+ FontSpanLayout(a,items,runs,parts,order,count,width,direction)=layout
    val ()=case+ part.kind of
      | SpanTextPart() => font_span_runs_advances(runs,i,flags,advances,length)
      | SpanTabPart() => buf_set32(advances,part.sourceEnd,part.width)
      | _ => ()
  in parts_fill(left-1,layout,flags,advances,iadd(i,1),length) end
fun prefix_fill{n:nat} .<n>. (left: int(n),advances: !Buf,i: int,total: llint): void =
  if left = 0 then () else let
    val next=total+g0int2int_int_llint(buf_get32(advances,i))
    val ()=buf_set32(advances,i,airlock_i32(next))
  in prefix_fill(left-1,advances,iadd(i,1),next) end
extern fun capacity_abort(): void = "mac#anth_die_void"
fun capacity_failed(): @(Buf,Buf) = let val ()=capacity_abort() in @(buf_make(0),buf_make(0)) end
implement font_span_wrap_metrics(layout,length) =
  if ilt(length,0) orelse igt(length,WRAP_PREFIX_MAX_SOURCE_BYTES) then capacity_failed() else let
    val flags=buf_make(iadd(length,1)) val advances=buf_make(imul(iadd(length,1),WORD32_BYTES))
    val+ FontSpanLayout(a,items,runs,parts,order,count,width,direction)=layout
    val ()=flags_fill(airlock_nat(native_text_analysis_count(a)),a,flags,0)
    val ()=buf_set(flags,length,5)
    val ()=parts_fill(count,layout,flags,advances,0,length)
    val ()=prefix_fill(airlock_nat(length),advances,1,0LL)
  in @(flags,advances) end
