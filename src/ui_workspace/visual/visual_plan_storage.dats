#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "airlock.sats"
staload "data_ast/layout/visual_rows.sats"
staload "data_font/text/span/font_span.sats"
staload "data_font/text/span/font_span_types.sats"
fun initialize{l:addr}{n:nat} .<n>. (pf: array_v(VisualPlanSlot?,l,n) | p: ptr(l),n: int(n)): (array_v(VisualPlanSlot,l,n) | void) =
  if n = 0 then let prval ()=array_v_unnil(pf) in (array_v_nil() | ()) end else let
    prval (head,tail)=array_v_uncons(pf) val ()=ptr_set<VisualPlanSlot>(head | p,VisualPlanEmpty())
    val (rest | ())=initialize(tail | ptr_add<VisualPlanSlot>(p,1),n-1)
  in (array_v_cons(head,rest) | ()) end
implement visual_plans_make(count,lines) = let val n=airlock_nat(imax(0,imin(count,VISUAL_ROW_PLAN_CACHE_ENTRIES)))
  val (pf,gc | p)=array_ptr_alloc<VisualPlanSlot>(i2sz(n)) val (ready | ())=initialize(pf | p,n)
in VisualPlans(ready,gc | p,n,visual_paragraphs_make(lines),0LL) end
fun release(slot: VisualPlanSlot): void = case+ slot of
  | ~VisualPlanEmpty() => () | ~VisualPlanOwned(row,layout,bytes) => font_span_dispose(layout)
fun dispose{l:addr}{n:nat} .<n>. (pf: array_v(VisualPlanSlot,l,n) | p: ptr(l),n: int(n)): (array_v(VisualPlanSlot?,l,n) | void) =
  if n = 0 then let prval ()=array_v_unnil(pf) in (array_v_nil() | ()) end else let
    prval (head,tail)=array_v_uncons(pf) val slot=ptr_get<VisualPlanSlot>(head | p) val ()=release(slot)
    val (rest | ())=dispose(tail | ptr_add<VisualPlanSlot>(p,1),n-1)
  in (array_v_cons(head,rest) | ()) end
implement visual_plans_dispose(plans) = let val+ ~VisualPlans(pf,gc | p,n,paragraphs,bytes)=plans
  val ()=visual_paragraphs_dispose(paragraphs)
  val (uninitialized | ())=dispose(pf | p,n)
in array_ptr_free(uninitialized,gc | p) end
fun slot_memory(slot: !VisualPlanSlot): llint = case+ slot of
  | VisualPlanEmpty() => 0LL | VisualPlanOwned(row,layout,bytes) => bytes
fun take_slot(slot: &VisualPlanSlot >> _,row: int,bytes: &llint >> _): Option_vt(FontSpanLayout) = let
  val ()=bytes := bytes-slot_memory(slot)
  val old=slot val ()=slot := VisualPlanEmpty()
in case+ old of | ~VisualPlanEmpty() => None_vt()
  | ~VisualPlanOwned(saved,layout,bytes) => if ieq(saved,row) then Some_vt(layout)
    else let val ()=font_span_dispose(layout) in None_vt() end end
implement visual_plans_take(plans,row) = let val+ @VisualPlans(pf,gc | p,n,paragraphs,bytes)=plans
  val layout = (if ilt(row, 0) orelse ile(n, 0) then None_vt() else let
    val (at,restore | cell)=array_ptr_takeout(pf | p,i2sz(airlock_below(imod(row,n),n)))
    val l=take_slot(!cell,row,bytes) prval ()=pf := restore(at)
  in l end): Option_vt(FontSpanLayout)
  prval ()=fold@(plans)
in layout end
fun put_slot(slot: &VisualPlanSlot >> _,row: int,layout: FontSpanLayout,bytes: &llint >> _): void = let
  val charge=font_span_memory_bytes(layout) val ()=bytes := bytes-slot_memory(slot)+charge
  val old=slot val ()=release(old)
in slot := VisualPlanOwned(row,layout,charge) end
implement visual_plans_put(plans,row,layout) = let val+ @VisualPlans(pf,gc | p,n,paragraphs,bytes)=plans
  val over=bytes+font_span_memory_bytes(layout) > VISUAL_ROW_PLAN_BUDGET_BYTES
  val () = if ilt(row, 0) orelse ile(n, 0) orelse over then font_span_dispose(layout) else let
    val (at,restore | cell)=array_ptr_takeout(pf | p,i2sz(airlock_below(imod(row,n),n)))
    val ()=put_slot(!cell,row,layout,bytes) prval ()=pf := restore(at)
  in () end
  prval ()=fold@(plans)
in () end
implement visual_plans_bytes(plans) = let val+ VisualPlans(pf,gc | p,n,paragraphs,bytes)=plans
  val+ VisualParagraphs(ppf,pgc | ptr,count,paragraph_bytes)=paragraphs
in bytes+paragraph_bytes+g0int2int_int_llint(n)*g0int2int_int_llint(g0uint2int_size_int(sizeof<VisualPlanSlot>))
  +g0int2int_int_llint(count)*g0int2int_int_llint(g0uint2int_size_int(sizeof<VisualParagraphSlot>))+128LL end
fun forget_slot(slot: &VisualPlanSlot >> _,row: int,bytes: &llint >> _): void = let
  val stale=(case+ slot of | VisualPlanEmpty() => false | VisualPlanOwned(saved,layout,charge) => ige(saved,row)): bool
in if stale then let val ()=bytes := bytes-slot_memory(slot) val old=slot val ()=slot := VisualPlanEmpty()
  in release(old) end else () end
fun forget{l:addr}{n:nat} .<n>. (pf: !array_v(VisualPlanSlot,l,n) | p: ptr(l),n: int(n),row: int,bytes: &llint >> _): void =
  if n = 0 then () else let
    prval (head,tail)=array_v_uncons(pf)
    val ()=forget_slot(!p,row,bytes)
    val ()=forget(tail | ptr_add<VisualPlanSlot>(p,1),n-1,row,bytes)
    prval ()=pf := array_v_cons(head,tail)
  in () end
(* Row indices after a splice point shift, so their cached plans would name other rows. *)
implement visual_plans_forget_from(plans,row) = let val+ @VisualPlans(pf,gc | p,n,paragraphs,bytes)=plans
  val ()=forget(pf | p,n,row,bytes)
  prval ()=fold@(plans)
in () end
