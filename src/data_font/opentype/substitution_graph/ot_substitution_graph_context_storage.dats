#include "data_font/opentype/substitution_graph/ot_substitution_graph_internal.hats"
implement ot_substitution_contexts_make(xs,n) = let
  val (pf,gc | rows)=array_ptr_alloc<OtSubstitutionContext>(i2sz(n))
  val ()=array_initize_list_vt<OtSubstitutionContext>(!rows,n,xs)
in OtSubstitutionContexts(pf,gc | rows,n,n) end
implement ot_substitution_context_dispose(slot) = case+ slot of | ~SubstitutionContextVacant() => ()
  | ~SubstitutionContext(program,limits) => ot_context_dispose(program)
implement ot_substitution_context_list_dispose(xs) = dispose(xs) where {
  fun dispose{n:nat} .<n>. (xs: list_vt(OtSubstitutionContext,n)): void = case+ xs of | ~list_vt_nil() => ()
    | ~list_vt_cons(x,tail) => let val ()=ot_substitution_context_dispose(x) in dispose(tail) end }
implement array_uninitize$clear<OtSubstitutionContext>(i,x) = let val owned=x in ot_substitution_context_dispose(owned) end
implement ot_substitution_contexts_dispose(t) = let val+ ~OtSubstitutionContexts(pf,gc | rows,n,i)=t
  val ()=array_uninitize<OtSubstitutionContext>(!rows,i2sz(n))
in array_ptr_free(pf,gc | rows) end
