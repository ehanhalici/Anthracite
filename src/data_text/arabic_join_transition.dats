#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "data_text/unicode_property.sats"
staload "data_text/arabic_join_types.sats"
staload "data_text/arabic_join_work.sats"
staload "data_text/arabic_join.sats"
implement arabic_join_step(state,joining) = case+ joining of
  | JoinNone() => @{state=JoinStart(),previous=FormNone(),current=FormNone(),advance=ReplacePrevious()}
  | JoinLeft() => @{state=JoinOpenIsolated(),previous=FormNone(),current=FormIsolated(),advance=ReplacePrevious()}
  | JoinRight() => arabic_join_right(state)
  | JoinDual() => arabic_join_dual(state) | JoinCausing() => arabic_join_dual(state)
  | JoinTransparent() => @{state=state,previous=FormNone(),current=FormNone(),advance=RetainPrevious()}
implement arabic_join_start(boundary) = case+ boundary of
  | BoundaryNone() => JoinStart() | BoundaryRight() => JoinStart()
  | BoundaryLeft() => JoinOpenIsolated() | BoundaryDual() => JoinOpenIsolated()
  | BoundaryCausing() => JoinOpenIsolated()
implement arabic_join_end(state,boundary) = case+ boundary of
  | BoundaryNone() => FormNone() | BoundaryLeft() => FormNone()
  | BoundaryRight() => arabic_join_promote(state)
  | BoundaryDual() => arabic_join_promote(state) | BoundaryCausing() => arabic_join_promote(state)
