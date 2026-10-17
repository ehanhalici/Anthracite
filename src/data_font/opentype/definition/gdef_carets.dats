#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
(* Initial allocation policy; capacities are measured in bytes. *)
macdef GDEF_CARETS_PARSE_BUFFER_INITIAL_BYTES = 0

staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_reader.sats"
staload "data_font/opentype/tables/opentype_coverage.sats"
staload "data_font/opentype/definition/gdef_types.sats"
staload "data_font/opentype/definition/gdef_attach_types.sats"
staload "data_font/opentype/definition/gdef_attach.sats"

fun covered(b: !Buf,s: OtSpan,child: OtChild,glyphs: int): OtCoverageRead = case+ child.kind of
  | ChildMissing() => CoverageRejected(ot_error(OtBounds(),s))
  | ChildInvalid() => CoverageRejected(ot_error(OtBounds(),s))
  | ChildPresent() => ot_coverage_parse(b,child.span,glyphs)

fun lig_glyph {n:nat} .<n>. (n: int(n),b: !Buf,s: OtSpan,output: !Buf,index: int,
  glyphs: int): Option_vt(OtError) =
  if n = 0 then None_vt() else let
    val relative=ot_u32(b,s,iadd(4,imul(index,4)))
    val child=ot_optional_child(s,relative,iadd(4,imul(n,4)))
  in case+ child.kind of
    | ChildMissing() => Some_vt(ot_error(OtBounds(),s))
    | ChildInvalid() => Some_vt(ot_error(OtBounds(),s))
    | ChildPresent() => let
      val ligspan=child.span
      val count=ot_u16(b,ligspan,0)
    in if not(ot_rows_fit(ligspan,2,count,2)) then Some_vt(ot_error(OtBounds(),ligspan))
      else let
        val ()=buf_set32(output,imul(index,7),ligspan.offset)
        val ()=buf_set32(output,iadd(imul(index,7),1),ligspan.length)
        val ()=buf_set32(output,iadd(imul(index,7),2),count)
      in lig_glyph(n-1,b,s,output,iadd(index,1),glyphs) end end end

fun compile(b: !Buf,s: OtSpan,count: int,glyphs: int,c: OtCoverageInfo): GdefLigCaretsRead = let
  val output=buf_make(imul(count,28))
  val errors=lig_glyph(airlock_nat(count),b,s,output,0,glyphs)
in case+ errors of
  | ~None_vt() => GdefLigCaretsAccepted(GdefLigCarets(output,count,c))
  | ~Some_vt(e) => let val ()=buf_free(output) in GdefLigCaretsRejected(e) end end

fun parse_present(b: !Buf,s: OtSpan,glyphs: int): GdefLigCaretsRead =
  if not(ot_span_valid(b,s)) orelse ilt(s.length,4) then GdefLigCaretsRejected(ot_error(OtBounds(),s))
  else let
    val count=ot_u16(b,s,2)
  in if not(ot_rows_fit(s,4,count,4)) then GdefLigCaretsRejected(ot_error(OtBounds(),s))
    else case+ covered(b,s,ot_optional_child(s,ot_u16(b,s,0),iadd(6,imul(count,4))),glyphs) of
      | ~CoverageRejected(e) => GdefLigCaretsRejected(e)
      | ~CoverageAccepted(c) => compile(b,s,count,glyphs,c) end

implement gdef_carets_parse(b,h,glyphs) =
  if not(ot_glyph_domain_valid(glyphs)) then GdefLigCaretsRejected(ot_error(OtGlyphDomain(),h.span)) else
    case+ h.carets.kind of
    | ChildMissing() => GdefLigCaretsAccepted(GdefLigCarets(buf_make(GDEF_CARETS_PARSE_BUFFER_INITIAL_BYTES),0,
        @{span= @{offset=0,length=0},encoding=OtList(),count=0,total=0}))
    | ChildInvalid() => GdefLigCaretsRejected(ot_error(OtBounds(),h.span))
    | ChildPresent() => parse_present(b,h.carets.span,glyphs)

implement gdef_carets_count(carets) = let val+ GdefLigCarets(descriptors,count,c)=carets in count end

fun lig_at(descriptors: !Buf,index: int): GdefLigGlyph = let val at=imul(index,7) in
  @{span= @{offset=buf_get32(descriptors,at),length=buf_get32(descriptors,iadd(at,1))},
    carets=buf_get32(descriptors,iadd(at,2))} end

fun empty_lig(): GdefLigGlyph = @{span= @{offset=0,length=0},carets=0}
implement gdef_carets_ligature(b,carets,glyph) = let
  val+ GdefLigCarets(descriptors,count,c)=carets
  val found=ot_coverage_index(b,c,glyph)
in if not(found.found) then empty_lig() else lig_at(descriptors,found.index) end

fun caret_signed16(raw: int): int = if ige(raw,WORD16_SIGN_BIT) then isub(raw,WORD16_MODULUS) else raw
fun empty_caret(): GdefCaretValue = @{kind=CaretCoordinate(),value=0,device= @{offset=0,length=0}}
fun caret_value(b: !Buf,lig: GdefLigGlyph,index: int): GdefCaretValue =
  if ilt(index,0) orelse ige(index,lig.carets) then empty_caret() else let
    val relative=ot_u16(b,lig.span,iadd(2,imul(index,2)))
    val child=ot_optional_child(lig.span,relative,iadd(2,imul(lig.carets,2)))
  in case+ child.kind of
    | ChildMissing() => empty_caret() | ChildInvalid() => empty_caret()
    | ChildPresent() => let val s=child.span val format=ot_u16(b,s,0)
      in case+ format of
        | 1 => @{kind=CaretCoordinate(),value=caret_signed16(ot_u16(b,s,2)),device= @{offset=0,length=0}}
        | 2 => @{kind=CaretContour(),value=ot_u16(b,s,2),device= @{offset=0,length=0}}
        | 3 => let val relative=ot_u16(b,s,4)
          in if ilt(relative,0) orelse ige(relative,s.length) then empty_caret() else
            @{kind=CaretDevice(),value=caret_signed16(ot_u16(b,s,2)),
              device= @{offset=iadd(s.offset,relative),length=isub(s.length,relative)}} end
        | _ => empty_caret() end end

implement gdef_caret_value(b,carets,lig,index) = caret_value(b,lig,index)

implement gdef_carets_dispose(carets) = let val+ ~GdefLigCarets(descriptors,count,c)=carets
in buf_free(descriptors) end
