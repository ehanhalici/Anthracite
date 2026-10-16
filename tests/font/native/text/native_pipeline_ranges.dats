#include "font/native/text/native_pipeline_test.hats"
fun nfc(n: !NormalizationData,text: !ScalarText): int = case+ normalization_apply_range(n,text,3,5,NFC()) of
  | ~CannotNormalize(e) => 1 | ~NormalizedText(view) => let
    val ok=ieq(scalar_count(view),1) andalso ieq(scalar_value(view,0),304)
      andalso ieq(scalar_start(view,0),4) andalso ieq(scalar_end(view,0),7)
    val ()=scalar_dispose(view) in if ok then 0 else 1 end
fun invalid(n: !NormalizationData,text: !ScalarText,start: int,finish: int): int =
  case+ normalization_apply_range(n,text,start,finish,NFD()) of
  | ~CannotNormalize(e) => (case+ e.reason of | NormSourceReason() => 0
    | NormIoReason() => 1 | NormHeaderReason() => 1 | NormRangesReason() => 1
    | NormGraphReason() => 1 | NormLengthReason() => 1)
  | ~NormalizedText(view) => let val ()=scalar_dispose(view) in 1 end
fun empty(n: !NormalizationData,text: !ScalarText): int = case+ normalization_apply_range(n,text,2,2,NFD()) of
  | ~CannotNormalize(e) => 1 | ~NormalizedText(view) => let val ok=ieq(scalar_count(view),0)
    val ()=scalar_dispose(view) in if ok then 0 else 1 end
fun decoded(n: !NormalizationData,text: ScalarText): int = let
  val errors=nfc(n,text)+empty(n,text)+invalid(n,text,~1,2)+invalid(n,text,3,2)+invalid(n,text,0,6)
  val ()=scalar_dispose(text)
in errors end
implement pipeline_range_cases(assets) = let
  val+ NativeTextAssets(aux,w,l,e)=assets val+ NativeTextAux(base,s,b,br,m)=aux
  val+ NativeTextBase(data,n,mcm)=base val source=pipeline_bytes("Ş İ")
  val result=case+ text_decode(source,buf_len(source)) of | ~InvalidTextSpan() => 1
    | ~DecodedText(text) => decoded(n,text)
  val ()=buf_free(source)
in result end
