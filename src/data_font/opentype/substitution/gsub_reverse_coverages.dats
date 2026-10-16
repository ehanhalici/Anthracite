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
staload "data_font/opentype/tables/opentype_glyphs.sats"
staload "data_font/opentype/coverage/ot_cov_cache.sats"
staload "data_font/opentype/substitution/gsub_reverse_work.sats"
fun validated{back,look:nat}{n:nat}(font: !Buf,info: GsubReverseInfo(back,look),
  cache: OtCoverageCache(n,n)): GsubReverseRead =
  if ot_cov_cache_count(cache) != info.back+info.look+1 then let val ()=ot_cov_cache_dispose(cache) in
    ReverseRejected(ot_error(OtReference(),info.span)) end
  else let val main=ot_cov_cache_get(cache,0) in
    if ine(main.total,info.count) then let val ()=ot_cov_cache_dispose(cache) in
      ReverseRejected(ot_error(OtCoverageIndex(),info.span)) end
    else ReverseAccepted(GsubReverse(info,cache)) end
fun consume{back,look:nat}(font: !Buf,info: GsubReverseInfo(back,look),
  fields: Buf,result: OtCoverageCacheRead): GsubReverseRead = let val ()=buf_free(fields) in
  case+ result of
  | ~CoverageCacheRejected(e) => ReverseRejected(e)
  | ~CoverageCacheAccepted(cache) => validated(font,info,cache) end
implement gsub_reverse_coverages(font,info) = let
  val fields=gsub_reverse_fields(info)
  val floor=iadd(info.output,imul(info.count,2))
in consume(font,info,fields,ot_cov_cache_read(font,info.span,fields,floor,info.glyphs)) end
