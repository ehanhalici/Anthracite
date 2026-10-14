#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/gpos_value_types.sats"
staload "data_font/gpos_values.sats"
staload "data_font/gpos_anchor_cache_types.sats"
staload "data_font/gpos_anchor_cache.sats"
fun read(b: !Buf,s: OtSpan,field: int,floor: int,p: OtAnchorPresence): OtAnchorSlotRead =
  if ilt(field,0) orelse igt(field,isub(s.length,2)) then AnchorSlotRejected(ot_error(OtBounds(),s))
  else ot_anchor_slot_parse(b,s,ot_u16(b,s,field),floor,p)
fun fill {n,i:nat | i <= n} .<n-i>. (b: !Buf,s: OtSpan,fields: !Buf,floor: int,
  p: OtAnchorPresence,cache: OtAnchorCache(n,i)): OtAnchorCacheRead = let
  val count=ot_anchor_cache_count(cache) and index=ot_anchor_cache_filled(cache)
in if index = count then AnchorCacheAccepted(cache) else
  case+ read(b,s,buf_get32(fields,index),floor,p) of
  | ~AnchorSlotRejected(e) => let val ()=ot_anchor_cache_dispose(cache) in AnchorCacheRejected(e) end
  | ~AnchorSlotAccepted(v) => fill(b,s,fields,floor,p,ot_anchor_cache_append(cache,v)) end
implement ot_anchor_cache_read(b,s,fields,floor,p) =
  if not(ot_span_valid(b,s)) orelse ine(imod(buf_len(fields),4),0) orelse ilt(floor,0) orelse igt(floor,s.length)
    then AnchorCacheRejected(ot_error(OtBounds(),s)) else let
    val count=idiv(buf_len(fields),4)
  in if not(ot_anchor_cache_capacity(count)) then AnchorCacheRejected(ot_error(OtCapacity(),s))
    else fill(b,s,fields,floor,p,ot_anchor_cache_make(airlock_nat(count))) end
