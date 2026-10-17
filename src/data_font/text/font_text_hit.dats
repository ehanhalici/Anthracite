#include "data_font/text/font_text_internal.hats"
staload "data_font/resources/font_hit.sats"
staload "data_font/native/text/native_text_analysis.sats"
staload "data_font/native/text/native_text_analysis_types.sats"
staload "data_text/utf8/utf8.sats"
fun snap{n:nat} .<n>. (left: int(n),a: !NativeTextAnalysis,source: int,length: int,i: int): int =
  if left = 0 then length else let val+ NativeTextAnalysis(text,bidi,scripts,breaks,graphemes)=a
    val start=scalar_start(text,i)
  in if native_text_analysis_grapheme(a,i) andalso ige(start,source) then start else snap(left-1,a,source,length,iadd(i,1)) end
fun click_offset(layout: !FontSpanLayout,source: int,length: int): int = let
  val+ FontSpanLayout(a,items,runs,parts,order,n,width,direction)=layout
in snap(airlock_nat(native_text_analysis_count(a)),a,source,length,0) end
fun rounded(value: int): int = iadd(idiv(value,64),if ige(imod(value,64),32) then 1 else if ile(imod(value,64),~32) then ~1 else 0)
fun bounded(layout: !FontSpanLayout,query: TextQuery,length: int): TextQuery = case+ query of
  | QueryCaret(byte) => QueryCaret(imin(length,imax(0,byte)))
  | QueryClick(pixel) => QueryClick(imin(font_span_width(layout),imax(0,pixel)))
fun queried{b:bool}(slot: !option_vt(FontTextCache,b),n: int,query: TextQuery): FontTextResult = case+ slot of
  | None_vt() => FontTextFailed(SpanShaping()) | Some_vt(cache) => let val+ FontTextCache(key,layout,px,tail)=cache
    val raw=font_span_hit(layout,bounded(layout,query,n))
    val value=case+ query of | QueryCaret(byte) => rounded(raw) | QueryClick(pixel) => click_offset(layout,imin(n,imax(0,raw)),n)
  in FontTextValue(value) end
fun active(f: !Font,session: &FontTextSession >> FontTextSession,b: !Buf,n: int,query: TextQuery): FontTextResult = let
  val+ ~FontTextSession(assets,old,p,a,m)=session var cache: Option_vt(FontTextCache)=old val px=font_get_px(f)
  val options: FontSpanOptions= @{primary=p,fallback=a,scale= @{xPpem=px,yPpem=px}}
  val result=case+ font_text_cache_prepare(cache,f,assets,b,n,options) of
    | ~Some_vt(e) => FontTextFailed(e) | ~None_vt() => queried(cache,n,query)
  val ()=session := FontTextSession(assets,cache,p,a,m)
in result end
fun dispatch{b:bool}(state: &option_vt(FontTextSession,b) >> option_vt(FontTextSession,b),f: !Font,
  source: !Buf,n: int,query: TextQuery): FontTextResult = case+ state of
  | @None_vt() => let prval ()=fold@(state) in FontTextInactive() end
  | @Some_vt(session) => let val result=active(f,session,source,n,query) prval ()=fold@(state) in result end
implement font_text_hit(f,b,n,query) = let var state=font_text_take(f)
  val result=dispatch(state,f,b,n,query) val ()=font_text_put(f,state)
in result end
