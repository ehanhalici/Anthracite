#include "data_font/native/text/native_text_analysis_internal.hats"
staload "font/native/text/native_text_item_cases.sats"
fun copy{n:nat} .<n>. (left: int(n),text: string,b: !Buf,index: int): void = if left = 0 then () else let
  val ()=buf_set(b,index,c_str_byte(text,index)) in copy(left-1,text,b,iadd(index,1)) end
fun bytes(text: string): Buf = let val size=c_strlen(text) val b=buf_make(size)
  val ()=copy(airlock_nat(size),text,b,0) val ()=buf_set_len(b,size)
in b end
fun mandatory(a: !NativeTextAnalysis,index: int): bool = case+ native_text_analysis_break(a,index) of
  | BreakMandatory() => true | BreakOptional() => false | BreakForbidden() => false
fun mixed(assets: !NativeTextAssets): int = let val source=bytes("Türkçe بَب")
  val errors=case+ native_text_analyze(assets,source,buf_len(source),AutoLtr()) of
    | ~NativeAnalysisRejected(e) => 1 | ~NativeAnalysisAccepted(a) => let
      val latin=native_text_analysis_script(a,0) and arabic=native_text_analysis_script(a,7)
      val ok=ieq(native_text_analysis_count(a),10) andalso ieq(latin.code,1281455214) andalso ieq(arabic.code,1098015074)
        andalso ieq(native_text_analysis_level(a,0),0) andalso ieq(native_text_analysis_level(a,7),1)
        andalso not(native_text_analysis_grapheme(a,8)) andalso mandatory(a,10)
      val ()=native_text_analysis_dispose(a) in if ok then 0 else 1 end
  val ()=buf_free(source)
in errors end
fun normalized(assets: !NativeTextAssets): int = let val source=bytes("Ş İ")
  val errors=case+ native_text_analyze(assets,source,buf_len(source),AutoLtr()) of
    | ~NativeAnalysisRejected(e) => 1 | ~NativeAnalysisAccepted(a) => let
      val+ NativeTextAnalysis(text,bidi,scripts,breaks,graphemes,source_length)=a
      val ok=ieq(scalar_count(text),3) andalso ieq(scalar_value(text,0),350)
        andalso ieq(scalar_start(text,0),0) andalso ieq(scalar_end(text,0),3)
        andalso ieq(scalar_value(text,2),304) andalso ieq(scalar_start(text,2),4) andalso ieq(scalar_end(text,2),7)
      val ()=native_text_analysis_dispose(a) in if ok then 0 else 1 end
  val ()=buf_free(source)
in errors end
fun empty(assets: !NativeTextAssets): int = let val source=buf_make(0)
  val errors=case+ native_text_analyze(assets,source,0,AutoLtr()) of | ~NativeAnalysisRejected(e) => 1
    | ~NativeAnalysisAccepted(a) => let val ok=ieq(native_text_analysis_count(a),0) andalso mandatory(a,0)
      val ()=native_text_analysis_dispose(a) in if ok then 0 else 1 end
  val ()=buf_free(source)
in errors end
fun invalid(assets: !NativeTextAssets): int = let val source=buf_make(1)
  val errors=case+ native_text_analyze(assets,source,iadd(buf_cap(source),1),AutoLtr()) of
    | ~NativeAnalysisRejected(e) => 0 | ~NativeAnalysisAccepted(a) => let val ()=native_text_analysis_dispose(a) in 1 end
  val ()=buf_free(source)
in errors end
#include "font/native/text/native_analysis_window_cases.hats"
fun cases(): int = if ine(c_argc(),3) then 1 else
  case+ native_text_assets_load(@{generated=c_argv(1),source=c_argv(2)}) of | ~NativeAssetsRejected(e) => 1
    | ~NativeAssetsAccepted(assets) => let val errors=mixed(assets)+normalized(assets)+empty(assets)+invalid(assets)+native_text_item_cases(assets)+native_analysis_window_cases(assets)
      val ()=native_text_assets_dispose(assets) in errors end
fun ownership(before: int): int = if ieq(before,mem_live()) then 0 else 1
implement main0() = let val before=mem_live() val errors=cases() val owned=ownership(before)
  val ()=println!("event=native_text_analysis errors=",errors," buf_errors=",owned)
in if igt(iadd(errors,owned),0) then exit(1) else () end
