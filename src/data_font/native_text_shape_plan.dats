#include "data_font/native_text_shape_internal.hats"
fun requested(b: !Buf,info: SfntInfo,cache: !NativeShapeCache,assets: !NativeTextAssets,
  a: !NativeTextAnalysis,contexts: !NativeTextContexts,item: NativeTextItem,
  request: OtShapeRequest,masks: OtShapeMasks,scale: NativeShapeScale): NativeItemShapeRead =
  case+ native_shape_plan_parse(b,cache,request,masks) of
  | ~NativePlanRejected(e) => NativeItemPlanError(e)
  | ~NativePlanAccepted(plan) => let
    val result=native_item_shape_planned(b,info,cache,assets,a,contexts,item,plan,scale)
    val ()=native_shape_plan_dispose(plan)
  in result end
implement native_text_item_shape(b,info,cache,assets,a,contexts,item,language,masks,scale) =
  case+ native_shape_script_request(item.script,language,native_text_item_direction(item)) of
  | ~NativeScriptRequestUnsupported(script) => NativeItemUnsupported(script)
  | ~NativeScriptRequestAccepted(request) => requested(b,info,cache,assets,a,contexts,item,request,masks,scale)
