#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "data_text/arabic/joining/arabic_join_types.sats"
staload "data_text/arabic/joining/arabic_join_work.sats"
implement arabic_join_right(state) = case+ state of
  | JoinStart() => @{state=JoinBlocked(),previous=FormNone(),current=FormIsolated(),advance=ReplacePrevious()}
  | JoinBlocked() => @{state=JoinBlocked(),previous=FormNone(),current=FormIsolated(),advance=ReplacePrevious()}
  | JoinOpenIsolated() => @{state=JoinBlocked(),previous=FormInitial(),current=FormFinal(),advance=ReplacePrevious()}
  | JoinOpenFinal() => @{state=JoinBlocked(),previous=FormMedial(),current=FormFinal(),advance=ReplacePrevious()}
implement arabic_join_dual(state) = case+ state of
  | JoinStart() => @{state=JoinOpenIsolated(),previous=FormNone(),current=FormIsolated(),advance=ReplacePrevious()}
  | JoinBlocked() => @{state=JoinOpenIsolated(),previous=FormNone(),current=FormIsolated(),advance=ReplacePrevious()}
  | JoinOpenIsolated() => @{state=JoinOpenFinal(),previous=FormInitial(),current=FormFinal(),advance=ReplacePrevious()}
  | JoinOpenFinal() => @{state=JoinOpenFinal(),previous=FormMedial(),current=FormFinal(),advance=ReplacePrevious()}
implement arabic_join_promote(state) = case+ state of
  | JoinStart() => FormNone() | JoinBlocked() => FormNone()
  | JoinOpenIsolated() => FormInitial() | JoinOpenFinal() => FormMedial()
