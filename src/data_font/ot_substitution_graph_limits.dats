#include "data_font/ot_substitution_graph_internal.hats"
implement ot_substitution_graph_limits(a,b) = @{back=imax(a.back,b.back),input=imax(a.input,b.input),look=imax(a.look,b.look)}
fun context_limits(slot: !OtSubstitutionContext): OtContextLimits = case+ slot of
  | SubstitutionContextVacant() => @{back=0,input=1,look=0} | SubstitutionContext(program,limits) => limits
fun contexts{n,i:nat | i <= n} .<n-i>. (index: int(i),t: !OtSubstitutionContexts(n,n),limits: OtContextLimits): OtContextLimits = let
  val+ OtSubstitutionContexts(pf,gc | rows,n,filled)=t
in if index = n then limits else let
  var loan: OtSubstitutionContext=SubstitutionContextVacant()
  val ()=array_exch_at<OtSubstitutionContext>(!rows,i2sz(index),loan)
  val next=ot_substitution_graph_limits(limits,context_limits(loan))
  val ()=array_exch_at<OtSubstitutionContext>(!rows,i2sz(index),loan)
  val ()=ot_substitution_context_dispose(loan)
in contexts(index+1,t,next) end end
implement ot_substitution_graph_entry_limits(entry) = case+ entry of
  | SubstitutionGraphVacant() => @{back=0,input=1,look=0}
  | SubstitutionGraphSingle(h,t) => @{back=0,input=1,look=0}
  | SubstitutionGraphMultiple(h,t) => @{back=0,input=1,look=0}
  | SubstitutionGraphAlternate(h,t) => @{back=0,input=1,look=0}
  | SubstitutionGraphLigature(h,t) => @{back=0,input=imax(1,ot_ligation_lookup_maximum(t)),look=0}
  | SubstitutionGraphReverse(h,t) => let val+ OtReverseLookup(info,glyphs,limits,rows)=t in limits end
  | SubstitutionGraphContext(h,t) => contexts(0,t,@{back=0,input=1,look=0})
