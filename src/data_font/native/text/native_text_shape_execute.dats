#include "data_font/native/text/native_text_shape_internal.hats"
fun shaped(b: !Buf,info: SfntInfo,cache: !NativeShapeCache,plan: !NativeShapePlan,data: !NativeShapeData,
  text: !NativeShapeText,context: ArabicContext,scale: NativeShapeScale): NativeItemShapeRead =
  case+ native_shape_run(b,info,cache,plan,data,text,context,scale) of
  | ~NativeShapeRejected(e) => NativeItemRunError(e) | ~NativeShapeAccepted(run) => NativeItemShaped(run)
implement native_item_shape_planned(b,info,cache,assets,a,contexts,item,plan,scale) = let
  val+ NativeTextAssets(aux,words,lines,east)=assets val+ NativeTextAux(base,s,bidi,brackets,mirrors)=aux
  val+ NativeTextBase(data,n,mcm)=base val+ NativeTextAnalysis(source,doc,scripts,breaks,graphemes)=a
in case+ native_shape_text_parse_range(b,info,plan,n,mcm,source,item.start,item.finish) of
  | ~NativeTextRejected(e) => NativeItemTextError(e)
  | ~NativeTextAccepted(text) => let
    val context=native_text_context_at(contexts,item.start,item.finish)
    val result=shaped(b,info,cache,plan,data,text,context,scale)
    val ()=native_shape_text_dispose(text)
  in result end end
