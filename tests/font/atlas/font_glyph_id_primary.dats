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
staload "data_font/sfnt/sfnt.sats"
fun metrics(face: !SfntFace,g: gmet,glyph: int,ppem: int): int = let
  val info=sfnt_info(face) and m=sfnt_glyph_metrics(face,glyph)
  val expected=idiv(iadd(imul(m.advance,ppem),idiv(info.units,2)),info.units)
in if ieq(g.ax,expected) then 0 else 1 end
fun one(f: !Font,r: !Rend,face: !SfntFace,cp: int,ppem: int): int = let var errors: int=0
  val gid=sfnt_glyph(face,cp)
  val a=id_test_read(f,r,GlyphPrimaryFace(),gid,errors)
  val again=id_test_read(f,r,GlyphPrimaryFace(),gid,errors)
  val ()=errors := errors+metrics(face,a,gid,ppem)
  val same=id_test_geometry(a,again) andalso ieq(a.x0,again.x0) andalso ieq(a.y0,again.y0)
  var nominal: gmet= @{ax=0,bx=0,top=0,bw=0,bh=0,x0=0,y0=0,ok=Off()}
  val ()=if igt(gid,0) then font_glyph(f,r,cp,nominal) else ()
  val ok=same andalso (ile(gid,0) orelse id_test_geometry(a,nominal))
in iadd(errors,if ok then 0 else 1) end
fun size(f: !Font,r: !Rend,face: !SfntFace,ppem: int): int = let
  val ()=rend_flush(r) and ()=font_set_px(f,ppem)
in one(f,r,face,65,ppem)+one(f,r,face,305,ppem)+one(f,r,face,350,ppem)+one(f,r,face,287,ppem)
  +one(f,r,face,775,ppem)+one(f,r,face,1576,ppem)+one(f,r,face,1614,ppem)+one(f,r,face,64830,ppem) end
fun opened(r: !Rend,path: string,face: !SfntFace): int = let
  val f=font_open()
  val loaded=font_use_file(f,path)
  val errors=size(f,r,face,16)+size(f,r,face,24)+size(f,r,face,48)
  val ()=rend_flush(r) and ()=font_free(f)
in iadd(errors,if loaded then 0 else 1) end
implement id_test_primary(r,path) = case+ sfnt_open(path) of
  | ~RejectedSfnt(e) => 1 | ~LoadedSfnt(face) => let
    val errors=opened(r,path,face)
    val ()=sfnt_dispose(face)
  in errors end
