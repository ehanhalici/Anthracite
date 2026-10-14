#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/ot_position_lookup_types.sats"
staload "data_font/ot_position_lookup.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/glyph_metadata.sats"
staload "data_font/glyph_position_types.sats"
staload "data_font/glyph_position.sats"
staload "data_font/glyph_position_lookup.sats"
staload "glyph_position_contracts.sats"
extern fun cached_pair_position_test_failed(): OtPositionLookup = "mac#anth_die_box"
fun table(b: !Buf): OtPositionLookup = case+ ot_position_lookup_parse(b,position_test_span(b),128) of
  | ~PositionLookupRejected(e) => cached_pair_position_test_failed() | ~PositionLookupAccepted(t) => t
fun check(words: string,matches: int,second: int): int = let
  val b=position_test_fixture(words,TestBaseClasses()) val t=table(b) and m=position_test_metadata(b)
  var errors: int=0 val p=position_test_run("0005 0005 0005",errors)
  val p=position_test_take(glyph_position_lookup(b,t,m,p,position_test_all(),PositionLTR()),3,matches,errors)
  val ()=errors := errors+position_test_values(p,0,1031,0,0,0)+position_test_values(p,1,second,0,0,0)+position_test_values(p,2,0,0,0,0)
  val ()=glyph_position_dispose(p) and ()=glyph_metadata_dispose(m) and ()=ot_position_lookup_dispose(t) and ()=buf_free(b)
in errors end
implement position_test_lookup_pair_cases() = check("0002 0000 0001 0008 0001 000C 0004 0001 0001 0012 0001 0001 0005 0001 0005 0007 0000",1,0)
  +check("0002 0000 0001 0008 0001 000C 0004 0000 0001 0012 0001 0001 0005 0001 0005 0007",2,7)
