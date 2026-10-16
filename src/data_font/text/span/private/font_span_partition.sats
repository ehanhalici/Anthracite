staload "mem.sats"
staload "data_font/resources/font.sats"
staload "data_font/native/text/native_text_assets_types.sats"
staload "data_font/native/text/native_text_analysis_types.sats"
staload "data_font/native/text/native_text_items_types.sats"
datatype FontSpanCandidate = SpanPrimaryCandidate | SpanFallbackCandidate | SpanMissingCandidate | SpanTabCandidate | SpanLineEndCandidate
fun font_span_candidate(f: !Font,assets: !NativeTextAssets,a: !NativeTextAnalysis,item: NativeTextItem): FontSpanCandidate
fun font_span_candidate_same(first: FontSpanCandidate,second: FontSpanCandidate): bool
fun font_span_cluster_finish(a: !NativeTextAnalysis,start: int,limit: int): int
fun font_span_partition_mark(f: !Font,assets: !NativeTextAssets,a: !NativeTextAnalysis,cuts: !Buf): void
fun font_span_items_make(f: !Font,assets: !NativeTextAssets,a: !NativeTextAnalysis): NativeItemsRead
