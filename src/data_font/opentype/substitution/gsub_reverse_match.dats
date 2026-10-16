#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_reader.sats"
staload "data_font/opentype/coverage/ot_cov_cache_types.sats"
staload "data_font/opentype/substitution/gsub_reverse_types.sats"
staload "data_font/opentype/tables/opentype_coverage.sats"
staload "data_font/opentype/coverage/ot_cov_cache.sats"
staload "data_font/opentype/substitution/gsub_reverse.sats"
fun member{n:nat}(b: !Buf,cache: !OtCoverageCache(n,n),slot: int,glyph: int): bool = let
  val c=ot_cov_cache_get(cache,slot)
  val result=ot_coverage_index(b,c,glyph)
in result.found end
fun backtrack {fuel:nat}{n:nat} .<fuel>. (fuel: int(fuel),b: !Buf,cache: !OtCoverageCache(n,n),
  input: !Buf,start: int,i: int): bool =
  if fuel = 0 then true else
    if not(member(b,cache,iadd(i,1),buf_get32(input,isub(isub(start,1),i)))) then false
    else backtrack(fuel-1,b,cache,input,start,iadd(i,1))
fun lookahead {fuel:nat}{n:nat} .<fuel>. (fuel: int(fuel),b: !Buf,cache: !OtCoverageCache(n,n),
  input: !Buf,start: int,slot: int,i: int): bool =
  if fuel = 0 then true else
    if not(member(b,cache,iadd(slot,i),buf_get32(input,iadd(iadd(start,1),i)))) then false
    else lookahead(fuel-1,b,cache,input,start,slot,iadd(i,1))
implement gsub_reverse_match(b,table,input,count,start) =
  if ilt(count,0) orelse igt(count,idiv(buf_cap(input),4)) orelse ilt(start,0) orelse ige(start,count)
  then @{matched=false,glyph=0} else let
    val+ GsubReverse(info,cache)=table
    val glyph=buf_get32(input,start)
    val first=ot_coverage_index(b,ot_cov_cache_get(cache,0),glyph)
    val fits=ige(start,info.back) andalso ilt(info.look,isub(count,start))
    val matched=first.found andalso fits andalso backtrack(info.back,b,cache,input,start,0)
      andalso lookahead(info.look,b,cache,input,start,iadd(info.back,1),0)
  in if matched then @{matched=true,glyph=ot_u16(b,info.span,iadd(info.output,imul(first.index,2)))}
    else @{matched=false,glyph=glyph} end
implement gsub_reverse_dispose(table) = let val+ ~GsubReverse(info,cache)=table in ot_cov_cache_dispose(cache) end
