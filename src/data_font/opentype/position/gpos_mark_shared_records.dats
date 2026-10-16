#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_reader.sats"
staload "data_font/opentype/position/gpos_value_types.sats"
staload "data_font/opentype/position/gpos_values.sats"
staload "data_font/opentype/position/gpos_anchor_cache_types.sats"
staload "data_font/opentype/position/gpos_anchor_cache.sats"
staload "data_font/opentype/position/gpos_mark_shared_types.sats"
staload "data_font/opentype/position/gpos_mark_shared.sats"
staload "data_font/opentype/position/gpos_mark_shared_work.sats"
fun rows {n:nat} .<n>. (n: int(n),b: !Buf,s: OtSpan,classes: int,index: int): bool =
  if n = 0 then true else if ige(ot_u16(b,s,iadd(2,imul(index,4))),classes) then false
  else rows(n-1,b,s,classes,iadd(index,1))
implement gpos_mark_records(b,s,count,classes) = rows(airlock_nat(count),b,s,classes,0)
