#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/opentype_coverage.sats"
staload "data_font/gdef_types.sats"
staload "data_font/gdef_marks.sats"
staload "data_font/gdef_mark_storage.sats"

fun coverage(b: !Buf,s: OtSpan,index: int,count: int,glyphs: int): OtCoverageRead = let
  val relative=ot_u32(b,s,iadd(4,imul(index,4)))
  val child=ot_optional_child(s,relative,iadd(4,imul(count,4)))
in case+ child.kind of
  | ChildMissing() => CoverageRejected(ot_error(OtBounds(),s))
  | ChildInvalid() => CoverageRejected(ot_error(OtBounds(),s))
  | ChildPresent() => ot_coverage_parse(b,child.span,glyphs) end

fun descriptors {n:nat} .<n>. (n: int(n),b: !Buf,s: OtSpan,output: !Buf,
  index: int,count: int,glyphs: int): Option_vt(OtError) =
  if n = 0 then None_vt() else case+ coverage(b,s,index,count,glyphs) of
  | ~CoverageRejected(e) => Some_vt(e)
  | ~CoverageAccepted(c) => let val ()=gdef_mark_descriptor_put(output,index,c) in
    descriptors(n-1,b,s,output,iadd(index,1),count,glyphs) end

fun compile_sets(b: !Buf,s: OtSpan,count: int,glyphs: int): GdefMarksRead = let
  val output=buf_make(imul(count,20))
  val errors=descriptors(airlock_nat(count),b,s,output,0,count,glyphs)
in case+ errors of
  | ~None_vt() => GdefMarksAccepted(GdefMarkSets(output,count))
  | ~Some_vt(e) => let val ()=buf_free(output) in GdefMarksRejected(e) end end

fun parse_present(b: !Buf,s: OtSpan,glyphs: int): GdefMarksRead =
  if not(ot_span_valid(b,s)) orelse ilt(s.length,4) then GdefMarksRejected(ot_error(OtBounds(),s))
  else if ine(ot_u16(b,s,0),1) then GdefMarksRejected(ot_error(OtFormat(),s)) else let
    val count=ot_u16(b,s,2)
  in if not(ot_rows_fit(s,4,count,4)) then GdefMarksRejected(ot_error(OtBounds(),s))
    else compile_sets(b,s,count,glyphs) end

implement gdef_marks_parse(b,h,glyphs) =
  if not(ot_glyph_domain_valid(glyphs)) then GdefMarksRejected(ot_error(OtGlyphDomain(),h.span)) else
    case+ h.markSets.kind of
    | ChildMissing() => GdefMarksAccepted(GdefNoMarks())
    | ChildInvalid() => GdefMarksRejected(ot_error(OtBounds(),h.span))
    | ChildPresent() => parse_present(b,h.markSets.span,glyphs)
