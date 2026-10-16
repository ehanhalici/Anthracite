#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "flag.sats"
staload "data_font/resources/font.sats"
staload "data_font/atlas/font_glyph_id.sats"
staload "core_render/render.sats"
staload "font/atlas/font_glyph_id_contracts.sats"
staload "data_font/resources/private/font_storage.sats"
fun unavailable(f: !Font,r: !Rend,face: FontGlyphFace): int = let
  var g: gmet= @{ax=99,bx=99,top=99,bw=99,bh=99,x0=99,y0=99,ok=On()}
  val status=font_glyph_id(f,r,face,0,g)
  val missing=case+ status of | GlyphRasterUnavailable() => true | GlyphRasterReady() => false | GlyphRasterDomain() => false
in if missing andalso is_off(g.ok) andalso ieq(g.ax,0) andalso ieq(g.bw,0) then 0 else 1 end
fun domain(f: !Font,r: !Rend,face: FontGlyphFace,glyph: int): int = let
  var g: gmet= @{ax=99,bx=99,top=99,bw=99,bh=99,x0=99,y0=99,ok=On()}
  val status=font_glyph_id(f,r,face,glyph,g)
  val outside=case+ status of | GlyphRasterDomain() => true | GlyphRasterUnavailable() => false | GlyphRasterReady() => false
in if outside andalso is_off(g.ok) andalso ieq(g.ax,0) andalso ieq(g.bw,0) then 0 else 1 end
fun bounds(f: !Font,r: !Rend,errors: &int >> _): int = let
  val primary=font_get_glyph_count(f) and fallback=font_get_fallback_glyph_count(f)
  val a=id_test_read(f,r,GlyphPrimaryFace(),isub(primary,1),errors)
  val b=id_test_read(f,r,GlyphFallbackFace(),isub(fallback,1),errors)
in domain(f,r,GlyphPrimaryFace(),primary)+domain(f,r,GlyphFallbackFace(),fallback) end
fun loaded(f: !Font,r: !Rend,latin: string,arabic: string): int = let
  val a=font_use_file(f,latin) and b=font_use_fallback_file(f,arabic)
  var errors: int=0
  val before=id_test_read(f,r,GlyphPrimaryFace(),14,errors)
  val outside=domain(f,r,GlyphPrimaryFace(),~1)+domain(f,r,GlyphPrimaryFace(),WORD16_MAX_VALUE)+bounds(f,r,errors)
    +domain(f,r,GlyphFallbackFace(),~1)+domain(f,r,GlyphFallbackFace(),WORD16_MAX_VALUE)
  val after=id_test_read(f,r,GlyphPrimaryFace(),14,errors)
in iadd(errors+outside,if a andalso b andalso id_test_geometry(before,after) then 0 else 1) end
implement id_test_domains(r,latin,arabic) = let
  val f=font_open()
  val empty=unavailable(f,r,GlyphPrimaryFace())+unavailable(f,r,GlyphFallbackFace())
  val errors=loaded(f,r,latin,arabic)
  val ()=rend_flush(r) and ()=font_free(f)
in empty+errors end
