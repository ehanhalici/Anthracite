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
staload "opentype_fixture.sats"
staload "gpos_value_contracts.sats"
staload "data_font/gpos_single_types.sats"
staload "data_font/gpos_single.sats"
staload "gpos_single_contracts.sats"
fun check(b: !Buf,glyph: int,xp: int,xa: int,matched: bool): int =
  case+ gpos_single_parse(b,ot_fixture_span(b),10) of
  | ~PositionSingleRejected(e) => 1 | ~PositionSingleAccepted(t) => let
    val r=gpos_single_query(b,t,glyph)
    val ok=(r.matched = matched) andalso ieq(r.value.units.xPlace,xp) andalso ieq(r.value.units.xAdvance,xa)
    val ()=gpos_single_dispose(t)
  in if ok then 0 else 1 end
fun fixture(s: string): int = let
  val b=ot_fixture_words(s)
  val errors=check(b,5,~1,2,true)+check(b,6,~1,2,true)+check(b,4,0,0,false)
  val ()=buf_free(b)
in errors end
fun indexed(): int = let
  val b=ot_fixture_words("0002 0010 0005 0002 FFFF 0002 0003 FFFC 0001 0002 0005 0006")
  val errors=check(b,5,~1,2,true)+check(b,6,3,~4,true)+check(b,4,0,0,false)
  val ()=buf_free(b)
in errors end
fun zero(): int = let
  val b=ot_fixture_words("0002 0008 0000 0002 0001 0002 0005 0006")
  val errors=check(b,5,0,0,true)+check(b,6,0,0,true)+check(b,4,0,0,false)
  val ()=buf_free(b)
in errors end
fun device(): int = let
  val b=ot_fixture_words("0001 0008 0010 000E 0001 0001 0005 0005 0006 0001 B000")
  val errors=case+ gpos_single_parse(b,ot_fixture_span(b),10) of
    | ~PositionSingleRejected(e) => 1 | ~PositionSingleAccepted(t) => let
      val r=gpos_single_query(b,t,5)
      val sample=ot_value_sample(b,r.value,5)
      val ()=gpos_single_dispose(t)
    in if r.matched andalso ieq(sample.xPlace.pixels,~2) then 0 else 1 end
  val ()=buf_free(b)
in errors end
implement gpos_single_test_matches() =
  fixture("0001 000A 0005 FFFF 0002 0001 0002 0005 0006")+indexed()+zero()+device()
