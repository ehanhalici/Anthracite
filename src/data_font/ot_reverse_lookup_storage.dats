#include "data_font/ot_reverse_lookup_internal.hats"
implement ot_reverse_tables_make(xs,n) = let
  val (pf,gc | rows)=array_ptr_alloc<OtReverseSlot>(i2sz(n))
  val ()=array_initize_list_vt<OtReverseSlot>(!rows,n,xs)
in OtReverseTables(pf,gc | rows,n,n) end
implement ot_reverse_slot_dispose(slot) = case+ slot of | ~ReverseSlotVacant() => () | ~ReverseSlot(t) => gsub_reverse_dispose(t)
implement ot_reverse_slot_list_dispose(xs) = dispose(xs) where {
  fun dispose{n:nat} .<n>. (xs: list_vt(OtReverseSlot,n)): void = case+ xs of | ~list_vt_nil() => ()
    | ~list_vt_cons(x,tail) => let val ()=ot_reverse_slot_dispose(x) in dispose(tail) end }
implement array_uninitize$clear<OtReverseSlot>(i,x) = let val owned=x in ot_reverse_slot_dispose(owned) end
implement ot_reverse_tables_dispose(t) = let val+ ~OtReverseTables(pf,gc | rows,n,i)=t
  val ()=array_uninitize<OtReverseSlot>(!rows,i2sz(n))
in array_ptr_free(pf,gc | rows) end
implement ot_reverse_lookup_dispose(t) = let val+ ~OtReverseLookup(h,glyphs,limits,tables)=t
in ot_reverse_tables_dispose(tables) end
