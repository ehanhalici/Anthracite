#include "data_font/text/span/font_span_internal.hats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/position/glyph_position_types.sats"
macdef SPAN_ALLOCATION_ALLOWANCE_BYTES = 64LL
macdef SPAN_RUN_OBJECT_ALLOWANCE_BYTES = 1024LL
fun buffer_bytes(buffer: !Buf): llint = g0int2int_int_llint(buf_cap(buffer))+SPAN_ALLOCATION_ALLOWANCE_BYTES
fun array_bytes(count: int,element: size_t): llint =
  g0int2int_int_llint(count)*g0int2int_int_llint(g0uint2int_size_int(element))+SPAN_ALLOCATION_ALLOWANCE_BYTES
fun native_run_bytes(run: !FontNativeRun): llint = let
  val+ FontNativeRun(positioned,token)=run val+ PositionFrozen(glyphs,scale,direction)=positioned
  val+ GlyphRun(phase,meta,storage)=glyphs val+ GlyphStorage(capacity,cores,links,positions)=storage
in array_bytes(capacity,sizeof<GlyphCore>)+array_bytes(capacity,sizeof<GlyphLinks>)
  +array_bytes(capacity,sizeof<GlyphPosition>)+SPAN_RUN_OBJECT_ALLOWANCE_BYTES end
fun slot_bytes(slot: !FontSpanSlot): llint = case+ slot of
  | None_vt() => 0LL | Some_vt(run) => native_run_bytes(run)
fun runs_bytes{n:nat} .<n>. (left: int(n),runs: !FontSpanRuns,i: int): llint =
  if left = 0 then 0LL else let val+ @FontSpanRuns(pf,gc | p,n)=runs
    val (at,restore | cell)=array_ptr_takeout(pf | p,i2sz(airlock_below(i,n)))
    val bytes=slot_bytes(!cell) prval ()=pf := restore(at) prval ()=fold@(runs)
  in bytes+runs_bytes(left-1,runs,iadd(i,1)) end
implement font_span_memory_bytes(layout) = let
  val+ FontSpanLayout(analysis,items,runs,parts,order,n,width,direction)=layout
  val+ NativeTextItems(item_rows,ni)=items val+ FontSpanRuns(pf,gc | p,nr)=runs
in native_text_analysis_memory_bytes(analysis)+array_bytes(ni,sizeof<NativeTextItem>)+array_bytes(n,sizeof<FontSpanPart>)
  +buffer_bytes(order)+array_bytes(nr,sizeof<FontSpanSlot>)+runs_bytes(nr,runs,0)+SPAN_RUN_OBJECT_ALLOWANCE_BYTES end
