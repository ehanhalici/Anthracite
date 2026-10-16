#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "flag.sats"
staload "os/fs.sats"
staload "data_font/resources/font.sats"
staload "data_font/atlas/font_glyph_id.sats"
staload "data_font/text/run/font_run.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/position/glyph_position_types.sats"
staload "data_font/glyph/position/glyph_position.sats"
staload "data_font/sfnt/sfnt.sats"
staload "core_render/render.sats"
staload "core_render/gl.sats"
staload "font/text/run/font_run_render_contracts.sats"
staload "font/resources/font_gl_airlock.sats"
fun ready(status: FontRunStatus): bool = case+ status of | FontRunReady() => true | FontRunFace() => false
  | FontRunScale() => false | FontRunOverflow() => false | FontRunRaster() => false | FontRunGraph() => false
fun actual(f: !Font,r: !Rend,p: !GlyphPositioned(1),face: FontGlyphFace,errors: &int >> _): Buf = let
  val ()=rend_begin(r,640,480)
  val result=font_draw_positioned(f,r,p,@{face=face,font=3},50.25,72.5,col_white())
  val ()=if ready(result.status) andalso ieq(result.xAdvance,1400) andalso ieq(result.drawn,2) then () else errors := iadd(errors,1)
  val ()=rend_flush(r) val b=buf_make(WORD16_MODULUS) val ()=font_gl_read_pixels(b,128,128)
in b end
fun shape(f: !Font,r: !Rend,face: !SfntFace,slot: FontGlyphFace,d: GlyphPositionDirection,a: int,c: int): int = let
  val p=run_render_test_run(face,a,c,d) var errors: int=0
  val expected=run_render_test_reference(f,r,p,slot,d,errors) and image=actual(f,r,p,slot,errors)
  val ()=errors := iadd(errors,run_render_test_compare(expected,image))
  val wrong=font_draw_positioned(f,r,p,@{face=slot,font=4},50.25,72.5,col_white())
  val ()=if not(ready(wrong.status)) andalso ieq(wrong.drawn,0) then () else errors := iadd(errors,1)
  val ()=font_set_px(f,24) val wrong_size=font_draw_positioned(f,r,p,@{face=slot,font=3},50.25,72.5,col_white())
  val ()=if not(ready(wrong_size.status)) andalso ieq(wrong_size.drawn,0) then () else errors := iadd(errors,1)
  val ()=font_set_px(f,16)
  val ()=glyph_position_dispose(p) and ()=buf_free(expected) and ()=buf_free(image)
in errors end
fun loaded(f: !Font,r: !Rend,path: string,slot: FontGlyphFace,d: GlyphPositionDirection,a: int,c: int): int = case+ sfnt_open(path) of
  | ~RejectedSfnt(e) => 1 | ~LoadedSfnt(face) => let val errors=shape(f,r,face,slot,d,a,c) val ()=sfnt_dispose(face) in errors end
fun font(primary: string,source: string,r: !Rend,slot: FontGlyphFace,d: GlyphPositionDirection,a: int,c: int): int = let
  val f=font_open() val installed=font_use_file(f,primary)
  val selected=case+ slot of | GlyphPrimaryFace() => installed | GlyphFallbackFace() => font_use_fallback_file(f,source)
  val ()=font_set_px(f,16)
  val errors=loaded(f,r,source,slot,d,a,c)
  val ()=rend_flush(r) and ()=font_free(f)
in iadd(errors,if installed andalso selected then 0 else 1) end
implement run_render_test_faces(r,latin,arabic) = let
  val before=mem_live()
  val a=font(latin,latin,r,GlyphPrimaryFace(),PositionLTR(),65,86)+font(latin,latin,r,GlyphPrimaryFace(),PositionRTL(),65,86)
  val c=font(latin,arabic,r,GlyphFallbackFace(),PositionLTR(),1576,1578)+font(latin,arabic,r,GlyphFallbackFace(),PositionRTL(),1576,1578)
  val errors=iadd(iadd(a,c),if ieq(before,mem_live()) then 0 else 1)
  val ()=println!("event=font_run_render primary_errors=",a," fallback_errors=",c," total_errors=",errors)
in errors end
