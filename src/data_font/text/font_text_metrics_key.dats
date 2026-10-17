#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/text/font_text_metrics.sats"
staload "data_font/native/ownership/private/font_native_owner.sats"
staload "data_font/atlas/font_glyph_id.sats"
fun hash{n:nat} .<n>. (left: int(n),b: !Buf,i: int,h: int): int =
  if left = 0 then h else hash(left-1,b,iadd(i,1),imod(iadd(imul(h,31),buf_get(b,i)),8192))
implement font_text_metric_key(f,b,n,px) = let
  val p=font_native_current(f,GlyphPrimaryFace()) val a=font_native_current(f,GlyphFallbackFace())
in @{length=n,px=px,primary=p.font,fallback=a.font,primaryGeneration=p.generation,
  fallbackGeneration=a.generation,bucket=hash(airlock_nat(n),b,0,0)} end
fun bytes{n:nat} .<n>. (left: int(n),arena: !Buf,b: !Buf,offset: int,i: int): bool =
  if left = 0 then true else ieq(buf_get(arena,iadd(offset,i)),buf_get(b,i))
    andalso bytes(left-1,arena,b,offset,iadd(i,1))
implement font_text_metric_matches(t,arena,b,k) = let val o=imul(k.bucket,9)
in ieq(buf_get32(t,o),1) andalso ieq(buf_get32(t,iadd(o,2)),k.length)
  andalso ieq(buf_get32(t,iadd(o,3)),k.px) andalso ieq(buf_get32(t,iadd(o,4)),k.primaryGeneration)
  andalso ieq(buf_get32(t,iadd(o,5)),k.fallbackGeneration) andalso ieq(buf_get32(t,iadd(o,6)),k.primary)
  andalso ieq(buf_get32(t,iadd(o,7)),k.fallback)
  andalso bytes(airlock_nat(k.length),arena,b,buf_get32(t,iadd(o,1)),0) end
