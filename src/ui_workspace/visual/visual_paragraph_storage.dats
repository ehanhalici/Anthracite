#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "airlock.sats"
staload "data_ast/layout/visual_rows.sats"
staload "data_font/native/text/native_text_analysis.sats"
staload "data_font/native/text/native_text_analysis_types.sats"
fun initialize{l:addr}{n:nat} .<n>. (pf: array_v(VisualParagraphSlot?,l,n) | p: ptr(l),n: int(n)): (array_v(VisualParagraphSlot,l,n) | void) =
  if n = 0 then let prval ()=array_v_unnil(pf) in (array_v_nil() | ()) end else let
    prval (head,tail)=array_v_uncons(pf) val ()=ptr_set<VisualParagraphSlot>(head | p,None_vt())
    val (rest | ())=initialize(tail | ptr_add<VisualParagraphSlot>(p,1),n-1)
  in (array_v_cons(head,rest) | ()) end
implement visual_paragraphs_make(count) = let val n=airlock_nat(count)
  val (pf,gc | p)=array_ptr_alloc<VisualParagraphSlot>(i2sz(n)) val (ready | ())=initialize(pf | p,n)
in VisualParagraphs(ready,gc | p,n,0LL) end
implement visual_paragraph_dispose(paragraph) = let val+ ~VisualParagraph(analysis,base,length,bytes)=paragraph
in native_text_analysis_dispose(analysis) end
fun release(slot: VisualParagraphSlot): void = case+ slot of
  | ~None_vt() => () | ~Some_vt(paragraph) => visual_paragraph_dispose(paragraph)
fun dispose{l:addr}{n:nat} .<n>. (pf: array_v(VisualParagraphSlot,l,n) | p: ptr(l),n: int(n)): (array_v(VisualParagraphSlot?,l,n) | void) =
  if n = 0 then let prval ()=array_v_unnil(pf) in (array_v_nil() | ()) end else let
    prval (head,tail)=array_v_uncons(pf) val slot=ptr_get<VisualParagraphSlot>(head | p) val ()=release(slot)
    val (rest | ())=dispose(tail | ptr_add<VisualParagraphSlot>(p,1),n-1)
  in (array_v_cons(head,rest) | ()) end
implement visual_paragraphs_dispose(paragraphs) = let val+ ~VisualParagraphs(pf,gc | p,n,bytes)=paragraphs
  val (uninitialized | ())=dispose(pf | p,n)
in array_ptr_free(uninitialized,gc | p) end
fun slot_bytes(slot: !VisualParagraphSlot): llint = case+ slot of
  | None_vt() => 0LL | Some_vt(paragraph) => let val+ VisualParagraph(a,b,n,bytes)=paragraph in bytes end
fun take_slot(slot: &VisualParagraphSlot >> _,bytes: &llint >> _): VisualParagraphSlot = let
  val old=slot val ()=bytes := bytes-slot_bytes(old) val ()=slot := None_vt()
in old end
implement visual_paragraphs_take(paragraphs,line) = let val+ @VisualParagraphs(pf,gc | p,n,bytes)=paragraphs
  val (at,restore | cell)=array_ptr_takeout(pf | p,i2sz(airlock_below(line,n)))
  val result=take_slot(!cell,bytes) prval ()=pf := restore(at) prval ()=fold@(paragraphs)
in result end
fun put_slot(slot: &VisualParagraphSlot >> _,paragraph: VisualParagraph,bytes: &llint >> _): void = let
  val old=slot val ()=bytes := bytes-slot_bytes(old) val ()=release(old)
  val+ VisualParagraph(a,b,n,charge)=paragraph val ()=bytes := bytes+charge
in slot := Some_vt(paragraph) end
implement visual_paragraphs_put(paragraphs,line,paragraph) = let val+ @VisualParagraphs(pf,gc | p,n,bytes)=paragraphs
  val (at,restore | cell)=array_ptr_takeout(pf | p,i2sz(airlock_below(line,n)))
  val ()=put_slot(!cell,paragraph,bytes) prval ()=pf := restore(at) prval ()=fold@(paragraphs)
in () end
implement visual_paragraph_take(plans,line) = let val+ VisualPlans(pf,gc | p,n,paragraphs,bytes)=plans
in visual_paragraphs_take(paragraphs,line) end
implement visual_paragraph_put(plans,line,paragraph) = let val+ VisualPlans(pf,gc | p,n,paragraphs,bytes)=plans
in visual_paragraphs_put(paragraphs,line,paragraph) end
