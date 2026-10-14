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
staload "data_font/ot_cov_cache_types.sats"
staload "data_font/ot_cov_cache.sats"
staload "data_font/ot_context.sats"
staload "data_font/ot_context_work.sats"
staload "data_font/ot_context_header.sats"
fun consume{kind:int}(info: OtContextInfo,domain: OtLayoutDomain(kind),
  fields: Buf,result: OtCoverageCacheRead): OtContextRead(kind) = let val ()=buf_free(fields) in
  case+ result of
  | ~CoverageCacheRejected(e) => ContextRejected(e)
  | ~CoverageCacheAccepted(cache) => ContextAccepted(OtContextProgram(info,domain,cache)) end
fun coverages{kind:int}(b: !Buf,info: OtContextInfo,domain: OtLayoutDomain(kind)): OtContextRead(kind) = let
  val fields=ot_context_fields(info)
in consume(info,domain,fields,ot_cov_cache_read(b,info.span,fields,info.floor,info.glyphs)) end
fun validated{kind:int}(b: !Buf,info: OtContextInfo,domain: OtLayoutDomain(kind)): OtContextRead(kind) =
  case+ ot_context_validate(b,info,domain) of
  | ~Some_vt(e) => ContextRejected(e) | ~None_vt() => coverages(b,info,domain)
implement ot_context_parse(b,s,glyphs,lookups,domain,mode) =
  case+ ot_context_header_parse(b,s,glyphs,lookups,mode) of
  | ~ContextHeaderRejected(e) => ContextRejected(e)
  | ~ContextHeaderAccepted(info) => validated(b,info,domain)
