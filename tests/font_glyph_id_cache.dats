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
staload "data_font/private/font_cache_types.sats"
staload "data_font/private/font_cache.sats"
fun write(f: !Font,kind: FontCacheKind,ppem: int,advance: int): void = let
  var g: gmet= @{ax=advance,bx=0,top=0,bw=0,bh=0,x0=0,y0=0,ok=On()}
in cache_put_key(f,@{kind=kind,value=65,ppem=ppem},g) end
fun expect(f: !Font,kind: FontCacheKind,ppem: int,advance: int): int = let
  var g: gmet= @{ax=0,bx=0,top=0,bw=0,bh=0,x0=0,y0=0,ok=Off()}
  val found=cache_get_key(f,@{kind=kind,value=65,ppem=ppem},g)
in if ieq(found,1) andalso ieq(g.ax,advance) then 0 else 1 end
fun missing(f: !Font,kind: FontCacheKind,ppem: int): int = let
  var g: gmet= @{ax=0,bx=0,top=0,bw=0,bh=0,x0=0,y0=0,ok=Off()}
  val found=cache_get_key(f,@{kind=kind,value=65,ppem=ppem},g)
in if ieq(found,0) then 0 else 1 end
implement id_test_cache() = let val f=font_open()
  val ()=write(f,CacheCodepoint(),16,11) and ()=write(f,CachePrimaryGlyph(),16,22)
  val ()=write(f,CacheFallbackGlyph(),16,33) and ()=write(f,CachePrimaryGlyph(),24,44)
  val first=expect(f,CacheCodepoint(),16,11)+expect(f,CachePrimaryGlyph(),16,22)
    +expect(f,CacheFallbackGlyph(),16,33)+expect(f,CachePrimaryGlyph(),24,44)+missing(f,CacheCodepoint(),48)
  val ()=write(f,CachePrimaryGlyph(),16,55)
  val second=expect(f,CacheCodepoint(),16,11)+expect(f,CachePrimaryGlyph(),16,55)
    +expect(f,CacheFallbackGlyph(),16,33)+expect(f,CachePrimaryGlyph(),24,44)
  val ()=clear_cache(f,0)
  val cleared=missing(f,CacheCodepoint(),16)+missing(f,CachePrimaryGlyph(),16)
    +missing(f,CacheFallbackGlyph(),16)+missing(f,CachePrimaryGlyph(),24)
  val ()=font_free(f)
in first+second+cleared end
