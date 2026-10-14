staload "mem.sats"
staload "data_text/utf8.sats"
staload "data_text/bidi_document.sats"
staload "data_text/script_items_types.sats"
staload "data_text/line_types.sats"
staload "data_text/normalization_types.sats"
datatype NativeAnalysisFailure = AnalysisSpan | AnalysisNormalization | AnalysisScriptCapacity
typedef NativeAnalysisError = @{reason=NativeAnalysisFailure,detail=int}
datavtype NativeTextAnalysis = NativeTextAnalysis of (ScalarText,BidiDocument,ScriptItems,LineBreakMap,Buf)
datavtype NativeAnalysisRead = NativeAnalysisAccepted of NativeTextAnalysis | NativeAnalysisRejected of NativeAnalysisError

