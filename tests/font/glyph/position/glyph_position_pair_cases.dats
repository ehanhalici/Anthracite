#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/position/gpos_pair_types.sats"
staload "data_font/opentype/position/gpos_pairs.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/core/glyph_metadata.sats"
staload "data_font/glyph/position/glyph_position_types.sats"
staload "data_font/glyph/position/glyph_position.sats"
staload "data_font/glyph/position/glyph_position_pair.sats"
staload "font/glyph/position/glyph_position_contracts.sats"
extern fun pair_position_test_failed(): GposPairs = "mac#anth_die_box"
fun table(b: !Buf): GposPairs = case+ gpos_pair_parse(b,position_test_span(b),128) of
  | ~PairRejected(e) => pair_position_test_failed() | ~PairAccepted(t) => t
fun ignore_marks(): OtLookupFlags = @{rtl=false,ignoreBase=false,ignoreLigature=false,ignoreMarks=true,useMarkSet=false,attachment=0}
fun basic(): int = let
  val b=position_test_fixture("0001 000C 0004 0000 0001 0012 0001 0001 0005 0001 0006 FFF6",TestBaseClasses())
  val t=table(b) and m=position_test_metadata(b)
  var errors: int=0
  val p=position_test_run("0005 0007 0006",errors)
  val p=position_test_take(glyph_position_pair(b,t,m,p,ignore_marks(),0,position_test_all()),3,1,errors)
  val ()=errors := errors+position_test_values(p,0,1014,0,0,0)+position_test_values(p,1,0,0,0,0)+position_test_values(p,2,0,0,0,0)
  val ()=glyph_position_dispose(p) and ()=glyph_metadata_dispose(m) and ()=gpos_pair_dispose(t) and ()=buf_free(b)
in errors end
fun blocked(): int = let
  val b=position_test_fixture("0001 000C 0004 0000 0001 0012 0001 0001 0005 0001 0006 FFF6",TestBaseClasses())
  val t=table(b) and m=position_test_metadata(b)
  var errors: int=0
  val p=position_test_run("0005 0006 0006",errors)
  val ()=position_test_mask(p,1,2u)
  val p=position_test_take(glyph_position_pair(b,t,m,p,position_test_flags(),0,@{kind=GlyphMasked(),mask=1u}),3,0,errors)
  val ()=errors := errors+position_test_values(p,0,1024,0,0,0)
  val ()=glyph_position_dispose(p) and ()=glyph_metadata_dispose(m) and ()=gpos_pair_dispose(t) and ()=buf_free(b)
in errors end
implement position_test_pair_cases() = basic()+blocked()
