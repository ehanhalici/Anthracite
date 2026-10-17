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
staload "data_font/atlas/private/font_cache_types.sats"
staload "data_font/atlas/private/font_cache.sats"
fun fill{n:nat} .<n>. (left: int(n),f: !Font,i: int): void = if left = 0 then () else let
  var g: gmet= @{ax=i,bx=0,top=0,bw=0,bh=0,x0=0,y0=0,ok=On()}
  val ()=cache_put_key(f,@{kind=CachePrimaryGlyph(),value=iadd(65,imul(i,1024)),ppem=16},g)
in fill(left-1,f,iadd(i,1)) end
fun one(f: !Font,i: int,expected: int): int = let
  var g: gmet= @{ax=0,bx=0,top=0,bw=0,bh=0,x0=0,y0=0,ok=Off()}
  val found=cache_get_key(f,@{kind=CachePrimaryGlyph(),value=iadd(65,imul(i,1024)),ppem=16},g)
in if ieq(found,expected) andalso (ieq(found,0) orelse ieq(g.ax,i)) then 0 else 1 end
fun rows{n:nat} .<n>. (left: int(n),f: !Font,i: int): int =
  if left = 0 then 0 else one(f,i,1)+rows(left-1,f,iadd(i,1))
implement id_test_cache_collision() = let val f=font_open()
  val ()=fill(25,f,0)
  val errors=one(f,0,0)+rows(24,f,1)
  val ()=font_free(f)
in errors end
