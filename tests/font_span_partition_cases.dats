#include "font_native_test.hats"
staload "data_font/font_span.sats"
staload "data_font/font_span_types.sats"
staload "data_font/private/font_span_work.sats"
staload "data_font/private/font_native_owner.sats"
fun bytes(s: string): Buf = let val n=c_strlen(s) val b=buf_make(n)
  fun copy{k:nat} .<k>. (left: int(k),s: string,b: !Buf,i: int): void = if left = 0 then () else let
    val ()=buf_set(b,i,c_str_byte(s,i)) in copy(left-1,s,b,iadd(i,1)) end
  val ()=copy(airlock_nat(n),s,b,0) val ()=buf_set_len(b,n)
in b end
fun ready(s: FontRunStatus): bool = case+ s of
  | FontRunReady() => true | FontRunFace() => false | FontRunScale() => false
  | FontRunOverflow() => false | FontRunRaster() => false | FontRunGraph() => false
fun alternating(f: !Font,r: !Rend,layout: !FontSpanLayout): bool = let
  val first=font_span_part(layout,0) and middle=font_span_part(layout,1) and last=font_span_part(layout,2)
  val primary=font_native_current(f,GlyphPrimaryFace()) and fallback=font_native_current(f,GlyphFallbackFace())
in ieq(first.sourceStart,0) andalso ieq(first.sourceEnd,1) andalso ieq(middle.sourceStart,1)
  andalso ieq(middle.sourceEnd,2) andalso ieq(last.sourceStart,2) andalso ieq(last.sourceEnd,3)
  andalso ieq(primary.font,91) andalso ieq(fallback.font,92) andalso ieq(font_span_width(layout),617)
  andalso ready(font_span_draw(f,r,layout,20.0,220.0,0xFFFFFFFFu)) end
fun cluster(f: !Font,r: !Rend,layout: !FontSpanLayout): bool = let
  val first=font_span_part(layout,0) and last=font_span_part(layout,1)
in ieq(first.start,0) andalso ieq(first.finish,2) andalso ieq(first.sourceStart,0) andalso ieq(first.sourceEnd,3)
  andalso ieq(last.start,2) andalso ieq(last.sourceStart,3) andalso ieq(last.sourceEnd,4)
  andalso ready(font_span_draw(f,r,layout,20.0,250.0,0xFFFFFFFFu)) end
fun examined(f: !Font,r: !Rend,layout: FontSpanLayout,count: int): int = let
  val+ FontSpanLayout(a,items,runs,rows,order,n,width,direction)=layout
  val ok=if ine(n,count) then false else if ieq(count,3) then alternating(f,r,layout) else cluster(f,r,layout)
  val ()=font_span_dispose(layout)
in if ok then 0 else 1 end
fun shaped(f: !Font,r: !Rend,assets: !NativeTextAssets,s: string,count: int): int = let val b=bytes(s)
  val result=font_span_make(f,assets,b,buf_len(b),@{primary=91,fallback=92,scale= @{xPpem=16,yPpem=16}})
  val ()=buf_free(b)
in case+ result of | ~FontSpanRejected(error) => 1 | ~FontSpanAccepted(layout) => examined(f,r,layout,count) end
fun loaded(f: !Font,r: !Rend,assets: !NativeTextAssets): int = let
  val primary=font_use_file(f,c_argv(1)) and fallback=font_use_fallback_file(f,c_argv(3)) val ()=font_set_px(f,16)
in if primary andalso fallback then shaped(f,r,assets,"ABA",3)+shaped(f,r,assets,"A̸A",2) else 1 end
implement native_span_partition_cases(r,assets) = let val f=font_open() val errors=loaded(f,r,assets)
  val ()=font_free(f) val ()=println!("event=native_span_partition errors=",errors)
in errors end
