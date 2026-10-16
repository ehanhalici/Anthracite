#include "data_font/opentype/reverse_lookup/ot_reverse_lookup_internal.hats"
implement ot_reverse_tables_exchange(t,index,slot) = let
  val+ OtReverseTables(pf,gc | rows,n,filled)=t
in array_exch_at<OtReverseSlot>(!rows,i2sz(index),slot) end
