#include "font/native/text/native_pipeline_note.hats"
staload "data_text/source/text_source.sats"
fun itemized(assets: !NativeTextAssets,a: !NativeTextAnalysis,contexts: !NativeTextContexts,
  latin: !SfntFace,lc: !NativeShapeCache,arabic: !SfntFace,ac: !NativeShapeCache): int =
  case+ native_text_items_make(a) of | ~NativeItemsRejected(e) => 1 | ~NativeItemsAccepted(items) => let
    val stats=pipeline_note_walk(assets,a,contexts,items,latin,lc,arabic,ac)
    val ()=native_text_items_dispose(items)
    val ()=println!("event=native_note items=",stats.items," glyphs=",stats.glyphs," missing=",stats.missing,
      " spans=",stats.spans," marks=",stats.marks," mark_advances=",stats.advances," failures=",stats.failures)
  in stats.missing+stats.spans+stats.advances+stats.failures end
fun analyzed(assets: !NativeTextAssets,a: NativeTextAnalysis,latin: !SfntFace,lc: !NativeShapeCache,
  arabic: !SfntFace,ac: !NativeShapeCache): int = let
  val errors=case+ native_text_context_make(assets,a) of | ~NativeContextRejected(e) => 1
    | ~NativeContextAccepted(contexts) => let val result=itemized(assets,a,contexts,latin,lc,arabic,ac)
      val ()=native_text_context_dispose(contexts) in result end
  val ()=native_text_analysis_dispose(a)
in errors end
fun source(assets: !NativeTextAssets,latin: !SfntFace,lc: !NativeShapeCache,arabic: !SfntFace,ac: !NativeShapeCache,path: string): int =
  case+ text_file_read(path) of | ~TextFileError(e) => 1 | ~TextFile(bytes) => let
    val errors=case+ native_text_analyze(assets,bytes,buf_len(bytes),AutoLtr()) of
      | ~NativeAnalysisRejected(e) => 1 | ~NativeAnalysisAccepted(a) => analyzed(assets,a,latin,lc,arabic,ac)
    val ()=buf_free(bytes)
  in errors end
fun cached(assets: !NativeTextAssets,latin: !SfntFace,lc: !NativeShapeCache,arabic: !SfntFace,path: string): int = let
  val+ SfntFace(b,info)=arabic
in case+ native_shape_cache_parse(b,info,2) of | ~NativeCacheRejected(e) => 1 | ~NativeCacheAccepted(ac) => let
    val result=source(assets,latin,lc,arabic,ac,path) val ()=native_shape_cache_dispose(ac)
  in result end end
implement pipeline_note_cases(assets,latin,arabic,path) = let val+ SfntFace(b,info)=latin
in case+ native_shape_cache_parse(b,info,1) of | ~NativeCacheRejected(e) => 1 | ~NativeCacheAccepted(lc) => let
    val result=cached(assets,latin,lc,arabic,path) val ()=native_shape_cache_dispose(lc)
  in result end end
