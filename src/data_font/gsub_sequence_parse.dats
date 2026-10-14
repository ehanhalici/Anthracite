#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/opentype_coverage.sats"
staload "data_font/gsub_sequence_types.sats"
staload "data_font/gsub_sequences.sats"
staload "data_font/gsub_sequence_work.sats"
staload "data_font/ot_layout_work.sats"
fun accepted{kind:int}(b: !Buf,info: GsubSequenceInfo,domain: GsubSequenceDomain(kind),
  remaining: &int >> _): GsubSequencesRead(kind) =
  if ine(info.count,info.coverage.total) then SequencesRejected(ot_error(OtCoverageIndex(),info.span))
  else case+ gsub_sequences_validate(b,info,domain,remaining) of
    | ~Some_vt(e) => SequencesRejected(e) | ~None_vt() => SequencesAccepted(GsubSequences(info))
fun covered{kind:int}(b: !Buf,s: OtSpan,glyphs: int,count: int,
  domain: GsubSequenceDomain(kind),remaining: &int >> _): GsubSequencesRead(kind) = let
  val child=ot_optional_child(s,ot_u16(b,s,2),iadd(6,imul(count,2)))
in case+ child.kind of
  | ChildMissing() => SequencesRejected(ot_error(OtBounds(),s))
  | ChildInvalid() => SequencesRejected(ot_error(OtBounds(),s))
  | ChildPresent() => case+ ot_coverage_parse(b,child.span,glyphs) of
    | ~CoverageRejected(e) => SequencesRejected(e)
    | ~CoverageAccepted(c) => accepted(b,@{span=s,coverage=c,count=count,glyphs=glyphs},domain,remaining) end
implement gsub_sequences_parse_work(b,s,glyphs,domain,remaining) =
  if not(ot_span_valid(b,s)) orelse ilt(s.length,6) then SequencesRejected(ot_error(OtBounds(),s))
  else if not(ot_glyph_domain_valid(glyphs)) then SequencesRejected(ot_error(OtGlyphDomain(),s))
  else if ine(ot_u16(b,s,0),1) then SequencesRejected(ot_error(OtFormat(),s)) else let
    val count=ot_u16(b,s,4)
  in if not(ot_rows_fit(s,6,count,2)) then SequencesRejected(ot_error(OtBounds(),s))
    else if not(ot_layout_charge(remaining,iadd(count,1))) then SequencesRejected(ot_error(OtCapacity(),s))
    else covered(b,s,glyphs,count,domain,remaining) end
implement gsub_sequences_parse(b,s,glyphs,domain) = let var remaining: int=MAX_REC_FUEL in
  gsub_sequences_parse_work(b,s,glyphs,domain,remaining) end
