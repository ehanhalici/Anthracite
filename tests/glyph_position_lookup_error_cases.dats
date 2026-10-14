#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/ot_position_lookup_types.sats"
staload "data_font/ot_position_lookup.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/glyph_position_types.sats"
staload "glyph_position_contracts.sats"
staload "opentype_fixture.sats"
fun rejected(words: string): int = let val b=position_test_fixture(words,TestBaseClasses())
  val errors: int=case+ ot_position_lookup_parse(b,position_test_span(b),128) of
    | ~PositionLookupRejected(e) => 0 | ~PositionLookupAccepted(t) => let val ()=ot_position_lookup_dispose(t) in 1 end
  val ()=buf_free(b)
in errors end
implement position_test_lookup_error_cases() = rejected("0001 0000 0002 000A 0018 0003 0008 0004 0000 0001 0001 0005 0001 0008 0004 0005 0001 0002 0005 0006")
  +rejected("0009 0000 0002 000A 0012 0001 0001 0000 0010 0001 0002 0000 0016 0001 0008 0004 0000 0001 0001 0005 0001 0008 0004 0005 0001 0002 0005 0006")
  +rejected("0001 0020 0000")+rejected("0007 0000 0001 0008 FFFF")+rejected("0007 0000 0000")+rejected("0008 0000 0000")
