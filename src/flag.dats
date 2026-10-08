#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

staload "flag.sats"

implement toggle_of(b) = if b then On else Off

implement is_on(t) = case+ t of
  | On() => true
  | Off() => false

implement is_off(t) = not(is_on(t))

implement toggle_int(t) = if is_on(t) then 1 else 0
