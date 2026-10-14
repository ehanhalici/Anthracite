#include "data_font/font_span_internal.hats"
staload "data_font/font_hit.sats"
fun queried{b:bool}(slot: !option_vt(FontNativeRun,b),offset: int,query: TextQuery,best: TextHit): TextHit = case+ slot of
  | None_vt() => best | Some_vt(run) => let val+ FontNativeRun(p,token)=run in font_position_hit(p,offset,query,best) end
fun text(runs: !FontSpanRuns,i: int,offset: int,query: TextQuery,best: TextHit): TextHit = let
  val+ @FontSpanRuns(pf,gc | p,n)=runs val (at,restore | cell)=array_ptr_takeout(pf | p,i2sz(airlock_below(i,n)))
  val result=queried(!cell,offset,query,best) prval ()=pf := restore(at) prval ()=fold@(runs)
in result end
fun part(runs: !FontSpanRuns,i: int,p: FontSpanPart,query: TextQuery,best: TextHit): TextHit = case+ p.kind of
  | SpanTextPart() => text(runs,i,p.x,query,best)
  | SpanTabPart() => font_hit_edge(query,p.sourceEnd,iadd(p.x,p.width),font_hit_edge(query,p.sourceStart,p.x,best))
  | SpanLineEndPart() => best
fun walk{n:nat} .<n>. (left: int(n),layout: !FontSpanLayout,query: TextQuery,i: int,best: TextHit): TextHit =
  if left = 0 then best else let val+ FontSpanLayout(a,items,runs,parts,order,count,width,direction)=layout
    val row=buf_get32(order,i) val result=part(runs,row,font_span_part(layout,row),query,best)
  in walk(left-1,layout,query,iadd(i,1),result) end
implement font_span_hit(layout,query) = let val+ FontSpanLayout(a,items,runs,parts,order,n,width,direction)=layout
  val result=walk(n,layout,query,0,@{distance=2147483647,value=0})
in result.value end
