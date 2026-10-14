#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "flag.sats"
staload "data_font/font.sats"
staload "data_font/font_glyph_id.sats"
staload "core_render/render.sats"
staload "font_glyph_id_contracts.sats"
fun one(f: !Font,separate: !Font,r: !Rend,glyph: int): int = let var errors: int=0
  val primary=id_test_read(f,r,GlyphPrimaryFace(),glyph,errors)
  val fallback=id_test_read(f,r,GlyphFallbackFace(),glyph,errors)
  val reference=id_test_read(separate,r,GlyphPrimaryFace(),glyph,errors)
  val primary_after=id_test_read(f,r,GlyphPrimaryFace(),glyph,errors)
  val ok=id_test_geometry(primary,primary_after) andalso ieq(primary.x0,primary_after.x0)
    andalso ieq(primary.y0,primary_after.y0) andalso id_test_geometry(fallback,reference)
in iadd(errors,if ok then 0 else 1) end
implement id_test_fallback(r,latin,arabic) = let
  val f=font_open() and separate=font_open()
  val a=font_use_file(f,latin) and b=font_use_file(separate,arabic)
  val fallback=font_use_fallback_file(f,arabic)
  val first=one(f,separate,r,0)+one(f,separate,r,1)+one(f,separate,r,14)+one(f,separate,r,321)+one(f,separate,r,614)
  val ()=rend_flush(r) and ()=font_set_px(f,32) and ()=font_set_px(separate,32)
  val second=one(f,separate,r,0)+one(f,separate,r,1)+one(f,separate,r,14)+one(f,separate,r,321)+one(f,separate,r,614)
  val ()=rend_flush(r) and ()=font_free(f) and ()=font_free(separate)
in iadd(first+second,if a andalso b andalso fallback then 0 else 1) end
