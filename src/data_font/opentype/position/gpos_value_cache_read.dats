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
staload "data_font/opentype/position/gpos_value_cache_types.sats"
staload "data_font/opentype/position/gpos_value_cache.sats"
fun fill {n,i:nat | i <= n} .<n-i>. (b: !Buf,s: OtSpan,at: int,
  format: OtValueFormat,floor: int,cache: OtValueCache(n,i)): OtValueCacheRead = let
  val count=ot_value_cache_count(cache) and index=ot_value_cache_filled(cache)
in if index = count then ValueCacheAccepted(cache) else
  case+ ot_value_parse(b,s,iadd(at,imul(index,format.size)),format,floor) of
  | ~ValueRejected(e) => let val ()=ot_value_cache_dispose(cache) in ValueCacheRejected(e) end
  | ~ValueAccepted(v) => fill(b,s,at,format,floor,ot_value_cache_append(cache,v)) end
fun rows_fit(s: OtSpan,at: int,count: int,size: int,floor: int): bool =
  ige(count,0) andalso ige(at,0) andalso ile(at,s.length) andalso ige(size,0)
  andalso ige(floor,at) andalso ile(floor,s.length)
  andalso (if ieq(size,0) then true else ile(count,idiv(isub(floor,at),size)))
implement ot_value_cache_read(b,s,at,count,format,floor) =
  if not(ot_span_valid(b,s)) orelse not(rows_fit(s,at,count,format.size,floor))
    then ValueCacheRejected(ot_error(OtBounds(),s))
  else if not(ot_value_cache_capacity(count)) then ValueCacheRejected(ot_error(OtCapacity(),s))
  else fill(b,s,at,format,floor,ot_value_cache_make(airlock_nat(count)))
