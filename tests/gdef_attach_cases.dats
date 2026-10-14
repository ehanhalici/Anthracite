#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/gdef_types.sats"
staload "data_font/gdef_header.sats"
staload "data_font/gdef_attach_types.sats"
staload "data_font/gdef_attach.sats"
staload "data_font/gpos_value_work.sats"
staload "opentype_fixture.sats"
staload "gdef_contracts.sats"

fun caret_kind_code(k: GdefCaretKind): int = case+ k of
  | CaretCoordinate() => 1 | CaretContour() => 2 | CaretDevice() => 3

fun checked(b: !Buf,h: GdefHeaderInfo): int = case+ gdef_attach_parse(b,h,16) of
  | ~GdefAttachRejected(e) => 1
  | ~GdefAttachAccepted(list) => let
    val count=gdef_attach_count(list)
    val first=gdef_attach_point(b,list,1)
    val absent=gdef_attach_point(b,list,99)
    val second=gdef_attach_point(b,list,3)
    val ()=gdef_attach_dispose(list)
    val ok=ieq(count,2) andalso ieq(first.count,3) andalso ieq(first.span.offset,52)
      andalso ieq(second.count,1) andalso ieq(absent.count,0)
  in if ok then 0 else 1 end

fun attach_case(s: string): int = let
  val b=ot_fixture_words(s)
  val errors=case+ gdef_header_parse(b,ot_fixture_span(b)) of
    | ~GdefHeaderRejected(e) => 1 | ~GdefHeaderAccepted(h) => checked(b,h)
  val ()=buf_free(b)
in errors end

fun attach_absent(s: string): int = let
  val b=ot_fixture_words(s)
  val errors=case+ gdef_header_parse(b,ot_fixture_span(b)) of
    | ~GdefHeaderRejected(e) => 1
    | ~GdefHeaderAccepted(h) => case+ gdef_attach_parse(b,h,16) of
      | ~GdefAttachRejected(e) => 1 | ~GdefAttachAccepted(a) => let
        val count=gdef_attach_count(a)
        val point=gdef_attach_point(b,a,3)
        val empty=ieq(count,0) andalso ieq(point.count,0)
        val ()=gdef_attach_dispose(a)
      in if empty then 0 else 1 end
  val ()=buf_free(b)
in errors end

fun attach_reject(s: string): int = let
  val b=ot_fixture_words(s)
  val errors=case+ gdef_header_parse(b,ot_fixture_span(b)) of
    | ~GdefHeaderRejected(e) => 0
    | ~GdefHeaderAccepted(h) => case+ gdef_attach_parse(b,h,16) of
      | ~GdefAttachRejected(e) => 0 | ~GdefAttachAccepted(a) => let val ()=gdef_attach_dispose(a) in 1 end
  val ()=buf_free(b)
in errors end

fun carets_checked(b: !Buf,h: GdefHeaderInfo): int = case+ gdef_carets_parse(b,h,16) of
  | ~GdefLigCaretsRejected(e) => 1
  | ~GdefLigCaretsAccepted(carets) => let
    val count=gdef_carets_count(carets)
    val lig=gdef_carets_ligature(b,carets,5)
    val absent=gdef_carets_ligature(b,carets,99)
    val coordinate=gdef_caret_value(b,carets,lig,0)
    val contour=gdef_caret_value(b,carets,lig,1)
    val device=gdef_caret_value(b,carets,lig,2)
    val beyond=gdef_caret_value(b,carets,lig,7)
    val ()=gdef_carets_dispose(carets)
    val ok=ieq(count,1) andalso ieq(lig.carets,3) andalso ieq(lig.span.offset,56)
      andalso ieq(absent.carets,0)
      andalso ieq(caret_kind_code(coordinate.kind),1) andalso ieq(coordinate.value,~40)
      andalso ieq(caret_kind_code(contour.kind),2) andalso ieq(contour.value,7)
      andalso ieq(caret_kind_code(device.kind),3) andalso igt(device.device.length,0)
      andalso ieq(caret_kind_code(beyond.kind),1) andalso ieq(beyond.value,0)
  in if ok then 0 else 1 end

fun carets_case(s: string): int = let
  val b=ot_fixture_words(s)
  val errors=case+ gdef_header_parse(b,ot_fixture_span(b)) of
    | ~GdefHeaderRejected(e) => 1 | ~GdefHeaderAccepted(h) => carets_checked(b,h)
  val ()=buf_free(b)
in errors end

fun carets_absent(s: string): int = let
  val b=ot_fixture_words(s)
  val errors=case+ gdef_header_parse(b,ot_fixture_span(b)) of
    | ~GdefHeaderRejected(e) => 1
    | ~GdefHeaderAccepted(h) => case+ gdef_carets_parse(b,h,16) of
      | ~GdefLigCaretsRejected(e) => 1 | ~GdefLigCaretsAccepted(c) => let
        val lig=gdef_carets_ligature(b,c,5)
        val value=gdef_caret_value(b,c,lig,0)
        val empty=ieq(gdef_carets_count(c),0) andalso ieq(lig.carets,0)
          andalso ieq(value.value,0)
        val ()=gdef_carets_dispose(c)
      in if empty then 0 else 1 end
  val ()=buf_free(b)
in errors end

fun carets_reject(s: string): int = let
  val b=ot_fixture_words(s)
  val errors=case+ gdef_header_parse(b,ot_fixture_span(b)) of
    | ~GdefHeaderRejected(e) => 0
    | ~GdefHeaderAccepted(h) => case+ gdef_carets_parse(b,h,16) of
      | ~GdefLigCaretsRejected(e) => 0 | ~GdefLigCaretsAccepted(c) => let val ()=gdef_carets_dispose(c) in 1 end
  val ()=buf_free(b)
in errors end

implement gdef_test_attach() =
  attach_case("0001 0000 0000 0018 0000 0000 0000 0000 0000 0000 0000 0000 000C 0002 0014 001C 0000 0000 0001 0002 0001 0003 0003 0001 0003 0005 0001 0009")
  +attach_absent("0001 0000 0000 0000 0000 0000")
  +attach_reject("0001 0000 0000 0006 0000 0000 0002 0002 0000 0000 000E 0000")
  +attach_reject("0001 0000 0000 0006 0000 0000 0001 0001 0000 0000 000E 0000")
  +attach_reject("0001 0000 0000 0004 0000 0000 0001 0002 0000 0000 000A 0000")
  +carets_case("0001 0000 0000 0000 0018 0000 0000 0000 0000 0000 0000 0000 000A 0001 0000 0018 0000 0001 0001 0005 0000 0000 0000 0000 0003 0010 0016 001E 0000 0000 0000 0000 0001 FFD8 0000 0002 0007 0000 0000 0003 0012 0030 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0002 0010 0030 0001 0008")
  +carets_absent("0001 0000 0000 0000 0000 0000")
  +carets_reject("0001 0000 0000 0000 0006 0000 0002 0001 0000 0000 0016 0000")
  +carets_reject("0001 0000 0000 0000 0006 0000 0001 0001 0000 0000 0016 0000")
  +carets_reject("0001 0000 0000 0000 0004 0000 0001 0001 0000 0000 0014 0000")
