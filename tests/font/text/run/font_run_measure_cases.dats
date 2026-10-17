#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "flag.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/glyph/position/glyph_position_types.sats"
staload "data_font/glyph/position/glyph_position.sats"
staload "data_font/resources/font.sats"
staload "data_font/atlas/font_glyph_id.sats"
staload "data_font/text/run/font_run.sats"
staload "data_font/text/run/private/font_run_work.sats"
staload "font/glyph/position/glyph_position_contracts.sats"
fun position(advance: int): GlyphPosition = @{xAdvance=advance,yAdvance=0,xOffset=0,yOffset=0,
  attachment=AttachmentNone(),parent= ~1,anchorX=0,anchorY=0}
fun basic(): int = let var errors: int=0 val p=position_test_run("0005 0006",errors)
  val ()=position_test_set(p,1,position(700))
  val p=position_test_frozen(glyph_position_finish(p,PositionRTL()),errors)
  val extent=font_run_measure(p)
  val ready=case+ extent.status of | FontRunReady() => true | FontRunFace() => false | FontRunScale() => false
    | FontRunOverflow() => false | FontRunRaster() => false | FontRunGraph() => false
  val ()=errors := iadd(errors,if ready andalso ieq(extent.xAdvance,1724) andalso ieq(extent.drawn,0) then 0 else 1)
  val ()=glyph_position_dispose(p)
in errors end
fun overflow(d: GlyphPositionDirection): int = let var errors: int=0 val p=position_test_run("0005 0005 0005 0005",errors)
  val ()=position_test_set(p,0,position(SIGNED_INT_MAX_VALUE)) and ()=position_test_set(p,1,position(SIGNED_INT_MAX_VALUE))
  val ()=position_test_set(p,2,position(~SIGNED_INT_MAX_VALUE)) and ()=position_test_set(p,3,position(~SIGNED_INT_MAX_VALUE))
  val p=position_test_frozen(glyph_position_finish(p,d),errors) val extent=font_run_measure(p)
  val bad=case+ extent.status of | FontRunOverflow() => true | FontRunReady() => false | FontRunFace() => false
    | FontRunScale() => false | FontRunRaster() => false | FontRunGraph() => false
  val ()=errors := iadd(errors,if bad then 0 else 1)
  val ()=glyph_position_dispose(p)
in errors end
fun geometry(): int = let
  val p: GlyphPosition= @{xAdvance=700,yAdvance=0,xOffset=31,yOffset=17,attachment=AttachmentNone(),parent= ~1,anchorX=0,anchorY=0}
  val g: gmet= @{ax=999,bx=2,top=8,bw=10,bh=11,x0=0,y0=0,ok=On()}
  val pen=font_run_origin(PositionRTL(),@{x=1400,y=0},p)
  val q=font_run_quad(pen,p,@{units=1024,xPpem=32,yPpem=16},g,50.25,72.5)
in if q.x = 65.671875 andalso q.y = 64.234375 andalso q.w = 20.0 andalso q.h = 11.0 then 0 else 1 end
implement position_test_measure_cases() = basic()+overflow(PositionLTR())+overflow(PositionRTL())+geometry()
