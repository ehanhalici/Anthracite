#include "data_font/text/font_text_internal.hats"
staload "data_font/native/text/native_text_analysis.sats"
staload "data_font/native/text/native_text_analysis_types.sats"
staload "data_text/utf8/utf8.sats"
staload "data_text/line_break/line_types.sats"
staload "data_text/bidi/bidi_types.sats"
fun break_code(b: LineBreak): int = case+ b of
  | BreakForbidden() => 1 | BreakOptional() => 3 | BreakMandatory() => 5
fun fallback_flags(n: int): Buf = let
  val safe_n = imax(0, n)
  val flags = buf_make(iadd(safe_n, 1))
  val () = buf_set(flags, safe_n, 5)
in flags end
fun fill{n:nat} .<n>. (left: int(n),a: !NativeTextAnalysis,flags: !Buf,i: int): void =
  if left = 0 then () else let val+ NativeTextAnalysis(text,bidi,scripts,breaks,graphemes,source_length)=a
    val ()=if native_text_analysis_grapheme(a,i) then
      buf_set(flags,scalar_start(text,i),break_code(native_text_analysis_break(a,i))) else ()
  in fill(left-1,a,flags,iadd(i,1)) end
fun analyzed(assets: !NativeTextAssets,b: !Buf,n: int): Buf = case+ native_text_analyze(assets,b,n,AutoLtr()) of
  | ~NativeAnalysisRejected(e) => fallback_flags(n)
  | ~NativeAnalysisAccepted(a) => let val safe_n = imax(0, n)
    val flags=buf_make(iadd(safe_n,1)) val ()=buf_zero(flags)
    val ()=fill(airlock_nat(native_text_analysis_count(a)),a,flags,0)
    val ()=buf_set(flags,safe_n,5) val ()=native_text_analysis_dispose(a)
  in flags end
fun active{b:bool}(state: !option_vt(FontTextSession,b),source: !Buf,n: int): Buf = case+ state of
  | None_vt() => fallback_flags(n) | Some_vt(session) => let val+ FontTextSession(assets,cache,p,f,m)=session
  in analyzed(assets,source,n) end
implement font_text_boundaries(f,b,n) = let val state=font_text_take(f)
  val flags=active(state,b,n) val ()=font_text_put(f,state)
in flags end

fun metrics_fallback(length: int): @(Buf, Buf) = let
  val safe_n = imax(0, length)
  val flags = fallback_flags(safe_n)
  val advances = buf_make(imul(iadd(safe_n, 1), WORD32_BYTES))
in @(flags, advances) end
fun cached_metrics{b:bool}(state: !option_vt(FontTextCache,b),length: int): @(Buf,Buf) = case+ state of
  | None_vt() => metrics_fallback(length)
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
  val seg_len = imax(0, isub(finish, start))
  var segment=buf_make(imax(1, seg_len)) val ()=buf_append_at(segment,source,start,seg_len)
  val error=font_text_cache_prepare(cache,f,assets,segment,seg_len,options)
  val result = (case+ error of
    | ~None_vt() => cached_metrics(cache, seg_len)
    | ~Some_vt(e) => metrics_fallback(seg_len)): @(Buf, Buf)
  val ()=buf_free(segment)
in result end
fun segments{n:nat} .<n>. (left: int(n),f: !Font,assets: !NativeTextAssets,cache: &Option_vt(FontTextCache) >> _,
  source: !Buf,flags: !Buf,advances: !Buf,base: int,options: FontSpanOptions): void =
  if not(recursion_fuel_available(left)) then () else if ige(base,buf_len(source)) then () else let
    val finish=mandatory(airlock_nat(imax(0,isub(buf_len(source),base))),flags,iadd(base,1))
    val (local_flags,local_advances)=segment_metrics(f,assets,cache,source,base,finish,options)
    val count=imax(0,isub(finish,base))
    val ()=merge_metrics(airlock_nat(count),flags,advances,local_flags,local_advances,base,buf_get32(advances,base),1)
    val ()=buf_free(local_flags) val ()=buf_free(local_advances)
  in segments(left-1,f,assets,cache,source,flags,advances,imax(iadd(base,1),finish),options) end
fun split_metrics(f: !Font,assets: !NativeTextAssets,cache: &Option_vt(FontTextCache) >> _,
  source: !Buf,length: int,options: FontSpanOptions): @(Buf,Buf) = let
  val flags=analyzed(assets,source,length) val advances=buf_make(imul(iadd(imax(0,length),1),WORD32_BYTES))
  val ()=segments(airlock_nat(MAX_REC_FUEL),f,assets,cache,source,flags,advances,0,options)
in @(flags,advances) end
fun metrics_result(error: Option_vt(FontSpanFailure),f: !Font,assets: !NativeTextAssets,
  cache: &Option_vt(FontTextCache) >> _,b: !Buf,length: int,options: FontSpanOptions): @(Buf,Buf) =
  case+ error of | ~Some_vt(e) => (case+ e of
    | SpanParagraph() => split_metrics(f,assets,cache,b,length,options)
    | SpanAnalysis() => metrics_fallback(length)
    | SpanItems() => metrics_fallback(length)
    | SpanContext() => metrics_fallback(length)
    | SpanShaping() => metrics_fallback(length)
    | SpanCapacity() => metrics_fallback(length)
    | SpanOverflow() => metrics_fallback(length)
    | SpanMissing() => metrics_fallback(length)
    | SpanUnsupported() => metrics_fallback(length))
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
  | @None_vt() => let prval ()=fold@(state) in metrics_fallback(length) end
  | @Some_vt(session) => let val result=session_metrics(f,session,b,length) prval ()=fold@(state) in result end
implement font_text_wrap_metrics(f,b,length) = let var state=font_text_take(f)
  val result=active_metrics(f,state,b,length) val ()=font_text_put(f,state)
in result end
