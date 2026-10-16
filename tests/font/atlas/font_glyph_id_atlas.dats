#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "os/fs.sats"
staload "airlock.sats"
staload "flag.sats"
staload "data_font/resources/font.sats"
staload "data_font/atlas/font_glyph_id.sats"
staload "core_render/render.sats"
staload "font/atlas/font_glyph_id_contracts.sats"
staload "core_render/gl.sats"
staload "data_font/resources/private/font_storage.sats"
staload "font/resources/font_gl_airlock.sats"
fun draw(f: !Font,r: !Rend,g: gmet): void = let
  val w=n_i2d(font_atlas_w(f)) and h=n_i2d(font_atlas_h(f))
in rend_quad(r,font_tex(f),ShadeAlpha(),20,20,g.bw,g.bh,n_i2d(g.x0)/w,n_i2d(g.y0)/h,
  n_i2d(iadd(g.x0,g.bw))/w,n_i2d(iadd(g.y0,g.bh))/h,col_white()) end
fun changed{n:nat} .<n>. (left: int(n),b: !Buf,bg: !Buf,i: int): int = if left = 0 then 0 else let
  val at=imul(i,4)
  val different=ine(buf_get(b,at),buf_get(bg,0)) orelse ine(buf_get(b,at+1),buf_get(bg,1))
    orelse ine(buf_get(b,at+2),buf_get(bg,2)) orelse ine(buf_get(b,at+3),buf_get(bg,3))
in iadd(if different then 1 else 0,changed(left-1,b,bg,iadd(i,1))) end
fun reference(f: !Font,r: !Rend,g: gmet,errors: &int >> _): Buf = let
  val b=buf_make(imul(imul(g.bw,g.bh),4))
  val background=buf_make(4)
  val ()=rend_begin(r,640,480) and ()=font_gl_read_pixels(background,1,1)
  val ()=draw(f,r,g) and ()=rend_flush(r)
  val ()=font_gl_read_pixels(b,g.bw,g.bh)
  val ink=changed(airlock_nat(imul(g.bw,g.bh)),b,background,0)
  val ()=if igt(ink,0) then () else errors := errors+1
  val ()=buf_free(background)
in b end
fun overflow(f: !Font,r: !Rend,g: gmet,errors: &int >> _): Buf = let
  val b=buf_make(imul(imul(g.bw,g.bh),4))
  val ()=rend_begin(r,640,480) and ()=draw(f,r,g)
  val ()=font_set_pen_x(f,font_atlas_w(f)-1) and ()=font_set_pen_y(f,font_atlas_h(f)-1) and ()=font_set_row_h(f,1)
  val next=id_test_read(f,r,GlyphPrimaryFace(),cmap_gid(f,66),errors)
  val ()=if igt(next.bw,0) andalso igt(next.bh,0) then () else errors := errors+1
  val ()=font_gl_read_pixels(b,g.bw,g.bh)
in b end
fun compare{n:nat} .<n>. (left: int(n),a: !Buf,b: !Buf,i: int): int = if left = 0 then 0 else
  iadd(if ieq(buf_get(a,i),buf_get(b,i)) then 0 else 1,compare(left-1,a,b,iadd(i,1)))
implement id_test_atlas(r,path) = let
  val f=font_open() val loaded=font_use_file(f,path)
  var errors: int=0
  val g=id_test_read(f,r,GlyphPrimaryFace(),cmap_gid(f,65),errors)
  val expected=reference(f,r,g,errors) and actual=overflow(f,r,g,errors)
  val ()=errors := errors+compare(airlock_nat(buf_cap(expected)),expected,actual,0)
  val ()=if loaded andalso igt(g.bw,0) andalso igt(g.bh,0) then () else errors := errors+1
  val ()=buf_free(expected) and ()=buf_free(actual)
  val ()=rend_flush(r) and ()=font_free(f)
in errors end
