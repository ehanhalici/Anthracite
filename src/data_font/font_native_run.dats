#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "data_font/font.sats"
staload "data_font/font_run.sats"
staload "data_font/font_native_types.sats"
staload "data_font/font_native.sats"
staload "data_font/glyph_position.sats"
staload "data_font/private/font_run_work.sats"
staload "data_font/private/font_native_owner.sats"
implement font_native_run_check(f,run) = let val+ FontNativeRun(positioned,token)=run
  val current=font_native_current(f,token.face)
in if ine(current.font,token.font) orelse ine(current.generation,token.generation) then FontRunFace()
  else font_run_binding_check(f,positioned,@{face=token.face,font=token.font}) end
implement font_draw_native_run(f,r,run,x,baseline,color) = let
  val status=font_native_run_check(f,run) val+ FontNativeRun(positioned,token)=run
in case+ status of
  | FontRunReady() => font_draw_positioned(f,r,positioned,@{face=token.face,font=token.font},x,baseline,color)
  | FontRunFace() => @{status=status,xAdvance=0,yAdvance=0,drawn=0}
  | FontRunScale() => @{status=status,xAdvance=0,yAdvance=0,drawn=0}
  | FontRunOverflow() => @{status=status,xAdvance=0,yAdvance=0,drawn=0}
  | FontRunRaster() => @{status=status,xAdvance=0,yAdvance=0,drawn=0}
  | FontRunGraph() => @{status=status,xAdvance=0,yAdvance=0,drawn=0} end
implement font_native_run_dispose(run) = let val+ ~FontNativeRun(positioned,token)=run
in glyph_position_dispose(positioned) end
