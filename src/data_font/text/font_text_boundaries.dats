#include "data_font/text/font_text_internal.hats"
staload "data_font/native/text/native_text_analysis.sats"
staload "data_font/native/text/native_text_analysis_types.sats"
staload "data_text/utf8/utf8.sats"
staload "data_text/line_break/line_types.sats"
staload "data_text/bidi/bidi_types.sats"
extern fun failed(): Buf = "mac#anth_die_box"
fun break_code(b: LineBreak): int = case+ b of
  | BreakForbidden() => 1 | BreakOptional() => 3 | BreakMandatory() => 5
fun fill{n:nat} .<n>. (left: int(n),a: !NativeTextAnalysis,flags: !Buf,i: int): void =
  if left = 0 then () else let val+ NativeTextAnalysis(text,bidi,scripts,breaks,graphemes)=a
    val ()=if native_text_analysis_grapheme(a,i) then
      buf_set(flags,scalar_start(text,i),break_code(native_text_analysis_break(a,i))) else ()
  in fill(left-1,a,flags,iadd(i,1)) end
fun analyzed(assets: !NativeTextAssets,b: !Buf,n: int): Buf = case+ native_text_analyze(assets,b,n,AutoLtr()) of
  | ~NativeAnalysisRejected(e) => let val ()=println!("event=visual_boundaries status=rejected") in failed() end
  | ~NativeAnalysisAccepted(a) => let val flags=buf_make(iadd(n,1)) val ()=buf_zero(flags)
    val ()=fill(airlock_nat(native_text_analysis_count(a)),a,flags,0)
    val ()=buf_set(flags,n,5) val ()=native_text_analysis_dispose(a)
  in flags end
fun active{b:bool}(state: !option_vt(FontTextSession,b),source: !Buf,n: int): Buf = case+ state of
  | None_vt() => failed() | Some_vt(session) => let val+ FontTextSession(assets,cache,p,f,m)=session
  in analyzed(assets,source,n) end
implement font_text_boundaries(f,b,n) = let val state=font_text_take(f)
  val flags=active(state,b,n) val ()=font_text_put(f,state)
in flags end

extern fun metrics_abort(): void = "mac#anth_die_void"
fun metrics_failed(): @(Buf,Buf) = let val ()=metrics_abort() in @(buf_make(0),buf_make(0)) end
fun cached_metrics{b:bool}(state: !option_vt(FontTextCache,b),length: int): @(Buf,Buf) = case+ state of
  | None_vt() => metrics_failed()
  | Some_vt(cache) => let val+ FontTextCache(key,layout,px,tail)=cache
    in font_span_wrap_metrics(layout,length) end
fun mandatory{n:nat} .<n>. (left: int(n),flags: !Buf,i: int): int =
  if left = 0 then i else if ieq(buf_get(flags,i),5) then i else mandatory(left-1,flags,iadd(i,1))
fun merge_metrics{n:nat} .<n>. (left: int(n),flags: !Buf,advances: !Buf,local_flags: !Buf,
  local_advances: !Buf,base: int,total: int,i: int): void =
  if left = 0 then () else let
    val ()=buf_set(flags,iadd(base,i),buf_get(local_flags,i))
    val sum=g0int2int_int_llint(total)+g0int2int_int_llint(buf_get32(local_advances,i))
    val ()=buf_set32(advances,iadd(base,i),airlock_i32(sum))
  in merge_metrics(left-1,flags,advances,local_flags,local_advances,base,total,iadd(i,1)) end
fun segment_metrics(f: !Font,assets: !NativeTextAssets,cache: &Option_vt(FontTextCache) >> _,
  source: !Buf,start: int,finish: int,options: FontSpanOptions): @(Buf,Buf) = let
  var segment=buf_make(isub(finish,start)) val ()=buf_append_at(segment,source,start,isub(finish,start))
  val error=font_text_cache_prepare(cache,f,assets,segment,isub(finish,start),options)
  val ()=case+ error of | ~None_vt() => () | ~Some_vt(e) => metrics_abort()
  val result=cached_metrics(cache,isub(finish,start)) val ()=buf_free(segment)
in result end
fun segments{n:nat} .<n>. (left: int(n),f: !Font,assets: !NativeTextAssets,cache: &Option_vt(FontTextCache) >> _,
  source: !Buf,flags: !Buf,advances: !Buf,base: int,options: FontSpanOptions): void =
  if not(recursion_fuel_available(left)) then () else if ige(base,buf_len(source)) then () else let
    val finish=mandatory(airlock_nat(isub(buf_len(source),base)),flags,iadd(base,1))
    val (local_flags,local_advances)=segment_metrics(f,assets,cache,source,base,finish,options)
    val count=isub(finish,base)
    val ()=merge_metrics(airlock_nat(count),flags,advances,local_flags,local_advances,base,buf_get32(advances,base),1)
    val ()=buf_free(local_flags) val ()=buf_free(local_advances)
  in segments(left-1,f,assets,cache,source,flags,advances,finish,options) end
fun split_metrics(f: !Font,assets: !NativeTextAssets,cache: &Option_vt(FontTextCache) >> _,
  source: !Buf,length: int,options: FontSpanOptions): @(Buf,Buf) = let
  val flags=analyzed(assets,source,length) val advances=buf_make(imul(iadd(length,1),WORD32_BYTES))
  val ()=segments(airlock_nat(MAX_REC_FUEL),f,assets,cache,source,flags,advances,0,options)
in @(flags,advances) end
fun metrics_result(error: Option_vt(FontSpanFailure),f: !Font,assets: !NativeTextAssets,
  cache: &Option_vt(FontTextCache) >> _,b: !Buf,length: int,options: FontSpanOptions): @(Buf,Buf) =
  case+ error of | ~Some_vt(e) => (case+ e of
    | SpanParagraph() => split_metrics(f,assets,cache,b,length,options) | _ => metrics_failed())
    | ~None_vt() => cached_metrics(cache,length)
fun session_metrics(f: !Font,session: &FontTextSession >> FontTextSession,b: !Buf,length: int): @(Buf,Buf) = let
  val+ ~FontTextSession(assets,old,primary,fallback,m)=session
  var cache: Option_vt(FontTextCache)=old val px=font_get_px(f)
  val options: FontSpanOptions= @{primary=primary,fallback=fallback,scale= @{xPpem=px,yPpem=px}}
  val error=font_text_cache_prepare(cache,f,assets,b,length,options)
  val result=metrics_result(error,f,assets,cache,b,length,options)
  val ()=session := FontTextSession(assets,cache,primary,fallback,m)
in result end
fun active_metrics(f: !Font,state: &Option_vt(FontTextSession) >> _,b: !Buf,length: int): @(Buf,Buf) = case+ state of
  | @None_vt() => let prval ()=fold@(state) in metrics_failed() end
  | @Some_vt(session) => let val result=session_metrics(f,session,b,length) prval ()=fold@(state) in result end
implement font_text_wrap_metrics(f,b,length) = let var state=font_text_take(f)
  val result=active_metrics(f,state,b,length) val ()=font_text_put(f,state)
in result end
