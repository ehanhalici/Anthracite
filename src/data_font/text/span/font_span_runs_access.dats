#include "data_font/text/span/font_span_internal.hats"
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
