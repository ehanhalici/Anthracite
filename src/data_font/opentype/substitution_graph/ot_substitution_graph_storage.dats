#include "data_font/opentype/substitution_graph/ot_substitution_graph_internal.hats"
implement ot_substitution_graph_entries_make(xs,n) = let
  val (pf,gc | rows)=array_ptr_alloc<OtSubstitutionGraphEntry>(i2sz(n))
  val ()=array_initize_list_vt<OtSubstitutionGraphEntry>(!rows,n,xs)
in OtSubstitutionGraphEntries(pf,gc | rows,n,n) end
implement ot_substitution_graph_entry_dispose(entry) = case+ entry of
  | ~SubstitutionGraphVacant() => () | ~SubstitutionGraphSingle(h,t) => ot_single_lookup_dispose(t)
  | ~SubstitutionGraphMultiple(h,t) => ot_sequence_lookup_dispose(t)
  | ~SubstitutionGraphAlternate(h,t) => ot_sequence_lookup_dispose(t)
  | ~SubstitutionGraphLigature(h,t) => ot_ligation_lookup_dispose(t)
  | ~SubstitutionGraphReverse(h,t) => ot_reverse_lookup_dispose(t)
  | ~SubstitutionGraphContext(h,t) => ot_substitution_contexts_dispose(t)
implement ot_substitution_graph_list_dispose(xs) = dispose(xs) where {
  fun dispose{n:nat} .<n>. (xs: list_vt(OtSubstitutionGraphEntry,n)): void = case+ xs of | ~list_vt_nil() => ()
    | ~list_vt_cons(x,tail) => let val ()=ot_substitution_graph_entry_dispose(x) in dispose(tail) end }
implement array_uninitize$clear<OtSubstitutionGraphEntry>(i,x) = let val owned=x in ot_substitution_graph_entry_dispose(owned) end
implement ot_substitution_graph_entries_dispose(t) = let val+ ~OtSubstitutionGraphEntries(pf,gc | rows,n,i)=t
  val ()=array_uninitize<OtSubstitutionGraphEntry>(!rows,i2sz(n))
in array_ptr_free(pf,gc | rows) end
implement ot_substitution_graph_dispose(g) = let val+ ~OtSubstitutionGraph(font,glyphs,limits,entries)=g
in ot_substitution_graph_entries_dispose(entries) end
