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
fun signed16_of(raw: int): int = if ige(raw,32768) then isub(raw,65536) else raw
fun delta(b: !Buf,s: OtSpan,c: OtCoverageInfo,glyphs: int): GsubSingleRead = let
  val d=signed16_of(ot_u16(b,s,4))
in if not(gsub_delta_valid(b,c,d,glyphs)) then SingleRejected(ot_error(OtGlyphDomain(),s))
  else SingleAccepted(GsubSingle(@{span=s,coverage=c,encoding=GsubDelta(),delta=d,count=c.total,glyphs=glyphs})) end
fun array(b: !Buf,s: OtSpan,c: OtCoverageInfo,glyphs: int): GsubSingleRead = let
  val count=ot_u16(b,s,4)
in if ine(c.total,count) then SingleRejected(ot_error(OtCoverageIndex(),s))
  else if not(gsub_array_valid(b,s,count,glyphs)) then SingleRejected(ot_error(OtGlyphDomain(),s))
  else SingleAccepted(GsubSingle(@{span=s,coverage=c,encoding=GsubArray(),delta=0,count=count,glyphs=glyphs})) end
fun covered(b: !Buf,s: OtSpan,encoding: GsubSingleEncoding,glyphs: int,floor: int): GsubSingleRead = let
  val child=ot_optional_child(s,ot_u16(b,s,2),floor)
in case+ child.kind of
  | ChildMissing() => SingleRejected(ot_error(OtBounds(),s))
  | ChildInvalid() => SingleRejected(ot_error(OtBounds(),s))
  | ChildPresent() => case+ ot_coverage_parse(b,child.span,glyphs) of
    | ~CoverageRejected(e) => SingleRejected(e)
    | ~CoverageAccepted(c) => case+ encoding of
      | GsubDelta() => delta(b,s,c,glyphs) | GsubArray() => array(b,s,c,glyphs) end
fun format_of(b: !Buf,s: OtSpan,glyphs: int): GsubSingleRead = case+ ot_u16(b,s,0) of
  | 1 => covered(b,s,GsubDelta(),glyphs,6)
  | 2 => let val count=ot_u16(b,s,4) in
    if not(ot_rows_fit(s,6,count,2)) then SingleRejected(ot_error(OtBounds(),s))
    else covered(b,s,GsubArray(),glyphs,iadd(6,imul(count,2))) end
  | _ => SingleRejected(ot_error(OtFormat(),s))
implement gsub_single_parse(b,s,glyphs) =
  if not(ot_span_valid(b,s)) orelse ilt(s.length,6) then SingleRejected(ot_error(OtBounds(),s))
  else if not(ot_glyph_domain_valid(glyphs)) then SingleRejected(ot_error(OtGlyphDomain(),s))
  else format_of(b,s,glyphs)
