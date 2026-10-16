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
staload "font/opentype/tables/opentype_fixture.sats"
staload "font/opentype/position/gpos_value_contracts.sats"
fun check(words: string,kind: OtAnchorKind,point: int): int = let
  val b=ot_fixture_words(words)
  val errors=case+ ot_anchor_parse(b,ot_fixture_span(b)) of
    | ~AnchorRejected(e) => 1 | ~AnchorAccepted(a) => let
      val typed=case+ a.kind of
        | AnchorCoordinates() => (case+ kind of | AnchorCoordinates() => true | AnchorContour() => false | AnchorDevices() => false)
        | AnchorContour() => (case+ kind of | AnchorCoordinates() => false | AnchorContour() => true | AnchorDevices() => false)
        | AnchorDevices() => (case+ kind of | AnchorCoordinates() => false | AnchorContour() => false | AnchorDevices() => true)
      val dx=ot_adjustment_sample(b,a.dx,5) and dy=ot_adjustment_sample(b,a.dy,5)
      val pixels=case+ kind of | AnchorCoordinates() => ieq(dx.pixels,0) andalso ieq(dy.pixels,0)
        | AnchorContour() => ieq(dx.pixels,0) andalso ieq(dy.pixels,0)
        | AnchorDevices() => ieq(dx.pixels,~2) andalso (case+ dy.kind of
          | PixelResolved() => false | PixelVariation() => ieq(dy.outer,WORD16_MAX_VALUE) andalso ieq(dy.inner,65534))
    in if typed andalso ieq(a.x,~WORD16_SIGN_BIT) andalso ieq(a.y,32767) andalso ieq(a.point,point) andalso pixels then 0 else 1 end
  val ()=buf_free(b)
in errors end
implement gpos_test_anchors() = check("0001 8000 7FFF",AnchorCoordinates(),0)+
  check("0002 8000 7FFF FFFF",AnchorContour(),WORD16_MAX_VALUE)+
  check("0003 8000 7FFF 000A 0012 0005 0006 0001 B000 FFFF FFFE 8000",AnchorDevices(),0)
