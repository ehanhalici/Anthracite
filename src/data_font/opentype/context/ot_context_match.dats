#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_reader.sats"
staload "data_font/opentype/context/ot_context_types.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/tables/opentype_coverage.sats"
staload "data_font/opentype/tables/opentype_classdef.sats"
staload "data_font/opentype/coverage/ot_cov_cache.sats"
staload "data_font/opentype/coverage/ot_cov_cache_types.sats"
staload "data_font/opentype/context/ot_context.sats"
staload "data_font/opentype/context/ot_context_match_work.sats"
fun sets{kind:int}{n:nat}(b: !Buf,info: OtContextInfo,domain: OtLayoutDomain(kind),
  cache: !OtCoverageCache(n,n),input: !Buf,count: int,start: int,inputLimit: int): OtContextMatch(kind) = let
  val glyph=buf_get32(input,start)
  val found=ot_coverage_index(b,ot_cov_cache_get(cache,0),glyph)
in if not(found.found) then ot_context_missing(domain) else case+ info.encoding of
  | ContextGlyphs() => ot_context_sets_match(b,info,domain,input,count,start,inputLimit,found.index,LiteralGlyph())
  | ContextClasses() => ot_context_sets_match(b,info,domain,input,count,start,inputLimit,
      ot_classdef_value(b,info.inputClass,glyph),LiteralClass())
  | ContextCoverages() => ot_context_direct_match(b,info,domain,cache,input,count,start,inputLimit) end
implement ot_context_match_bounded(b,program,input,count,start,inputLimit) = let val+ OtContextProgram(info,domain,cache)=program in
  if ilt(count,0) orelse igt(count,idiv(buf_cap(input),4)) orelse ilt(start,0) orelse ige(start,count)
  then ot_context_missing(domain)
  else if ilt(inputLimit,0) orelse igt(inputLimit,isub(count,start)) then ot_context_missing(domain) else case+ info.encoding of
  | ContextGlyphs() => sets(b,info,domain,cache,input,count,start,inputLimit)
  | ContextClasses() => sets(b,info,domain,cache,input,count,start,inputLimit)
  | ContextCoverages() => ot_context_direct_match(b,info,domain,cache,input,count,start,inputLimit) end
implement ot_context_match(b,program,input,count,start) =
  ot_context_match_bounded(b,program,input,count,start,isub(count,start))
