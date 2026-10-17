#include "data_font/text/font_text_internal.hats"
fun bytes{n:nat} .<n>. (left: int(n),a: !Buf,b: !Buf,i: int): bool =
  if left = 0 then true else ieq(buf_get(a,i),buf_get(b,i)) andalso bytes(left-1,a,b,iadd(i,1))
fun ready(s: FontRunStatus): bool = case+ s of
  | FontRunReady() => true | FontRunFace() => false | FontRunScale() => false
  | FontRunOverflow() => false | FontRunRaster() => false | FontRunGraph() => false
implement font_text_cache_matches(cache,f,b,length,px) = let val+ FontTextCache(key,layout,size,tail)=cache
in ieq(size,px) andalso ieq(buf_len(key),length) andalso bytes(airlock_nat(length),key,b,0)
  andalso ready(font_span_check(f,layout)) end
