#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "airlock.sats"
staload "data_ast/layout/visual_rows.sats"
staload "data_font/text/span/font_span.sats"
staload "data_font/text/span/font_span_types.sats"
macdef VISUAL_PLAN_CACHE_ROWS = 128
fun initialize{l:addr}{n:nat} .<n>. (pf: array_v(VisualPlanSlot?,l,n) | p: ptr(l),n: int(n)): (array_v(VisualPlanSlot,l,n) | void) =
  if n = 0 then let prval ()=array_v_unnil(pf) in (array_v_nil() | ()) end else let
    prval (head,tail)=array_v_uncons(pf) val ()=ptr_set<VisualPlanSlot>(head | p,VisualPlanEmpty())
    val (rest | ())=initialize(tail | ptr_add<VisualPlanSlot>(p,1),n-1)
  in (array_v_cons(head,rest) | ()) end
implement visual_plans_make(count) = let val n=airlock_nat(imin(count,VISUAL_PLAN_CACHE_ROWS))
  val (pf,gc | p)=array_ptr_alloc<VisualPlanSlot>(i2sz(n)) val (ready | ())=initialize(pf | p,n)
in VisualPlans(ready,gc | p,n) end
fun release(slot: VisualPlanSlot): void = case+ slot of
  | ~VisualPlanEmpty() => () | ~VisualPlanOwned(row,layout) => font_span_dispose(layout)
fun dispose{l:addr}{n:nat} .<n>. (pf: array_v(VisualPlanSlot,l,n) | p: ptr(l),n: int(n)): (array_v(VisualPlanSlot?,l,n) | void) =
  if n = 0 then let prval ()=array_v_unnil(pf) in (array_v_nil() | ()) end else let
    prval (head,tail)=array_v_uncons(pf) val slot=ptr_get<VisualPlanSlot>(head | p) val ()=release(slot)
    val (rest | ())=dispose(tail | ptr_add<VisualPlanSlot>(p,1),n-1)
  in (array_v_cons(head,rest) | ()) end
implement visual_plans_dispose(plans) = let val+ ~VisualPlans(pf,gc | p,n)=plans
  val (uninitialized | ())=dispose(pf | p,n)
in array_ptr_free(uninitialized,gc | p) end
fun take_slot(slot: &VisualPlanSlot >> _,row: int): Option_vt(FontSpanLayout) = let
  val old=slot val ()=slot := VisualPlanEmpty()
in case+ old of | ~VisualPlanEmpty() => None_vt()
  | ~VisualPlanOwned(saved,layout) => if ieq(saved,row) then Some_vt(layout)
    else let val ()=font_span_dispose(layout) in None_vt() end end
implement visual_plans_take(plans,row) = let val+ @VisualPlans(pf,gc | p,n)=plans
  val (at,restore | cell)=array_ptr_takeout(pf | p,i2sz(airlock_below(imod(row,n),n)))
  val layout=take_slot(!cell,row) prval ()=pf := restore(at) prval ()=fold@(plans)
in layout end
fun put_slot(slot: &VisualPlanSlot >> _,row: int,layout: FontSpanLayout): void = let
  val old=slot val ()=release(old)
in slot := VisualPlanOwned(row,layout) end
implement visual_plans_put(plans,row,layout) = let val+ @VisualPlans(pf,gc | p,n)=plans
  val (at,restore | cell)=array_ptr_takeout(pf | p,i2sz(airlock_below(imod(row,n),n)))
  val ()=put_slot(!cell,row,layout) prval ()=pf := restore(at) prval ()=fold@(plans)
in () end
