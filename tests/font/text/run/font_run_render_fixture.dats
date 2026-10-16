#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/resources/font.sats"
staload "data_font/atlas/font_glyph_id.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/run/glyph_run_storage.sats"
staload "data_font/glyph/run/glyph_run.sats"
staload "data_font/glyph/position/glyph_position_types.sats"
staload "data_font/glyph/position/glyph_position.sats"
staload "data_font/sfnt/sfnt.sats"
staload "core_render/render.sats"
staload "font/text/run/font_run_render_contracts.sats"
extern fun render_fixture_run_failed(): GlyphRun(0) = "mac#anth_die_box"
extern fun render_fixture_position_failed(): GlyphPositioned(0) = "mac#anth_die_box"
extern fun render_fixture_finish_failed(): GlyphPositioned(1) = "mac#anth_die_box"
fun failure(r: GlyphRun(0)): GlyphRun(0) = let val ()=glyph_run_dispose(r) in render_fixture_run_failed() end
fun take(edit: GlyphRunEdit(0)): GlyphRun(0) = let val+ ~GlyphRunEdited(r,status,node)=edit in
  case+ status of | GlyphUpdated() => r | GlyphUnchanged() => r | GlyphCapacity() => failure(r)
    | GlyphNode() => failure(r) | GlyphDomain() => failure(r) | GlyphSource() => failure(r)
    | GlyphOrder() => failure(r) | GlyphAssociationError() => failure(r) | GlyphOverflow() => failure(r) end
fun seed(face: !SfntFace,cp: int,start: int,limit: int): GlyphSeed =
  @{glyph=sfnt_glyph(face,cp),scalar=cp,sourceStart=start,sourceEnd=limit,cluster=start,mask=0u}
fun created(face: !SfntFace,a: int,c: int): GlyphRun(0) = let val info=sfnt_info(face)
  val step: int=if ilt(a,128) then 1 else 2
in case+ glyph_run_make(3,info.glyphs,imul(step,2),2) of | ~GlyphRunRejected(e) => render_fixture_run_failed()
  | ~GlyphRunCreated(r) => take(glyph_run_append(take(glyph_run_append(r,seed(face,a,0,step))),seed(face,c,step,imul(step,2)))) end
fun initialized(face: !SfntFace,r: GlyphRun(0)): GlyphPositioned(0) =
  case+ glyph_position_initialize(face,glyph_run_position(glyph_run_substitute(r)),16,16) of
  | ~PositionInitialized(p) => p | ~PositionRejected(r,status) => let val ()=glyph_run_dispose(r) in render_fixture_position_failed() end
fun shifted(p: !GlyphPositioned(0)): void = let val+ PositionAccumulating(r,scale)=p val+ GlyphRun(phase,meta,s)=r
  val ()=glyph_storage_set_position(s,0,@{xAdvance=700,yAdvance=0,xOffset=31,yOffset=17,
    attachment=AttachmentNone(),parent= ~1,anchorX=0,anchorY=0})
in glyph_storage_set_position(s,1,@{xAdvance=700,yAdvance=0,xOffset= ~11,yOffset= ~9,
  attachment=AttachmentNone(),parent= ~1,anchorX=0,anchorY=0}) end
implement run_render_test_run(face,a,c,d) = let val p=initialized(face,created(face,a,c)) val ()=shifted(p) in
  case+ glyph_position_finish(p,d) of | ~PositionFinished(p) => p
  | ~PositionUnfinished(p,status) => let val ()=glyph_position_dispose(p) in render_fixture_finish_failed() end end
