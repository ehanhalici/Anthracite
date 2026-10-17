#include "data_font/text/span/font_span_internal.hats"
staload "data_font/glyph/position/glyph_position.sats"
staload "data_font/glyph/position/glyph_position_types.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
extern fun span_slot_failed(): void = "mac#anth_die_void"
fun install(slot: &FontSpanSlot >> _,run: FontNativeRun): void = case+ slot of
  | ~None_vt() => slot := Some_vt(run)
  | ~Some_vt(old) => let val ()=font_native_run_dispose(old)
    val ()=slot := Some_vt(run) in span_slot_failed() end
implement font_span_runs_put(runs,index,run) = let val+ @FontSpanRuns(pf,gc | p,n)=runs
  val (at,restore | cell)=array_ptr_takeout(pf | p,i2sz(airlock_below(index,n)))
  val ()=install(!cell,run) prval ()=pf := restore(at) prval ()=fold@(runs)
in () end
fun measure(slot: !FontSpanSlot): FontRunExtent = case+ slot of
  | None_vt() => @{status=FontRunGraph(),xAdvance=0,yAdvance=0,drawn=0}
  | Some_vt(run) => let val+ FontNativeRun(positioned,token)=run in font_run_measure(positioned) end
implement font_span_runs_measure(runs,index) = let val+ @FontSpanRuns(pf,gc | p,n)=runs
  val (at,restore | cell)=array_ptr_takeout(pf | p,i2sz(airlock_below(index,n)))
  val result=measure(!cell) prval ()=pf := restore(at) prval ()=fold@(runs)
in result end
fun check(slot: !FontSpanSlot,f: !Font): FontRunStatus = case+ slot of
  | None_vt() => FontRunGraph() | Some_vt(run) => font_native_run_check(f,run)
implement font_span_runs_check(runs,index,f) = let val+ @FontSpanRuns(pf,gc | p,n)=runs
  val (at,restore | cell)=array_ptr_takeout(pf | p,i2sz(airlock_below(index,n)))
  val result=check(!cell,f) prval ()=pf := restore(at) prval ()=fold@(runs)
in result end
fun draw(slot: !FontSpanSlot,f: !Font,r: !Rend,x: double,y: double,color: uint): FontRunExtent = case+ slot of
  | None_vt() => @{status=FontRunGraph(),xAdvance=0,yAdvance=0,drawn=0}
  | Some_vt(run) => font_draw_native_run(f,r,run,x,y,color)
implement font_span_runs_draw(runs,index,f,r,x,y,color) = let val+ @FontSpanRuns(pf,gc | p,n)=runs
  val (at,restore | cell)=array_ptr_takeout(pf | p,i2sz(airlock_below(index,n)))
  val result=draw(!cell,f,r,x,y,color) prval ()=pf := restore(at) prval ()=fold@(runs)
in result end

fun cluster_interior{n:nat} .<n>. (left: int(n),flags: !Buf,i: int): void =
  if left = 0 then () else let val ()=buf_set(flags,i,0)
  in cluster_interior(left-1,flags,iadd(i,1)) end
fun cluster_advance(v: GlyphView,flags: !Buf,advances: !Buf,length: int): void = let
  val a=imax(0,v.core.sourceStart) val b=imin(length,v.core.sourceEnd)
in if ile(b,a) then () else let
    val old=buf_get32(advances,b)
    val sum=g0int2int_int_llint(old)+g0int2int_int_llint(imax(0,v.position.xAdvance))
    val ()=buf_set32(advances,b,airlock_i32(sum))
  in cluster_interior(airlock_nat(isub(isub(b,a),1)),flags,iadd(a,1)) end
end
fun advances_walk{n:nat} .<n>. (left: int(n),p: !GlyphPositioned(1),node: int,
  flags: !Buf,advances: !Buf,length: int): void =
  if left = 0 then () else let val v=glyph_position_query(p,node)
    val ()=cluster_advance(v,flags,advances,length)
  in advances_walk(left-1,p,v.links.next,flags,advances,length) end
fun advances_slot(slot: !FontSpanSlot,flags: !Buf,advances: !Buf,length: int): void = case+ slot of
  | None_vt() => () | Some_vt(run) => let val+ FontNativeRun(p,token)=run
    val meta=glyph_position_meta(p)
  in advances_walk(airlock_nat(meta.live),p,meta.head,flags,advances,length) end
implement font_span_runs_advances(runs,index,flags,advances,length) = let val+ @FontSpanRuns(pf,gc | p,n)=runs
  val (at,restore | cell)=array_ptr_takeout(pf | p,i2sz(airlock_below(index,n)))
  val ()=advances_slot(!cell,flags,advances,length)
  prval ()=pf := restore(at) prval ()=fold@(runs)
in () end
