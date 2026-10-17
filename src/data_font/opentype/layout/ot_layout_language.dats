#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_reader.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/layout/ot_layout_language.sats"
staload "data_font/opentype/layout/ot_layout_work.sats"
implement ot_language_info(b,s) = let val required=ot_u16(b,s,2) in
  @{span=s,count=ot_u16(b,s,4),
    required= @{found=ine(required,WORD16_MAX_VALUE),index=if ine(required,WORD16_MAX_VALUE) then required else 0}} end

fun indices_valid {n:nat} .<n>. (n: int(n),b: !Buf,s: OtSpan,i: int,features: int): bool =
  if n = 0 then true else if ige(ot_u16(b,s,iadd(6,imul(i,2))),features) then false
    else indices_valid(n-1,b,s,iadd(i,1),features)

implement ot_language_work(b,s,features,remaining) =
  if ilt(s.length,6) then Some_vt(ot_error(OtBounds(),s))
  else if ine(ot_u16(b,s,0),0) then Some_vt(ot_error(OtFormat(),s)) else let
    val l=ot_language_info(b,s)
  in if not(ot_rows_fit(s,6,l.count,2)) then Some_vt(ot_error(OtBounds(),s))
    else if not(ot_layout_charge(remaining,iadd(l.count,1))) then Some_vt(ot_error(OtCapacity(),s))
    else if l.required.found andalso ige(l.required.index,features) then Some_vt(ot_error(OtReference(),s))
    else if not(indices_valid(airlock_nat(l.count),b,s,0,features)) then Some_vt(ot_error(OtReference(),s))
    else None_vt() end

implement ot_language_validate(b,s,features) = let var remaining: int=MAX_REC_FUEL in
  ot_language_work(b,s,features,remaining) end
