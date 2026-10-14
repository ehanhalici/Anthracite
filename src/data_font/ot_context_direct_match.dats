#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/ot_context_types.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/opentype_coverage.sats"
staload "data_font/ot_cov_cache.sats"
staload "data_font/ot_cov_cache_types.sats"
staload "data_font/ot_context_match_work.sats"
fun member{n:nat}(b: !Buf,cache: !OtCoverageCache(n,n),slot: int,glyph: int): bool = let
  val result=ot_coverage_index(b,ot_cov_cache_get(cache,slot),glyph)
in result.found end
fun forward {fuel:nat}{n:nat} .<fuel>. (fuel: int(fuel),b: !Buf,cache: !OtCoverageCache(n,n),
  input: !Buf,start: int,slot: int,i: int): bool =
  if fuel = 0 then true else
    if not(member(b,cache,iadd(slot,i),buf_get32(input,iadd(start,i)))) then false
    else forward(fuel-1,b,cache,input,start,slot,iadd(i,1))
fun backtrack {fuel:nat}{n:nat} .<fuel>. (fuel: int(fuel),b: !Buf,cache: !OtCoverageCache(n,n),
  input: !Buf,start: int,i: int): bool =
  if fuel = 0 then true else
    if not(member(b,cache,i,buf_get32(input,isub(isub(start,1),i)))) then false
    else backtrack(fuel-1,b,cache,input,start,iadd(i,1))
implement ot_context_direct_match(b,info,domain,cache,input,count,start,inputLimit) = let
  val p=info.pattern
  val matched=ot_context_pattern_fits_input(p,count,start,inputLimit) andalso
    backtrack(airlock_nat(p.backCount),b,cache,input,start,0) andalso
    forward(airlock_nat(p.inputCount),b,cache,input,start,p.backCount,0) andalso
    forward(airlock_nat(p.lookCount),b,cache,input,iadd(start,p.inputCount),iadd(p.backCount,p.inputCount),0)
in if matched then ot_context_result(domain,p,0) else ot_context_missing(domain) end
