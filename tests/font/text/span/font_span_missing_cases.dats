#include "font/native/ownership/font_native_test.hats"
staload "data_font/text/span/font_span.sats"
staload "data_font/text/span/font_span_types.sats"
staload "data_font/text/span/private/font_span_work.sats"
fun bytes(s: string): Buf = let val n=c_strlen(s) val b=buf_make(n)
  fun copy{k:nat} .<k>. (left: int(k),s: string,b: !Buf,i: int): void = if left = 0 then () else let
    val ()=buf_set(b,i,c_str_byte(s,i)) in copy(left-1,s,b,iadd(i,1)) end
  val ()=copy(airlock_nat(n),s,b,0) val ()=buf_set_len(b,n)
in b end
fun options(): FontSpanOptions = @{primary=93,fallback=94,scale= @{xPpem=16,yPpem=16}}
fun ready(s: FontRunStatus): bool = case+ s of
  | FontRunReady() => true | FontRunFace() => false | FontRunScale() => false
  | FontRunOverflow() => false | FontRunRaster() => false | FontRunGraph() => false
fun spans(f: !Font,assets: !NativeTextAssets,s: string): FontSpanRead = let
  val b=bytes(s) val result=font_span_make(f,assets,b,buf_len(b),options())
  val ()=buf_free(b)
in result end
fun drawn(f: !Font,r: !Rend,layout: !FontSpanLayout): bool =
  ready(font_span_draw(f,r,layout,30.0,70.0,0xFFFFFFFFu))
fun notdef(f: !Font,r: !Rend,assets: !NativeTextAssets): int = let
  val errors=case+ spans(f,assets,"😀") of
    | ~FontSpanRejected(e) => 1 | ~FontSpanAccepted(layout) => let
      val row=font_span_part(layout,0)
      val ok=igt(font_span_width(layout),0) andalso ieq(row.sourceStart,0) andalso ieq(row.sourceEnd,4)
        andalso drawn(f,r,layout)
      val ()=font_span_dispose(layout)
    in if ok then 0 else 1 end
in errors end
fun hebrew(f: !Font,r: !Rend,assets: !NativeTextAssets): int = let
  val errors=case+ spans(f,assets,"שלום") of
    | ~FontSpanRejected(e) => 1 | ~FontSpanAccepted(layout) => let
      val width=font_span_width(layout)
      val ok=igt(width,0) andalso drawn(f,r,layout)
      val ()=println!("event=native_span_missing_hebrew width=",width," ok=",ok)
      val ()=font_span_dispose(layout)
    in if ok then 0 else 1 end
in errors end
fun surrounded(f: !Font,r: !Rend,assets: !NativeTextAssets): int = let
  val errors=case+ spans(f,assets,"İשלום") of
    | ~FontSpanRejected(e) => 1 | ~FontSpanAccepted(layout) => let
      val width=font_span_width(layout)
      val ok=igt(width,0) andalso drawn(f,r,layout)
      val ()=println!("event=native_span_missing_surrounded width=",width," ok=",ok)
      val ()=font_span_dispose(layout)
    in if ok then 0 else 1 end
in errors end
fun still_accepted(f: !Font,r: !Rend,assets: !NativeTextAssets,s: string): int = let
  val b=bytes(s) val errors=case+ font_span_make(f,assets,b,buf_len(b),options()) of
    | ~FontSpanRejected(e) => 1 | ~FontSpanAccepted(layout) => let
      val direction=font_span_direction(layout)
      val ok=ready(font_span_check(f,layout))
      val ()=println!("event=native_span_missing_accepted direction=",direction," ok=",ok)
      val ()=font_span_dispose(layout) in if ok then 0 else 1 end
  val ()=buf_free(b)
in errors end
fun loaded(f: !Font,r: !Rend,assets: !NativeTextAssets): int = let
  val a=notdef(f,r,assets) val b=hebrew(f,r,assets) val c=surrounded(f,r,assets)
  val d=still_accepted(f,r,assets,"İשלום") val e=still_accepted(f,r,assets,"سلام 😀")
  val ()=println!("event=native_span_missing notdef=",a," hebrew=",b," surrounded=",c," left=",d," right=",e)
in a+b+c+d+e end
implement native_span_missing_cases(r,assets) = let val f=font_open()
  val primary=font_use_file(f,c_argv(3)) and fallback=font_use_fallback_file(f,c_argv(4))
  val ()=font_set_px(f,16)
  val errors=if primary andalso fallback then loaded(f,r,assets) else 1
  val ()=font_free(f)
in errors end
