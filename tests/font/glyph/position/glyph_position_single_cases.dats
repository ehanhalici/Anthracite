#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/position/gpos_single_types.sats"
staload "data_font/opentype/position/gpos_single.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/core/glyph_metadata.sats"
staload "data_font/glyph/position/glyph_position_types.sats"
staload "data_font/glyph/position/glyph_position.sats"
staload "data_font/glyph/position/glyph_position_single.sats"
staload "font/glyph/position/glyph_position_contracts.sats"
extern fun single_position_test_failed(): GposSingle = "mac#anth_die_box"
fun table(b: !Buf): GposSingle = case+ gpos_single_parse(b,position_test_span(b),128) of
  | ~PositionSingleRejected(e) => single_position_test_failed() | ~PositionSingleAccepted(t) => t
fun basic(): int = let
  val b=position_test_fixture("0001 000A 0005 FFFF 0002 0001 0002 0005 0006",TestBaseClasses())
  val t=table(b) and m=position_test_metadata(b)
  var errors: int=0
  val p=position_test_run("0005 0006 0007",errors)
  val p=position_test_take(glyph_position_single(b,t,m,p,position_test_flags(),0,position_test_all()),3,2,errors)
  val ()=errors := errors+position_test_values(p,0,1026,0,~1,0)+position_test_values(p,1,2,0,~1,0)+position_test_values(p,2,0,0,0,0)
  val ()=glyph_position_dispose(p) and ()=glyph_metadata_dispose(m) and ()=gpos_single_dispose(t) and ()=buf_free(b)
in errors end
fun atomic(): int = let
  val b=position_test_fixture("0001 000A 0005 FFFF 0002 0001 0002 0005 0006",TestBaseClasses())
  val t=table(b) and m=position_test_metadata(b)
  var errors: int=0
  val p=position_test_run("0005 0006",errors)
  val ()=position_test_set(p,1,@{xAdvance=SIGNED_INT_MAX_VALUE,yAdvance=0,xOffset=0,yOffset=0,
    attachment=AttachmentNone(),parent= ~1,anchorX=0,anchorY=0})
  val+ ~GlyphPositionResult(p,status,v,matches)=glyph_position_single(b,t,m,p,position_test_flags(),0,position_test_all())
  val ok=case+ status of | PositionOverflow() => true | PositionReady() => false | PositionDomain() => false
    | PositionReference() => false | PositionCapacity() => false | PositionVariation() => false
  val ()=errors := iadd(errors,if ok andalso ieq(v,0) andalso ieq(matches,0) then 0 else 1)
  val ()=errors := errors+position_test_values(p,0,1024,0,0,0)+position_test_values(p,1,SIGNED_INT_MAX_VALUE,0,0,0)
  val ()=glyph_position_dispose(p) and ()=glyph_metadata_dispose(m) and ()=gpos_single_dispose(t) and ()=buf_free(b)
in errors end
implement position_test_single_cases() = basic()+atomic()
