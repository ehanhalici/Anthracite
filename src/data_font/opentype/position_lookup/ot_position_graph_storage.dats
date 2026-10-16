#include "data_font/opentype/position_lookup/ot_position_graph_internal.hats"
implement ot_position_graph_entries_make(xs,n) = let
  val (pf,gc | rows)=array_ptr_alloc<OtPositionGraphEntry>(i2sz(n))
  val ()=array_initize_list_vt<OtPositionGraphEntry>(!rows,n,xs)
in OtPositionGraphEntries(pf,gc | rows,n,n) end
implement ot_position_graph_entry_dispose(entry) = case+ entry of
  | ~PositionGraphVacant() => () | ~PositionGraphDirect(t) => ot_position_lookup_dispose(t)
  | ~PositionGraphContext(h,t) => ot_position_contexts_dispose(t)
implement ot_position_graph_list_dispose(xs) = dispose(xs) where {
  fun dispose{n:nat} .<n>. (xs: list_vt(OtPositionGraphEntry,n)): void = case+ xs of | ~list_vt_nil() => ()
    | ~list_vt_cons(x,tail) => let val ()=ot_position_graph_entry_dispose(x) in dispose(tail) end }
implement array_uninitize$clear<OtPositionGraphEntry>(i,x) = let val owned=x in ot_position_graph_entry_dispose(owned) end
implement ot_position_graph_entries_dispose(t) = let val+ ~OtPositionGraphEntries(pf,gc | rows,n,i)=t
  val ()=array_uninitize<OtPositionGraphEntry>(!rows,i2sz(n))
in array_ptr_free(pf,gc | rows) end
implement ot_position_graph_dispose(g) = let val+ ~OtPositionGraph(font,glyphs,limits,entries)=g
in ot_position_graph_entries_dispose(entries) end
