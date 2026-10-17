#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "flag.sats"
staload "os/fs.sats"
staload "data_font/resources/font.sats"
staload "data_font/atlas/font_glyph_id.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/position/glyph_position_types.sats"
staload "data_font/glyph/position/glyph_position.sats"
staload "data_font/sfnt/sfnt.sats"
staload "core_render/render.sats"
staload "core_render/gl.sats"
staload "font/text/run/font_run_render_contracts.sats"
staload "font/atlas/font_glyph_id_contracts.sats"
staload "font/resources/font_gl_airlock.sats"
fun paint(f: !Font,r: !Rend,face: FontGlyphFace,glyph: int,x: double,y: double,errors: &int >> _): void = let
  val g=id_test_read(f,r,face,glyph,errors)
  val aw=n_i2d(font_atlas_w(f)) and ah=n_i2d(font_atlas_h(f))
in rend_quad_pixels(r,font_tex(f),ShadeAlpha(),x+n_i2d(g.bx),y-n_i2d(g.top),n_i2d(g.bw),n_i2d(g.bh),
  n_i2d(g.x0)/aw,n_i2d(g.y0)/ah,n_i2d(iadd(g.x0,g.bw))/aw,n_i2d(iadd(g.y0,g.bh))/ah,col_white()) end
fun origins(d: GlyphPositionDirection): @(double,double) = case+ d of | PositionLTR() => @(0.0,700.0) | PositionRTL() => @(700.0,0.0)
fun different{n:nat} .<n>. (left: int(n),a: !Buf,b: !Buf,i: int): int =
  if left = 0 then 0 else iadd(if ieq(buf_get(a,i),buf_get(b,i)) then 0 else 1,different(left-1,a,b,iadd(i,1)))
fun ink{n:nat} .<n>. (left: int(n),a: !Buf,i: int): int =
  if left = 0 then 0 else iadd(if ieq(buf_get(a,i),buf_get(a,imod(i,4))) then 0 else 1,ink(left-1,a,iadd(i,1)))
implement run_render_test_compare(a,b) = different(airlock_nat(WORD16_MODULUS),a,b,0)
implement run_render_test_reference(f,r,p,face,d,errors) = let
  val a=glyph_position_query(p,0) and c=glyph_position_query(p,1) val @(x0,x1)=origins(d)
  val ()=rend_begin(r,640,480)
  val ()=paint(f,r,face,a.core.glyph,50.25+(x0+31.0)/64.0,72.5-17.0/64.0,errors)
  val ()=paint(f,r,face,c.core.glyph,50.25+(x1-11.0)/64.0,72.5+9.0/64.0,errors)
  val ()=rend_flush(r) val b=buf_make(WORD16_MODULUS)
  val ()=font_gl_read_pixels(b,128,128)
  val ()=if igt(ink(WORD16_MODULUS,b,0),0) then () else errors := iadd(errors,1)
in b end
