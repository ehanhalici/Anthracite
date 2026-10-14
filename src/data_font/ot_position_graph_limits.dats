#include "data_font/ot_position_graph_internal.hats"
implement ot_position_graph_limits(a,b) = @{back=imax(a.back,b.back),input=imax(a.input,b.input),look=imax(a.look,b.look)}
fun context_limits(slot: !OtPositionContext): OtContextLimits = case+ slot of
  | PositionContextVacant() => @{back=0,input=1,look=0} | PositionContext(program,limits) => limits
fun contexts{n,i:nat | i <= n} .<n-i>. (index: int(i),t: !OtPositionContexts(n,n),limits: OtContextLimits): OtContextLimits = let
  val+ OtPositionContexts(pf,gc | rows,n,filled)=t
in if index = n then limits else let
  var loan: OtPositionContext=PositionContextVacant()
  val ()=array_exch_at<OtPositionContext>(!rows,i2sz(index),loan)
  val next=ot_position_graph_limits(limits,context_limits(loan))
  val ()=array_exch_at<OtPositionContext>(!rows,i2sz(index),loan)
  val ()=ot_position_context_dispose(loan)
in contexts(index+1,t,next) end end
implement ot_position_graph_entry_limits(entry) = case+ entry of
  | PositionGraphVacant() => @{back=0,input=1,look=0} | PositionGraphDirect(t) => @{back=0,input=1,look=0}
  | PositionGraphContext(h,t) => contexts(0,t,@{back=0,input=1,look=0})
