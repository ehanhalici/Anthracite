#include "data_font/text/span/font_span_internal.hats"
staload "data_font/text/span/private/font_span_partition.sats"
fun primary(c: FontSpanCandidate): bool = case+ c of
  | SpanPrimaryCandidate() => true | SpanFallbackCandidate() => false | SpanMissingCandidate() => false | SpanTabCandidate() => false
  | SpanLineEndCandidate() => false
fun fallback(c: FontSpanCandidate): bool = case+ c of
  | SpanPrimaryCandidate() => false | SpanFallbackCandidate() => true | SpanMissingCandidate() => false | SpanTabCandidate() => false
  | SpanLineEndCandidate() => false
fun missing(c: FontSpanCandidate): bool = case+ c of
  | SpanPrimaryCandidate() => false | SpanFallbackCandidate() => false | SpanMissingCandidate() => true | SpanTabCandidate() => false
  | SpanLineEndCandidate() => false
implement font_span_candidate_same(first,second) = case+ first of
  | SpanPrimaryCandidate() => primary(second) | SpanFallbackCandidate() => fallback(second) | SpanMissingCandidate() => missing(second)
  | SpanTabCandidate() => false
  | SpanLineEndCandidate() => false
fun hard_end(cp: int): bool = ieq(cp,10) orelse ieq(cp,13) orelse ieq(cp,11) orelse ieq(cp,12)
  orelse ieq(cp,133) orelse ieq(cp,8232) orelse ieq(cp,8233)
fun arabic(f: !Font,assets: !NativeTextAssets,a: !NativeTextAnalysis,item: NativeTextItem): FontSpanCandidate =
  if font_native_item_covered(f,assets,a,item,GlyphFallbackFace()) then SpanFallbackCandidate()
  else if font_native_item_covered(f,assets,a,item,GlyphPrimaryFace()) then SpanPrimaryCandidate() else SpanMissingCandidate()
fun common(f: !Font,assets: !NativeTextAssets,a: !NativeTextAnalysis,item: NativeTextItem): FontSpanCandidate =
  if font_native_item_covered(f,assets,a,item,GlyphPrimaryFace()) then SpanPrimaryCandidate()
  else if font_native_item_covered(f,assets,a,item,GlyphFallbackFace()) then SpanFallbackCandidate() else SpanMissingCandidate()
fun is_rtl(level: int): bool = ine(imod(level, 2), 0)
fun symbol_policy(f: !Font,assets: !NativeTextAssets,a: !NativeTextAnalysis,item: NativeTextItem): FontSpanCandidate =
  if is_rtl(item.level) then arabic(f,assets,a,item) else common(f,assets,a,item)
implement font_span_candidate(f,assets,a,item) = let val+ NativeTextAnalysis(text,bidi,scripts,breaks,graphemes,source_length)=a
  val cp=scalar_value(text,item.start)
in if ieq(cp,9) then SpanTabCandidate() else if hard_end(cp) then SpanLineEndCandidate()
  else if ieq(item.script.code,1098015074) then arabic(f,assets,a,item) else symbol_policy(f,assets,a,item) end
