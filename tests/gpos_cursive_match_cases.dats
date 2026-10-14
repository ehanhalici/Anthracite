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
staload "opentype_fixture.sats"
staload "gpos_cursive_contracts.sats"
implement gpos_cursive_fixture() =
  ot_fixture_words("0001 000E 0002 0000 0016 001C 0000 0001 0002 0005 0006 0001 0064 00C8 0002 012C 0190 0007")
fun sample(b: !Buf,t: !GposCursive): int = let
  val a=gpos_cursive_query(b,t,5) and c=gpos_cursive_query(b,t,6)
  val missing=gpos_cursive_query(b,t,7)
  val pair=gpos_cursive_pair(b,t,5,6) and reverse=gpos_cursive_pair(b,t,6,5)
  val entry=case+ a.entry.kind of | AnchorMissing() => true | AnchorPresent() => false
  val exit=case+ c.exit.kind of | AnchorMissing() => true | AnchorPresent() => false
  val contour=case+ pair.entry.anchor.kind of | AnchorCoordinates() => false
    | AnchorContour() => ieq(pair.entry.anchor.point,7) | AnchorDevices() => false
in if a.matched andalso c.matched andalso not(missing.matched) andalso pair.matched
  andalso not(reverse.matched) andalso entry andalso exit andalso contour
  andalso ieq(pair.exit.anchor.x,100) andalso ieq(pair.entry.anchor.y,400) then 0 else 1 end
implement gpos_cursive_test_matches() = let val b=gpos_cursive_fixture()
  val errors=case+ gpos_cursive_parse(b,ot_fixture_span(b),10) of
    | ~CursiveRejected(e) => 1 | ~CursiveAccepted(t) => let val errors=sample(b,t)
      val ()=gpos_cursive_dispose(t) in errors end
  val ()=buf_free(b)
in errors end
