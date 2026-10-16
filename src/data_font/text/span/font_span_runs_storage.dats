#include "data_font/text/span/font_span_internal.hats"
fun initialize{l:addr}{n:nat} .<n>. (pf: array_v(FontSpanSlot?,l,n) | p: ptr(l),n: int(n)): (array_v(FontSpanSlot,l,n) | void) =
  if n = 0 then let prval ()=array_v_unnil(pf) in (array_v_nil() | ()) end else let
    prval (head,tail)=array_v_uncons(pf)
    val ()=ptr_set<FontSpanSlot>(head | p,None_vt())
    val (rest | ())=initialize(tail | ptr_add<FontSpanSlot>(p,1),n-1)
  in (array_v_cons(head,rest) | ()) end
implement font_span_runs_make(count) = let val n=airlock_nat(count)
  val (pf,gc | p)=array_ptr_alloc<FontSpanSlot>(i2sz(n))
  val (initialized | ())=initialize(pf | p,n)
in FontSpanRuns(initialized,gc | p,n) end
fun released(slot: FontSpanSlot): void = case+ slot of
  | ~None_vt() => () | ~Some_vt(run) => font_native_run_dispose(run)
fun dispose{l:addr}{n:nat} .<n>. (pf: array_v(FontSpanSlot,l,n) | p: ptr(l),n: int(n)): (array_v(FontSpanSlot?,l,n) | void) =
  if n = 0 then let prval ()=array_v_unnil(pf) in (array_v_nil() | ()) end else let
    prval (head,tail)=array_v_uncons(pf)
    val slot=ptr_get<FontSpanSlot>(head | p) val ()=released(slot)
    val (rest | ())=dispose(tail | ptr_add<FontSpanSlot>(p,1),n-1)
  in (array_v_cons(head,rest) | ()) end
implement font_span_runs_dispose(runs) = let val+ ~FontSpanRuns(pf,gc | p,n)=runs
  val (uninitialized | ())=dispose(pf | p,n)
in array_ptr_free(uninitialized,gc | p) end
