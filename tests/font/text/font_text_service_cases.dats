#include "font/native/ownership/font_native_test.hats"
staload "data_font/text/font_text.sats"
staload "data_font/text/font_text_types.sats"
staload "data_font/text/private/font_text_owner.sats"
staload "data_font/text/span/font_span_types.sats"
staload "data_font/resources/private/font_storage.sats"
staload "font/text/font_text_abi_airlock.sats"
staload "core_runtime/text_engine_startup.sats"
extern fun native_source_edit_cases(f: !Font): int = "ext#native_source_edit_cases"
extern fun native_event_repaint_cases(): int = "ext#native_event_repaint_cases"
extern fun native_text_metrics_cases(f: !Font): int = "ext#native_text_metrics_cases"
extern fun native_visual_layout_cases(f: !Font,r: !Rend): int = "ext#native_visual_layout_cases"
fun bytes(s: string): Buf = let val n=c_strlen(s) val b=buf_make(n)
  fun copy{k:nat} .<k>. (left: int(k),s: string,b: !Buf,i: int): void = if left = 0 then () else let
    val ()=buf_set(b,i,c_str_byte(s,i)) in copy(left-1,s,b,iadd(i,1)) end
  val ()=copy(airlock_nat(n),s,b,0) val ()=buf_set_len(b,n)
in b end
fun value(result: FontTextResult,expected: int): int = case+ result of
  | FontTextValue(actual) => if ieq(actual,expected) then 0 else 1
  | FontTextInactive() => 1 | FontTextFailed(error) => 1
fun enabled(result: FontTextEnable): bool = case+ result of
  | FontTextEnabled() => true | FontTextAlreadyEnabled() => false | FontTextAssetsFailed(e) => false
fun repeated(result: FontTextEnable): int = case+ result of
  | FontTextAlreadyEnabled() => 0 | FontTextEnabled() => 1 | FontTextAssetsFailed(e) => 1
fun missing(result: FontTextEnable): int = case+ result of
  | FontTextAssetsFailed(e) => 0 | FontTextEnabled() => 1 | FontTextAlreadyEnabled() => 1
fun key{b:bool}(state: !option_vt(FontTextSession,b)): int = case+ state of
  | None_vt() => ~1 | Some_vt(session) => let val+ FontTextSession(assets,cache,primary,fallback,metrics)=session
    in case+ cache of | None_vt() => ~1 | Some_vt(c) => let val+ FontTextCache(source,layout,px,tail)=c
      in buf_get(source,0) end end
fun cached_byte(f: !Font): int = let val state=font_text_take(f) val first=key(state)
  val ()=font_text_put(f,state)
in first end
fun shared(f: !Font,r: !Rend): int = let val b=bytes("Ş İ بَّ")
  val measured=value(font_text_width(f,b,buf_len(b)),51) val before=mem_live()
  val drawn=value(font_text_draw(f,r,b,buf_len(b),20,140,0xFFFFFFFFu),51)
  val width=font_width_buf(f,r,b,buf_len(b)) val rendered=font_draw_buf(f,r,20,160,b,buf_len(b),0xFFFFFFFFu)
  val unchanged=ieq(before,mem_live()) andalso ieq(width,51) andalso ieq(rendered,51)
    andalso ieq(native_text_wrapped_width(f,r,b,buf_len(b)),51)
    andalso ieq(native_text_wrapped_draw(f,r,b,buf_len(b)),51)
    andalso ieq(native_text_raw_width(f,r,b,buf_len(b)),51)
  val ()=buf_free(b)
in iadd(iadd(measured,drawn),if unchanged then 0 else 1) end
fun changed(f: !Font): int = let val b=bytes("AA")
  val first=value(font_text_width(f,b,2),20) val ()=buf_set(b,0,66)
  val second=value(font_text_width(f,b,2),20) val fresh=ieq(cached_byte(f),66)
  val ()=buf_free(b)
in iadd(iadd(first,second),if fresh then 0 else 1) end
fun scaled(f: !Font,r: !Rend): int = let val b=bytes("Ş İ بَّ")
  val drawn=font_draw_scaled_buf(f,r,20,180,b,buf_len(b),0xFFFFFFFFu,3,2)
  val restored=ieq(font_get_px(f),16) val width=font_width_buf(f,r,b,buf_len(b)) val ()=buf_free(b)
in if igt(drawn,51) andalso restored andalso ieq(width,51) then 0 else 1 end
fun tabbed(f: !Font,r: !Rend,s: string,width: int): int = let val b=bytes(s)
  val measured=value(font_text_width(f,b,buf_len(b)),width)
  val rendered=value(font_text_draw(f,r,b,buf_len(b),20,350,0xFFFFFFFFu),width)
  val ()=buf_free(b)
in iadd(measured,rendered) end
fun tabs(f: !Font,r: !Rend): int =
  tabbed(f,r,"A\tB",49)+tabbed(f,r,"\t\t",78)+tabbed(f,r,"AAAA\tB",87)
  +tabbed(f,r,"A\r\n",10)+tabbed(f,r,"\r\n",0)
fun base_direction(f: !Font,s: string,expected: int): int = let val b=bytes(s)
  val errors=value(font_text_direction_code(f,b,buf_len(b)),expected) val ()=buf_free(b)
in errors end
fun directions(f: !Font): int = base_direction(f,"Türkçe بَّ",0)+base_direction(f,"بَّ Türkçe",1)
  +base_direction(f,"123",0)
fun failed(f: !Font): int = let val error=font_text_enable(f,@{generated="/missing-native-data",source=c_argv(6)})
in iadd(missing(error),if font_text_active(f) then 1 else 0) end
fun loaded(f: !Font,r: !Rend): int = let
  val primary=font_use_file(f,c_argv(3)) and fallback=font_use_fallback_file(f,c_argv(4)) val ()=font_set_px(f,16)
  val location: NativeAssetLocation= @{generated=c_argv(5),source=c_argv(6)}
  val errors=failed(f) val ready=font_text_enable(f,location)
in if primary andalso fallback andalso enabled(ready) then errors+shared(f,r)+changed(f)+scaled(f,r)
  +repeated(font_text_enable(f,location))+native_text_note_cases(f,r)+tabs(f,r)+directions(f)
  +native_text_cache_cases(f)+native_event_repaint_cases()+native_text_metrics_cases(f)+native_visual_layout_cases(f,r)
  +native_source_edit_cases(f) else errors+1 end
implement native_text_service_cases(r) = let val before=mem_live() val f=font_open()
  val errors=loaded(f,r) val ()=font_free(f) val balanced=ieq(mem_live(),before)
  val result=iadd(errors,if balanced then 0 else 1)
  val ()=println!("event=native_text_service errors=",result," balanced=",balanced)
in result end

implement native_workspace_startup_case(r) = let val before=mem_live() val f=font_open()
  val started=workspace_font_start(f) val b=bytes("Native")
  val width=font_width_buf(f,r,b,buf_len(b))
  val drawn=font_draw_buf(f,r,20,330,b,buf_len(b),0xFFFFFFFFu)
  val active=started andalso font_text_active(f) andalso igt(width,0) andalso ieq(drawn,width)
  val ()=buf_free(b) val ()=font_free(f)
  val errors=if active andalso ieq(before,mem_live()) then 0 else 1
  val ()=println!("event=native_workspace_startup errors=",iadd(errors,0))
in errors end
