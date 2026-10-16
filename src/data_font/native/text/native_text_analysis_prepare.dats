#include "data_font/native/text/native_text_analysis_internal.hats"
fun analyzed(assets: !NativeTextAssets,text: ScalarText,direction: ParagraphDirection): NativeAnalysisRead = let
  val+ NativeTextAssets(aux,words,lines,east)=assets
  val+ NativeTextAux(base,s,b,brackets,mirrors)=aux val+ NativeTextBase(shape,n,mcm)=base
  val+ NativeShapeData(db,c,i,j)=shape
in case+ script_items_make(s,db,b,text,brackets) of
  | ~ScriptItemsRejected(status) => let val ()=scalar_dispose(text)
    in NativeAnalysisRejected(@{reason=AnalysisScriptCapacity(),detail=0}) end
  | ~ScriptItemsAccepted(items) => let
    val bidi=bidi_document_make(b,text,brackets,direction)
    val breaks=line_boundaries(lines,east,c,db,text) val graphemes=grapheme_boundaries(db,text)
  in NativeAnalysisAccepted(NativeTextAnalysis(text,bidi,items,breaks,graphemes)) end end
fun normalized(assets: !NativeTextAssets,text: ScalarText,direction: ParagraphDirection): NativeAnalysisRead = let
  val+ NativeTextAssets(aux,words,lines,east)=assets val+ NativeTextAux(base,s,b,brackets,mirrors)=aux
  val+ NativeTextBase(shape,n,mcm)=base val result=normalization_apply(n,text,NFC())
  val ()=scalar_dispose(text)
in case+ result of | ~CannotNormalize(e) => NativeAnalysisRejected(@{reason=AnalysisNormalization(),detail=e.detail})
  | ~NormalizedText(view) => analyzed(assets,view,direction) end
implement native_text_analyze(assets,source,length,direction) = case+ text_decode(source,length) of
  | ~InvalidTextSpan() => NativeAnalysisRejected(@{reason=AnalysisSpan(),detail=length})
  | ~DecodedText(text) => normalized(assets,text,direction)
