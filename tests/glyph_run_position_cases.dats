#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_run_storage.sats"
staload "data_font/glyph_run.sats"
staload "glyph_run_contracts.sats"
fun attached(parent: int): GlyphPosition = @{xAdvance=0,yAdvance=0,xOffset= ~5,yOffset=7,
  attachment=AttachmentMark(),parent=parent,anchorX=3,anchorY=4}
fun cascade(run: GlyphRun(2),errors: &int >> _): GlyphRun(2) = let
  val run=run_test_take(glyph_run_set_position(run,1,attached(0)),run_test_updated,errors)
  val run=run_test_take(glyph_run_set_position(run,2,attached(1)),run_test_updated,errors)
  val run=run_test_take(glyph_run_set_position(run,0,attached(2)),run_test_rejected,errors)
  val run=run_test_take(glyph_run_set_position(run,1,attached(1)),run_test_rejected,errors)
  val run=run_test_take(glyph_run_set_position(run,4,attached(99)),run_test_rejected,errors)
  val base=glyph_run_query(run,0)
  val ()=if ieq(base.position.parent,~1) andalso ieq(base.position.xOffset,0) then () else errors := iadd(errors,1)
in run end
fun cursive(run: GlyphRun(2),errors: &int >> _): GlyphRun(2) = let
  val p: GlyphPosition= @{xAdvance=10,yAdvance=0,xOffset=0,yOffset= ~3,
    attachment=AttachmentCursive(),parent=4,anchorX=8,anchorY=9}
  val run=run_test_take(glyph_run_set_position(run,3,p),run_test_updated,errors)
  val run=run_test_take(glyph_run_set_position(run,4,attached(3)),run_test_rejected,errors)
in run end
implement run_test_positions() = let var errors: int=0
  val run=glyph_run_position(glyph_run_substitute(run_test_nominal(8,6,errors)))
  val run=cursive(cascade(run,errors),errors)
  val run=glyph_run_freeze(run)
  val v=glyph_run_query(run,2)
  val ()=if ieq(v.position.xAdvance,0) andalso ieq(v.position.parent,1)
    andalso ieq(v.core.sourceStart,4) andalso ieq(v.core.sourceEnd,6) then () else errors := iadd(errors,1)
  val ()=glyph_run_dispose(run)
in errors end
