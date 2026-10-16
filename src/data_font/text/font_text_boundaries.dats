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
