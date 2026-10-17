#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/unicode/unicode_property.sats"
staload "data_text/arabic/joining/arabic_join_types.sats"
staload "data_text/arabic/joining/arabic_join.sats"
extern fun joining_invalid(): ArabicJoining = "mac#anth_die_box"
implement arabic_joining_of(code) = case+ code of
  | 0 => JoinNone()
  | 1 => JoinRight()
  | 2 => JoinLeft()
  | 3 => JoinDual()
  | 4 => JoinCausing()
  | 5 => JoinTransparent()
  | _ => joining_invalid()
implement arabic_joining(map,scalar) = arabic_joining_of(property_value(map,scalar))
implement arabic_boundary_of(joining) = case+ joining of
  | JoinNone() => Some_vt(BoundaryNone())
  | JoinRight() => Some_vt(BoundaryRight())
  | JoinLeft() => Some_vt(BoundaryLeft())
  | JoinDual() => Some_vt(BoundaryDual())
  | JoinCausing() => Some_vt(BoundaryCausing())
  | JoinTransparent() => None_vt()
