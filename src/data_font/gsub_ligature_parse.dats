#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/opentype_coverage.sats"
staload "data_font/gsub_ligature_types.sats"
staload "data_font/gsub_ligatures.sats"
staload "data_font/gsub_ligature_work.sats"
fun accepted(b: !Buf,info: GsubLigatureInfo): GsubLigaturesRead = let
  var remaining: int=MAX_REC_FUEL
in if ine(info.count,info.coverage.total) then LigaturesRejected(ot_error(OtCoverageIndex(),info.span))
  else case+ gsub_ligatures_validate(b,info,remaining) of
    | ~Some_vt(e) => LigaturesRejected(e) | ~None_vt() => let
      val cached: GsubLigatureInfo= @{span=info.span,coverage=info.coverage,count=info.count,glyphs=info.glyphs,
        maximum=gsub_ligature_maximum(b,info)}
    in LigaturesAccepted(GsubLigatures(cached)) end end
fun covered(b: !Buf,s: OtSpan,glyphs: int,count: int): GsubLigaturesRead = let
  val child=ot_optional_child(s,ot_u16(b,s,2),iadd(6,imul(count,2)))
in case+ child.kind of
  | ChildMissing() => LigaturesRejected(ot_error(OtBounds(),s))
  | ChildInvalid() => LigaturesRejected(ot_error(OtBounds(),s))
  | ChildPresent() => case+ ot_coverage_parse(b,child.span,glyphs) of
    | ~CoverageRejected(e) => LigaturesRejected(e)
    | ~CoverageAccepted(c) => accepted(b,@{span=s,coverage=c,count=count,glyphs=glyphs,maximum=0}) end
implement gsub_ligatures_parse(b,s,glyphs) =
  if not(ot_span_valid(b,s)) orelse ilt(s.length,6) then LigaturesRejected(ot_error(OtBounds(),s))
  else if not(ot_glyph_domain_valid(glyphs)) then LigaturesRejected(ot_error(OtGlyphDomain(),s))
  else if ine(ot_u16(b,s,0),1) then LigaturesRejected(ot_error(OtFormat(),s)) else let val count=ot_u16(b,s,4) in
    if not(ot_rows_fit(s,6,count,2)) then LigaturesRejected(ot_error(OtBounds(),s))
    else covered(b,s,glyphs,count) end
