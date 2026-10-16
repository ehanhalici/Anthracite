#include "data_font/opentype/position_lookup/ot_position_graph_internal.hats"
implement ot_position_contexts_make(xs,n) = let
  val (pf,gc | rows)=array_ptr_alloc<OtPositionContext>(i2sz(n))
  val ()=array_initize_list_vt<OtPositionContext>(!rows,n,xs)
in OtPositionContexts(pf,gc | rows,n,n) end
implement ot_position_context_dispose(slot) = case+ slot of | ~PositionContextVacant() => ()
  | ~PositionContext(program,limits) => ot_context_dispose(program)
implement ot_position_context_list_dispose(xs) = dispose(xs) where {
  fun dispose{n:nat} .<n>. (xs: list_vt(OtPositionContext,n)): void = case+ xs of | ~list_vt_nil() => ()
    | ~list_vt_cons(x,tail) => let val ()=ot_position_context_dispose(x) in dispose(tail) end }
implement array_uninitize$clear<OtPositionContext>(i,x) = let val owned=x in ot_position_context_dispose(owned) end
implement ot_position_contexts_dispose(t) = let val+ ~OtPositionContexts(pf,gc | rows,n,i)=t
  val ()=array_uninitize<OtPositionContext>(!rows,i2sz(n))
in array_ptr_free(pf,gc | rows) end
