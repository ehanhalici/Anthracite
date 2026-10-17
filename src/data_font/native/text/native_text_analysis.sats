staload "mem.sats"
staload "data_font/native/text/native_text_assets_types.sats"
staload "data_font/native/text/native_text_analysis_types.sats"
staload "data_text/bidi/bidi_types.sats"
staload "data_text/script/script_types.sats"
staload "data_text/line_break/line_types.sats"
(* Pure paragraph analysis. No font selection, GSUB/GPOS, pixel layout,
   filesystem access, GPU calls or AST coordinates occur in this layer. *)
fun native_text_analyze(assets: !NativeTextAssets,source: !Buf,length: int,direction: ParagraphDirection): NativeAnalysisRead
fun native_text_analysis_count(a: !NativeTextAnalysis): int
fun native_text_analysis_level(a: !NativeTextAnalysis,index: int): int
fun native_text_analysis_script(a: !NativeTextAnalysis,index: int): ScriptCode
fun native_text_analysis_grapheme(a: !NativeTextAnalysis,index: int): bool
fun native_text_analysis_break(a: !NativeTextAnalysis,index: int): LineBreak
fun native_text_analysis_dispose(a: NativeTextAnalysis): void
(* An EGC-aligned window inside one resolved paragraph. Source offsets become
   window-local; bidi levels/base and resolved scripts are inherited. No new
   decoding/normalization errors are introduced by copying normalized scalars. *)
fun native_text_analysis_window(a: !NativeTextAnalysis,start: int,finish: int): NativeAnalysisRead
fun native_text_analysis_memory_bytes(a: !NativeTextAnalysis): llint
