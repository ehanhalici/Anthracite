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
staload "data_font/opentype/position/gpos_anchor_cache_types.sats"
staload "data_font/opentype/position/gpos_anchor_cache.sats"
staload "data_font/opentype/position/gpos_mark_shared_types.sats"
staload "data_font/opentype/position/gpos_mark_shared.sats"
staload "data_font/opentype/tables/opentype_coverage.sats"
staload "data_font/opentype/position/gpos_mark_shared_work.sats"
implement gpos_mark_coverage(b,s,field,glyphs) = let
  val child=ot_optional_child(s,ot_u16(b,s,field),12)
in case+ child.kind of
  | ChildMissing() => CoverageRejected(ot_error(OtBounds(),s))
  | ChildInvalid() => CoverageRejected(ot_error(OtBounds(),s))
  | ChildPresent() => ot_coverage_parse(b,child.span,glyphs) end
fun targets(b: !Buf,s: OtSpan,glyphs: int,marks: OtCoverageInfo): GposMarkHeaderRead =
  case+ gpos_mark_coverage(b,s,4,glyphs) of
  | ~CoverageRejected(e) => MarkHeaderRejected(e)
  | ~CoverageAccepted(c) => gpos_mark_arrays(b,s,marks,c,glyphs)
implement gpos_mark_header(b,s,glyphs) =
  if not(ot_span_valid(b,s)) orelse ilt(s.length,12) then MarkHeaderRejected(ot_error(OtBounds(),s))
  else if not(ot_glyph_domain_valid(glyphs)) then MarkHeaderRejected(ot_error(OtGlyphDomain(),s))
  else if ine(ot_u16(b,s,0),1) orelse ieq(ot_u16(b,s,6),0) then MarkHeaderRejected(ot_error(OtFormat(),s))
  else case+ gpos_mark_coverage(b,s,2,glyphs) of
    | ~CoverageRejected(e) => MarkHeaderRejected(e) | ~CoverageAccepted(c) => targets(b,s,glyphs,c)
