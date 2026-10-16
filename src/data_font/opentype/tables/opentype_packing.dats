#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_packing.sats"
implement ot_packing_of(code) = case+ code of
  | 1 => Some_vt(OtBits2()) | 2 => Some_vt(OtBits4()) | 3 => Some_vt(OtBits8())
  | _ => None_vt()
implement ot_packing_bits(p) = case+ p of | OtBits2() => 2 | OtBits4() => 4 | OtBits8() => 8
implement ot_packing_base(p) = case+ p of | OtBits2() => 4 | OtBits4() => 16 | OtBits8() => 256
fun power {n:nat} .<n>. (n: int(n),value: int): int =
  if n = 0 then value else power(n-1,imul(value,2))
implement ot_power2(n) = power(airlock_below(n,17),1)
