#include "font/native/ownership/font_native_test.hats"
staload "data_font/text/span/font_span.sats"
staload "data_font/text/span/font_span_types.sats"
staload "data_font/text/span/private/font_span_work.sats"
fun bytes(text: string): Buf = let val n=c_strlen(text) val b=buf_make(n)
  fun copy{k:nat} .<k>. (left: int(k),s: string,b: !Buf,index: int): void = if left = 0 then () else let
    val ()=buf_set(b,index,c_str_byte(s,index)) in copy(left-1,s,b,iadd(index,1)) end
  val ()=copy(airlock_nat(n),text,b,0) val ()=buf_set_len(b,n)
in b end
fun ready(status: FontRunStatus): bool = case+ status of
  | FontRunReady() => true | FontRunFace() => false | FontRunScale() => false
  | FontRunOverflow() => false | FontRunRaster() => false | FontRunGraph() => false
fun examined(f: !Font,r: !Rend,layout: FontSpanLayout): int = let
  val first=font_span_part(layout,0) and second=font_span_part(layout,1)
  val ok=ieq(font_span_width(layout),3259) andalso ieq(first.x,0) andalso ieq(second.x,2468)
    andalso ieq(first.sourceStart,0) andalso ieq(first.sourceEnd,8)
    andalso ieq(second.sourceStart,8) andalso ieq(second.sourceEnd,14)
    andalso ieq(font_span_direction(layout),0) andalso ready(font_span_draw(f,r,layout,20.0,40.0,0xFFFFFFFFu))
  val ()=font_span_dispose(layout)
in if ok then 0 else 1 end
fun mixed(f: !Font,r: !Rend,assets: !NativeTextAssets): int = let val source=bytes("Ş İ بَّ")
  val result=font_span_make(f,assets,source,buf_len(source),@{primary=61,fallback=62,scale= @{xPpem=16,yPpem=16}})
  val ()=buf_free(source)
in case+ result of | ~FontSpanRejected(e) => 1 | ~FontSpanAccepted(layout) => examined(f,r,layout) end
fun empty(f: !Font,r: !Rend,assets: !NativeTextAssets): int = let val source=buf_make(0)
  val errors=case+ font_span_make(f,assets,source,0,@{primary=61,fallback=62,scale= @{xPpem=16,yPpem=16}}) of
    | ~FontSpanRejected(e) => 1 | ~FontSpanAccepted(layout) => let
      val ok=ieq(font_span_width(layout),0) andalso ready(font_span_draw(f,r,layout,20.0,40.0,0xFFFFFFFFu))
      val ()=font_span_dispose(layout) in if ok then 0 else 1 end
  val ()=buf_free(source)
in errors end
fun initialized(f: !Font,r: !Rend,assets: !NativeTextAssets): int = let
  val loaded=font_use_file(f,c_argv(3)) and fb=font_use_fallback_file(f,c_argv(4)) val ()=font_set_px(f,16)
in if loaded andalso fb then mixed(f,r,assets)+empty(f,r,assets) else 1 end
implement native_span_cases(r,assets) = let val f=font_open()
  val errors=initialized(f,r,assets)
  val ()=font_free(f) val ()=println!("event=native_span_owner errors=",errors)
in errors end
