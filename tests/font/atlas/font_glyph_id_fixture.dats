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
implement id_test_read(f,r,face,glyph,errors) = let
  var g: gmet= @{ax=0,bx=0,top=0,bw=0,bh=0,x0=0,y0=0,ok=Off()}
  val status=font_glyph_id(f,r,face,glyph,g)
  val ready=case+ status of | GlyphRasterReady() => true | GlyphRasterDomain() => false | GlyphRasterUnavailable() => false
  val ()=if ready andalso is_on(g.ok) then () else errors := errors+1
in g end
implement id_test_geometry(a,b) = ieq(a.ax,b.ax) andalso ieq(a.bx,b.bx) andalso ieq(a.top,b.top)
  andalso ieq(a.bw,b.bw) andalso ieq(a.bh,b.bh)
implement id_test_faces(r,latin,arabic) = let
  val primary=id_test_primary(r,latin)+id_test_primary(r,arabic)
  val fallback=id_test_fallback(r,latin,arabic)
  val domains=id_test_domains(r,latin,arabic)
  val cache=id_test_cache()+id_test_cache_collision()
  val atlas=id_test_atlas(r,latin)
  val ()=println!("event=font_glyph_id_conformance primary_errors=",primary,
    " fallback_errors=",fallback," domain_errors=",domains," cache_errors=",cache," atlas_errors=",atlas)
in primary+fallback+domains+cache+atlas end
