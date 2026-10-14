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
staload "data_font/gpos_anchor_cache_types.sats"
staload "data_font/gpos_anchor_cache.sats"
staload "data_font/gpos_cursive_types.sats"
staload "data_font/gpos_cursive.sats"
staload "data_font/opentype_coverage.sats"
staload "data_font/gpos_cursive_work.sats"
fun anchors(b: !Buf,s: OtSpan,c: OtCoverageInfo,count: int,floor: int,glyphs: int): GposCursiveRead =
  if ine(c.total,count) then CursiveRejected(ot_error(OtCoverageIndex(),s)) else let
    val fields=gpos_cursive_fields(count)
    val read=ot_anchor_cache_read(b,s,fields,floor,AnchorOptional())
    val ()=buf_free(fields)
  in case+ read of | ~AnchorCacheRejected(e) => CursiveRejected(e)
    | ~AnchorCacheAccepted(cache) => CursiveAccepted(GposCursive(c,glyphs,cache)) end
fun coverage(b: !Buf,s: OtSpan,count: int,glyphs: int): GposCursiveRead = let
  val floor=iadd(6,imul(count,4))
  val child=ot_optional_child(s,ot_u16(b,s,2),floor)
in case+ child.kind of
  | ChildMissing() => CursiveRejected(ot_error(OtBounds(),s))
  | ChildInvalid() => CursiveRejected(ot_error(OtBounds(),s))
  | ChildPresent() => case+ ot_coverage_parse(b,child.span,glyphs) of
    | ~CoverageRejected(e) => CursiveRejected(e) | ~CoverageAccepted(c) => anchors(b,s,c,count,floor,glyphs) end
implement gpos_cursive_parse(b,s,glyphs) =
  if not(ot_span_valid(b,s)) orelse ilt(s.length,6) then CursiveRejected(ot_error(OtBounds(),s))
  else if not(ot_glyph_domain_valid(glyphs)) then CursiveRejected(ot_error(OtGlyphDomain(),s))
  else if ine(ot_u16(b,s,0),1) then CursiveRejected(ot_error(OtFormat(),s)) else let val count=ot_u16(b,s,4) in
    if not(ot_rows_fit(s,6,count,4)) then CursiveRejected(ot_error(OtBounds(),s))
    else coverage(b,s,count,glyphs) end
