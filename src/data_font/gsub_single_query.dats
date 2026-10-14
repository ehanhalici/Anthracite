#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/opentype_coverage.sats"
staload "data_font/gsub_single_types.sats"
staload "data_font/gsub_single.sats"
staload "data_font/gsub_single_work.sats"
fun output(b: !Buf,info: GsubSingleInfo,glyph: int,index: int): int = case+ info.encoding of
  | GsubDelta() => gsub_delta_add(glyph,info.delta)
  | GsubArray() => ot_u16(b,info.span,iadd(6,imul(index,2)))
implement gsub_single_query_info(b,info,glyph) = let
  val found=ot_coverage_index(b,info.coverage,glyph)
in if found.found then @{matched=true,glyph=output(b,info,glyph,found.index)}
  else @{matched=false,glyph=glyph} end
implement gsub_single_query(b,table,glyph) = let val+ GsubSingle(info)=table in
  gsub_single_query_info(b,info,glyph) end
implement gsub_single_dispose(table) = let val+ ~GsubSingle(info)=table in () end
