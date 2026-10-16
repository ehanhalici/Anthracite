#include "font/native/ownership/font_native_test.hats"
staload "data_font/text/span/font_span.sats"
staload "data_font/text/span/font_span_types.sats"
staload "data_font/text/span/private/font_span_work.sats"
fun bytes(s: string): Buf = let val n=c_strlen(s) val b=buf_make(n)
  fun copy{k:nat} .<k>. (left: int(k),s: string,b: !Buf,i: int): void = if left = 0 then () else let
    val ()=buf_set(b,i,c_str_byte(s,i)) in copy(left-1,s,b,iadd(i,1)) end
  val ()=copy(airlock_nat(n),s,b,0) val ()=buf_set_len(b,n)
in b end
fun options(): FontSpanOptions = @{primary=71,fallback=72,scale= @{xPpem=16,yPpem=16}}
fun ready(s: FontRunStatus): bool = case+ s of
  | FontRunReady() => true | FontRunFace() => false | FontRunScale() => false
  | FontRunOverflow() => false | FontRunRaster() => false | FontRunGraph() => false
fun face_error(s: FontRunStatus): bool = case+ s of
  | FontRunFace() => true | FontRunReady() => false | FontRunScale() => false
  | FontRunOverflow() => false | FontRunRaster() => false | FontRunGraph() => false
fun rejected_paragraph(f: !Font,assets: !NativeTextAssets,s: string): int = let val b=bytes(s)
  val errors=case+ font_span_make(f,assets,b,buf_len(b),options()) of
    | ~FontSpanRejected(e) => 0 | ~FontSpanAccepted(layout) => let val ()=font_span_dispose(layout) in 1 end
  val ()=buf_free(b)
in errors end
fun funexamined(f: !Font,r: !Rend,layout: FontSpanLayout): int = let
  val row=font_span_part(layout,0)
  val ok=igt(font_span_width(layout),0) andalso ieq(row.sourceStart,0) andalso ieq(row.sourceEnd,4)
    andalso ready(font_span_draw(f,r,layout,30.0,70.0,0xFFFFFFFFu))
  val ()=font_span_dispose(layout)
in if ok then 0 else 1 end
fun notdef_presentation(f: !Font,r: !Rend,assets: !NativeTextAssets,s: string): int = let val b=bytes(s)
  val errors=case+ font_span_make(f,assets,b,buf_len(b),options()) of
    | ~FontSpanRejected(e) => 1 | ~FontSpanAccepted(layout) => funexamined(f,r,layout)
  val ()=buf_free(b)
in errors end
fun examined(f: !Font,r: !Rend,layout: FontSpanLayout): int = let
  val row=font_span_part(layout,0)
  val ok=ieq(font_span_width(layout),791) andalso ieq(font_span_direction(layout),1)
    andalso ieq(row.sourceStart,0) andalso ieq(row.sourceEnd,6) andalso ieq(row.x,0)
    andalso ready(font_span_draw(f,r,layout,30.0,70.0,0xFFFFFFFFu))
  val ()=println!("event=native_span_arabic width=",font_span_width(layout)," direction=",font_span_direction(layout),
    " source_start=",row.sourceStart," source_end=",row.sourceEnd," ok=",ok)
  val ()=font_span_dispose(layout)
in if ok then 0 else 1 end
fun arabic(f: !Font,r: !Rend,assets: !NativeTextAssets): int = let val b=bytes("بَّ")
  val errors=case+ font_span_make(f,assets,b,buf_len(b),options()) of
    | ~FontSpanRejected(e) => 1 | ~FontSpanAccepted(layout) => examined(f,r,layout)
  val ()=buf_free(b)
in errors end
fun arabic_primary(r: !Rend,assets: !NativeTextAssets): int = let val f=font_open()
  (* Occupy the fallback slot with a checked fixture lacking Arabic. This
     prevents font_use_file's system-font discovery from changing the test. *)
  val fallback=font_use_fallback_file(f,c_argv(1))
  val primary=font_use_file(f,c_argv(4)) val ()=font_set_px(f,16)
  val errors=if primary andalso fallback then arabic(f,r,assets) else 1 val ()=font_free(f)
in errors end
fun long_examined(layout: FontSpanLayout): int = let val row=font_span_part(layout,0)
  val ok=ieq(font_span_width(layout),1579520) andalso ieq(row.finish,2560) andalso ieq(row.sourceEnd,2560)
  val ()=font_span_dispose(layout)
in if ok then 0 else 1 end
fun long_span(f: !Font,assets: !NativeTextAssets): int = let val b=buf_make(2560)
  fun fill{n:nat} .<n>. (left: int(n),b: !Buf,i: int): void = if left = 0 then () else let
    val ()=buf_set(b,i,65) in fill(left-1,b,iadd(i,1)) end
  val ()=fill(2560,b,0) val ()=buf_set_len(b,2560)
  val errors=case+ font_span_make(f,assets,b,2560,options()) of
    | ~FontSpanRejected(e) => 1 | ~FontSpanAccepted(layout) => long_examined(layout)
  val ()=buf_free(b)
in errors end
fun stale_examined(f: !Font,r: !Rend,layout: FontSpanLayout): int = let
  (* Only the second face changes: preflight must reject the entire snapshot. *)
  val loaded=font_use_fallback_file(f,c_argv(4))
  val ok=loaded andalso face_error(font_span_check(f,layout))
    andalso face_error(font_span_draw(f,r,layout,30.0,100.0,0xFFFFFFFFu))
  val ()=font_span_dispose(layout)
in if ok then 0 else 1 end
fun stale(f: !Font,r: !Rend,assets: !NativeTextAssets): int = let val b=bytes("Ş İ بَّ")
  val errors=case+ font_span_make(f,assets,b,buf_len(b),options()) of
    | ~FontSpanRejected(e) => 1 | ~FontSpanAccepted(layout) => stale_examined(f,r,layout)
  val ()=buf_free(b)
in errors end
fun loaded(f: !Font,r: !Rend,assets: !NativeTextAssets): int = let
  val primary=font_use_file(f,c_argv(3)) and fallback=font_use_fallback_file(f,c_argv(4))
  val ()=font_set_px(f,16)
in if primary andalso fallback then let
  val long_errors=long_span(f,assets) and paragraph_errors=rejected_paragraph(f,assets,"a\nb")
  val coverage_errors=notdef_presentation(f,r,assets,"􏿿") and stale_errors=stale(f,r,assets)
  val ()=println!("event=native_span_checks long=",long_errors," paragraph=",paragraph_errors,
    " coverage=",coverage_errors," stale=",stale_errors)
in long_errors+paragraph_errors+coverage_errors+stale_errors end else 1 end
implement native_span_boundary_cases(r,assets) = let val f=font_open()
  val errors=iadd(loaded(f,r,assets),arabic_primary(r,assets)) val ()=font_free(f)
  val ()=println!("event=native_span_boundaries errors=",errors)
in errors end
