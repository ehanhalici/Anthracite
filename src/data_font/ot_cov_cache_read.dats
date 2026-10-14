#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/opentype_coverage.sats"
staload "data_font/ot_cov_cache_types.sats"
staload "data_font/ot_cov_cache.sats"
staload "data_font/ot_cov_cache_work.sats"
fun child(b: !Buf,s: OtSpan,fields: !Buf,index: int,floor: int): OtChild = let
  val field=buf_get32(fields,index)
in if ilt(field,0) orelse igt(field,isub(s.length,2))
  then @{kind=ChildInvalid(),span= @{offset=0,length=0}}
  else ot_optional_child(s,ot_u16(b,s,field),floor) end
fun parse_target(b: !Buf,s: OtSpan,target: OtChild,glyphs: int,remaining: &int >> _): OtCoverageRead =
  case+ target.kind of
  | ChildMissing() => CoverageRejected(ot_error(OtBounds(),s))
  | ChildInvalid() => CoverageRejected(ot_error(OtBounds(),s))
  | ChildPresent() => ot_cov_cache_parse_child(b,target,glyphs,remaining)
fun fill {n,i:nat | i <= n} .<n-i>. (b: !Buf,s: OtSpan,fields: !Buf,floor: int,
  glyphs: int,cache: OtCoverageCache(n,i),remaining: &int >> _): OtCoverageCacheRead = let
  val count=ot_cov_cache_count(cache)
  val index=ot_cov_cache_filled(cache)
in if index = count then CoverageCacheAccepted(cache) else let
    val target=child(b,s,fields,index,floor)
  in case+ parse_target(b,s,target,glyphs,remaining) of
    | ~CoverageRejected(e) => let val ()=ot_cov_cache_dispose(cache) in CoverageCacheRejected(e) end
    | ~CoverageAccepted(c) => fill(b,s,fields,floor,glyphs,ot_cov_cache_append(cache,c),remaining) end end
implement ot_cov_cache_read(b,s,fields,floor,glyphs) =
  if not(ot_span_valid(b,s)) orelse ine(imod(buf_len(fields),4),0) orelse ilt(floor,0)
    orelse igt(floor,s.length) then CoverageCacheRejected(ot_error(OtBounds(),s))
  else if not(ot_glyph_domain_valid(glyphs)) then CoverageCacheRejected(ot_error(OtGlyphDomain(),s)) else let
    var remaining: int=MAX_REC_FUEL
    val count=airlock_nat(idiv(buf_len(fields),4))
  in fill(b,s,fields,floor,glyphs,ot_cov_cache_make(count),remaining) end
