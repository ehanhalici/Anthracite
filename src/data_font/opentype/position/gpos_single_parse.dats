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
staload "data_font/opentype/tables/opentype_coverage.sats"
staload "data_font/opentype/position/gpos_value_cache.sats"
staload "data_font/opentype/position/gpos_value_cache_types.sats"
staload "data_font/opentype/position/gpos_single_types.sats"
staload "data_font/opentype/position/gpos_single.sats"
fun values(b: !Buf,s: OtSpan,c: OtCoverageInfo,f: OtValueFormat,at: int,count: int,
  floor: int,encoding: GposSingleEncoding,glyphs: int): GposSingleRead = let
  val cached=case+ encoding of | PositionUniform() => 1 | PositionIndexed() => count
in case+ ot_value_cache_read(b,s,at,cached,f,floor) of
  | ~ValueCacheRejected(e) => PositionSingleRejected(e)
  | ~ValueCacheAccepted(cache) => PositionSingleAccepted(GposSingle(@{coverage=c,encoding=encoding,glyphs=glyphs},cache)) end
fun coverage(b: !Buf,s: OtSpan,glyphs: int,f: OtValueFormat,at: int,count: int,
  encoding: GposSingleEncoding): GposSingleRead = let
  val floor=iadd(at,imul(count,f.size))
  val target=ot_optional_child(s,ot_u16(b,s,2),floor)
in if igt(floor,s.length) then PositionSingleRejected(ot_error(OtBounds(),s)) else case+ target.kind of
  | ChildMissing() => PositionSingleRejected(ot_error(OtBounds(),s))
  | ChildInvalid() => PositionSingleRejected(ot_error(OtBounds(),s))
  | ChildPresent() => case+ ot_coverage_parse(b,target.span,glyphs) of
    | ~CoverageRejected(e) => PositionSingleRejected(e) | ~CoverageAccepted(c) => let
      val exact: bool=case+ encoding of | PositionUniform() => true | PositionIndexed() => ieq(c.total,count)
      val query=if ieq(f.size,0) then PositionUniform() else encoding
    in if exact then values(b,s,c,f,at,count,floor,query,glyphs)
      else PositionSingleRejected(ot_error(OtCoverageIndex(),s)) end end
fun format_of(b: !Buf,s: OtSpan,glyphs: int,f: OtValueFormat): GposSingleRead =
  case+ ot_u16(b,s,0) of
  | 1 => coverage(b,s,glyphs,f,6,1,PositionUniform())
  | 2 => if ilt(s.length,8) then PositionSingleRejected(ot_error(OtBounds(),s))
    else coverage(b,s,glyphs,f,8,ot_u16(b,s,6),PositionIndexed())
  | _ => PositionSingleRejected(ot_error(OtFormat(),s))
implement gpos_single_parse(b,s,glyphs) =
  if not(ot_span_valid(b,s)) orelse ilt(s.length,6) then PositionSingleRejected(ot_error(OtBounds(),s))
  else if not(ot_glyph_domain_valid(glyphs)) then PositionSingleRejected(ot_error(OtGlyphDomain(),s))
  else case+ ot_value_format(ot_u16(b,s,4)) of
    | ~ValueFormatRejected() => PositionSingleRejected(ot_error(OtFormat(),s))
    | ~ValueFormatAccepted(f) => format_of(b,s,glyphs,f)
