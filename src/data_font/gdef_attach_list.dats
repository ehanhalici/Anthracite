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
staload "data_font/gdef_attach_types.sats"
staload "data_font/gdef_attach.sats"

fun covered(b: !Buf,s: OtSpan,child: OtChild,glyphs: int): OtCoverageRead = case+ child.kind of
  | ChildMissing() => CoverageRejected(ot_error(OtBounds(),s))
  | ChildInvalid() => CoverageRejected(ot_error(OtBounds(),s))
  | ChildPresent() => ot_coverage_parse(b,child.span,glyphs)

fun attach_point {n:nat} .<n>. (n: int(n),b: !Buf,s: OtSpan,output: !Buf,index: int,
  glyphs: int): Option_vt(OtError) =
  if n = 0 then None_vt() else let
    val relative=ot_u16(b,s,iadd(4,imul(index,2)))
    val child=ot_optional_child(s,relative,iadd(4,imul(n,2)))
  in case+ child.kind of
    | ChildMissing() => Some_vt(ot_error(OtBounds(),s))
    | ChildInvalid() => Some_vt(ot_error(OtBounds(),s))
    | ChildPresent() => let
      val pointspan=child.span
      val count=ot_u16(b,pointspan,0)
    in if not(ot_rows_fit(pointspan,2,count,2)) then Some_vt(ot_error(OtBounds(),pointspan))
      else let
        val ()=buf_set32(output,imul(index,6),pointspan.offset)
        val ()=buf_set32(output,iadd(imul(index,6),1),pointspan.length)
        val ()=buf_set32(output,iadd(imul(index,6),2),count)
      in attach_point(n-1,b,s,output,iadd(index,1),glyphs) end end end

fun compile(b: !Buf,s: OtSpan,count: int,glyphs: int,c: OtCoverageInfo): GdefAttachRead = let
  val output=buf_make(imul(count,24))
  val errors=attach_point(airlock_nat(count),b,s,output,0,glyphs)
in case+ errors of
  | ~None_vt() => GdefAttachAccepted(GdefAttachList(output,count,c))
  | ~Some_vt(e) => let val ()=buf_free(output) in GdefAttachRejected(e) end end

fun parse_present(b: !Buf,s: OtSpan,glyphs: int): GdefAttachRead =
  if not(ot_span_valid(b,s)) orelse ilt(s.length,4) then GdefAttachRejected(ot_error(OtBounds(),s))
  else let
    val count=ot_u16(b,s,2)
  in if not(ot_rows_fit(s,4,count,4)) then GdefAttachRejected(ot_error(OtBounds(),s))
    else case+ covered(b,s,ot_optional_child(s,ot_u16(b,s,0),iadd(4,imul(count,4))),glyphs) of
      | ~CoverageRejected(e) => GdefAttachRejected(e)
      | ~CoverageAccepted(c) => compile(b,s,count,glyphs,c) end

implement gdef_attach_parse(b,h,glyphs) =
  if not(ot_glyph_domain_valid(glyphs)) then GdefAttachRejected(ot_error(OtGlyphDomain(),h.span)) else
    case+ h.attach.kind of
    | ChildMissing() => GdefAttachAccepted(GdefAttachList(buf_make(0),0,
        @{span= @{offset=0,length=0},encoding=OtList(),count=0,total=0}))
    | ChildInvalid() => GdefAttachRejected(ot_error(OtBounds(),h.span))
    | ChildPresent() => parse_present(b,h.attach.span,glyphs)

implement gdef_attach_count(attach) = let val+ GdefAttachList(descriptors,count,c)=attach in count end

fun point_at(descriptors: !Buf,index: int): GdefAttachPoint = let val at=imul(index,6) in
  @{span= @{offset=buf_get32(descriptors,at),length=buf_get32(descriptors,iadd(at,1))},
    count=buf_get32(descriptors,iadd(at,2))} end

fun empty_point(): GdefAttachPoint = @{span= @{offset=0,length=0},count=0}
implement gdef_attach_point(b,attach,glyph) = let
  val+ GdefAttachList(descriptors,count,c)=attach
  val found=ot_coverage_index(b,c,glyph)
in if not(found.found) then empty_point() else point_at(descriptors,found.index) end

implement gdef_attach_dispose(attach) = let val+ ~GdefAttachList(descriptors,count,c)=attach
in buf_free(descriptors) end
