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
staload "data_font/gpos_value_cache_types.sats"
staload "data_font/gpos_value_cache.sats"
staload "data_font/gpos_pair_types.sats"
staload "data_font/gpos_pair_work.sats"
fun fill {n,i:nat | i <= n} .<n-i>. (b: !Buf,info: GposPairInfo,cache: OtValueCache(n,i)): GposPairRead = let
  val index=ot_value_cache_filled(cache) and count=ot_value_cache_count(cache)
in if index = count then PairAccepted(PairClasses(info,cache)) else let
    val first=ieq(imod(index,2),0)
    val f=if first then info.formats.first else info.formats.second
    val at=iadd(iadd(16,imul(idiv(index,2),info.formats.stride)),if first then 0 else info.formats.first.size)
    val floor=iadd(16,imul(idiv(count,2),info.formats.stride))
  in case+ ot_value_parse(b,info.span,at,f,floor) of
    | ~ValueRejected(e) => let val ()=ot_value_cache_dispose(cache) in PairRejected(e) end
    | ~ValueAccepted(v) => fill(b,info,ot_value_cache_append(cache,v)) end end
implement gpos_pair_matrix(b,info) =
  if ieq(info.formats.stride,0) then PairAccepted(PairNoOpClasses(info)) else let
    (* Nonempty records were bounded by font span before this multiplication. *)
    val count=imul(imul(info.firstCount,info.secondCount),2)
  in if not(ot_value_cache_capacity(count)) then PairRejected(ot_error(OtCapacity(),info.span))
    else fill(b,info,ot_value_cache_make(airlock_nat(count))) end
