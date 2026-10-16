#include "data_font/opentype/position_lookup/ot_position_graph_internal.hats"
staload "data_font/opentype/coverage/ot_cov_cache_types.sats"
fun context_bytes(slot: !OtPositionContext): llint = case+ slot of | PositionContextVacant() => 0LL
  | PositionContext(p,limits) => let val+ OtContextProgram(info,domain,c)=p val+ OtCoverageCache(rows,n,i)=c
    in g0int2int_int_llint(n)*g0int2int_int_llint(g0uint2int_size_int(sizeof<OtCoverageInfo>))+1024LL end
fun contexts{n,i:nat | i <= n} .<n-i>. (index: int(i),t: !OtPositionContexts(n,n),total: llint): llint = let
  val+ OtPositionContexts(pf,gc | rows,n,filled)=t
in if index = n then total else let
  var loan: OtPositionContext=PositionContextVacant()
  val ()=array_exch_at<OtPositionContext>(!rows,i2sz(index),loan)
  val next=total+context_bytes(loan)
  val ()=array_exch_at<OtPositionContext>(!rows,i2sz(index),loan)
  val ()=ot_position_context_dispose(loan)
in contexts(index+1,t,next) end end
fun direct{n,i:nat | i <= n} .<n-i>. (index: int(i),t: !OtPositionTables(n,n),total: llint): llint = let
  val+ OtPositionTables(pf,gc | rows,n,filled)=t
in if index = n then total else let
  var loan: OtPositionPayload=PositionPayloadVacant()
  val ()=array_exch_at<OtPositionPayload>(!rows,i2sz(index),loan)
  val next=total+ot_position_payload_bytes(loan)+1024LL
  val ()=array_exch_at<OtPositionPayload>(!rows,i2sz(index),loan)
  val ()=ot_position_payload_dispose(loan)
in direct(index+1,t,next) end end
implement ot_position_graph_entry_bytes(entry) = case+ entry of | PositionGraphVacant() => 0LL
  | PositionGraphDirect(t) => let val+ OtPositionLookup(h,a,glyphs,tables)=t in direct(0,tables,1024LL) end
  | PositionGraphContext(h,t) => contexts(0,t,1024LL)
