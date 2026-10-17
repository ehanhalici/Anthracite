#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/position_lookup/ot_position_lookup_types.sats"
staload "data_font/opentype/position_lookup/ot_position_lookup.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/core/glyph_metadata.sats"
staload "data_font/glyph/position/glyph_position_types.sats"
staload "data_font/glyph/position/glyph_position.sats"
staload "data_font/glyph/position/glyph_position_lookup.sats"
staload "font/glyph/position/glyph_position_contracts.sats"
extern fun cached_position_test_failed(): OtPositionLookup = "mac#anth_die_box"
fun table(b: !Buf): OtPositionLookup = case+ ot_position_lookup_parse(b,position_test_span(b),128) of
  | ~PositionLookupRejected(e) => cached_position_test_failed() | ~PositionLookupAccepted(t) => t
fun check(words: string): int = let
  val b=position_test_fixture(words,TestBaseClasses()) val t=table(b) and m=position_test_metadata(b)
  var errors: int=0 val p=position_test_run("0005 0006 0007",errors)
  val p=position_test_take(glyph_position_lookup(b,t,m,p,position_test_all(),PositionLTR()),3,2,errors)
  val ()=errors := errors+position_test_values(p,0,1024,0,0,0)+position_test_values(p,1,5,0,0,0)+position_test_values(p,2,0,0,0,0)
  val p=position_test_take(glyph_position_lookup(b,t,m,p,position_test_all(),PositionLTR()),3,2,errors)
  val ()=errors := errors+position_test_values(p,0,1024,0,0,0)+position_test_values(p,1,10,0,0,0)
  val ()=glyph_position_dispose(p) and ()=glyph_metadata_dispose(m) and ()=ot_position_lookup_dispose(t) and ()=buf_free(b)
in errors end
implement position_test_lookup_cases() = check("0001 0000 0002 000A 0018 0001 0008 0004 0000 0001 0001 0005 0001 0008 0004 0005 0001 0002 0005 0006")
  +check("0009 0000 0002 000A 0012 0001 0001 0000 0010 0001 0001 0000 0016 0001 0008 0004 0000 0001 0001 0005 0001 0008 0004 0005 0001 0002 0005 0006")
