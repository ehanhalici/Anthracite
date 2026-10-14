#include "data_font/ot_substitution_graph_internal.hats"
staload "data_font/ot_cov_cache_types.sats"
fun context_bytes(slot: !OtSubstitutionContext): llint = case+ slot of | SubstitutionContextVacant() => 0LL
  | SubstitutionContext(p,limits) => let val+ OtContextProgram(info,domain,c)=p val+ OtCoverageCache(rows,n,i)=c
    in g0int2int_int_llint(n)*g0int2int_int_llint(g0uint2int_size_int(sizeof<OtCoverageInfo>))+1024LL end
fun contexts{n,i:nat | i <= n} .<n-i>. (index: int(i),t: !OtSubstitutionContexts(n,n),total: llint): llint = let
  val+ OtSubstitutionContexts(pf,gc | rows,n,filled)=t
in if index = n then total else let
  var loan: OtSubstitutionContext=SubstitutionContextVacant()
  val ()=array_exch_at<OtSubstitutionContext>(!rows,i2sz(index),loan)
  val next=total+context_bytes(loan)
  val ()=array_exch_at<OtSubstitutionContext>(!rows,i2sz(index),loan)
  val ()=ot_substitution_context_dispose(loan)
in contexts(index+1,t,next) end end
fun reverse{n,i:nat | i <= n} .<n-i>. (index: int(i),t: !OtReverseTables(n,n),total: llint): llint = let
  val+ OtReverseTables(pf,gc | rows,n,filled)=t
in if index = n then total else let
  var loan: OtReverseSlot=ReverseSlotVacant()
  val ()=ot_reverse_tables_exchange(t,index,loan)
  val next=total+ot_reverse_slot_bytes(loan)
  val ()=ot_reverse_tables_exchange(t,index,loan)
  val ()=ot_reverse_slot_dispose(loan)
in reverse(index+1,t,next) end end
fun descriptors(count: int): llint = 1024LL+g0int2int_int_llint(count)*1024LL
implement ot_substitution_graph_entry_bytes(entry) = case+ entry of
  | SubstitutionGraphVacant() => 0LL | SubstitutionGraphSingle(h,t) => descriptors(h.count)
  | SubstitutionGraphMultiple(h,t) => descriptors(h.count) | SubstitutionGraphAlternate(h,t) => descriptors(h.count)
  | SubstitutionGraphLigature(h,t) => descriptors(h.count)
  | SubstitutionGraphReverse(h,t) => let val+ OtReverseLookup(info,glyphs,limits,rows)=t in reverse(0,rows,1024LL) end
  | SubstitutionGraphContext(h,t) => contexts(0,t,1024LL)
