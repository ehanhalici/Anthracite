#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/definition/gdef_types.sats"
staload "data_font/opentype/definition/gdef_header.sats"
staload "data_font/opentype/definition/gdef_classes.sats"
staload "font/opentype/tables/opentype_fixture.sats"
staload "font/opentype/definition/gdef_contracts.sats"

fun kind_code(k: GdefGlyphKind): int = case+ k of
  | GlyphUnclassified() => 0 | GlyphBase() => 1 | GlyphLigature() => 2
  | GlyphMark() => 3 | GlyphComponent() => 4

fun metadata(b: !Buf,h: GdefHeaderInfo): int = case+ gdef_classes_parse(b,h,16) of
  | ~GdefClassRejected(e) => 1
  | ~GdefClassAccepted(m) => let
    val a=kind_code(gdef_glyph_kind(b,m,1))
    val c=kind_code(gdef_glyph_kind(b,m,2))
    val d=kind_code(gdef_glyph_kind(b,m,3))
    val e=kind_code(gdef_glyph_kind(b,m,4))
    val f=kind_code(gdef_glyph_kind(b,m,0))
    val mark=gdef_mark_attachment(b,m,3)
  in if ieq(a,1) andalso ieq(c,2) andalso ieq(d,3) andalso ieq(e,4) andalso ieq(f,0)
    andalso ieq(mark,WORD16_MAX_VALUE) andalso m.defined andalso m.attachmentDefined then 0 else 1 end

fun valid_metadata(): int = let
  val b=ot_fixture_words("0001 0000 000C 0000 0000 001A 0001 0001 0004 0001 0002 0003 0004 0002 0001 0003 0003 FFFF")
  val errors=case+ gdef_header_parse(b,ot_fixture_span(b)) of
    | ~GdefHeaderRejected(e) => 1 | ~GdefHeaderAccepted(h) => metadata(b,h)
  val ()=buf_free(b)
in errors end

fun absent_classes(b: !Buf,h: GdefHeaderInfo): int = case+ gdef_classes_parse(b,h,16) of
  | ~GdefClassRejected(e) => 1
  | ~GdefClassAccepted(m) => if m.defined orelse m.attachmentDefined then 1 else
    if ieq(kind_code(gdef_glyph_kind(b,m,0)),0) andalso ieq(gdef_mark_attachment(b,m,1),0) then 0 else 1

fun absent(s: string): int = let
  val b=ot_fixture_words(s)
  val errors=case+ gdef_header_parse(b,ot_fixture_span(b)) of
    | ~GdefHeaderRejected(e) => 1 | ~GdefHeaderAccepted(h) => absent_classes(b,h)
  val ()=buf_free(b)
in errors end

fun reject(s: string): int = let
  val b=ot_fixture_words(s)
  val errors=case+ gdef_header_parse(b,ot_fixture_span(b)) of
    | ~GdefHeaderRejected(e) => 0 | ~GdefHeaderAccepted(h) => 1
  val ()=buf_free(b)
in errors end

fun malformed_class(): int = let
  val b=ot_fixture_words("0001 0000 000C 0000 0000 0000 0001 0001 0001 0005")
  val errors=case+ gdef_header_parse(b,ot_fixture_span(b)) of
    | ~GdefHeaderRejected(e) => 1
    | ~GdefHeaderAccepted(h) => case+ gdef_classes_parse(b,h,16) of
      | ~GdefClassRejected(e) => 0 | ~GdefClassAccepted(m) => 1
  val ()=buf_free(b)
in errors end

implement gdef_test_metadata() =
  valid_metadata()+malformed_class()+
  absent("0001 0000 0000 0000 0000 0000")+
  absent("0001 0002 0000 0000 0000 0000 0000")+
  absent("0001 0003 0000 0000 0000 0000 0000 0000 0000")+
  reject("0001 0001 0000 0000 0000 0000")+
  reject("0001 0002 0000 0000 0000 0000")+
  reject("0001 0003 0000 0000 0000 0000 0000")+
  reject("0001 0000 0002 0000 0000 0000")+
  reject("0001 0000 FFFF 0000 0000 0000")+
  reject("0001 0003 0000 0000 0000 0000 0000 8000 0000")
