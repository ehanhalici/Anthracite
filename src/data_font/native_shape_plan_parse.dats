#include "data_font/native_shape_internal.hats"
fun positions(b: !Buf,t: !NativePositioning,sub: NativeSubPlan,info: NativePlanInfo): NativeShapePlanRead =
  case+ native_shape_pos_plan(b,t,info) of
    | ~NativePosPlanRejected(e) => let val ()=native_shape_sub_plan_dispose(sub) in NativePlanRejected(e) end
    | ~NativePosPlanAccepted(pos) => NativePlanAccepted(NativeShapePlan(sub,pos,info))
fun planned(b: !Buf,cache: !NativeShapeCache,info: NativePlanInfo): NativeShapePlanRead = let
  val+ NativeShapeCache(m,sub,pos,face)=cache
in case+ native_shape_sub_plan(b,sub,info) of | ~NativeSubPlanRejected(e) => NativePlanRejected(e)
  | ~NativeSubPlanAccepted(s) => positions(b,pos,s,info) end
implement native_shape_plan_parse(b,cache,request,masks) = let val+ NativeShapeCache(m,sub,pos,face)=cache
  val info: NativePlanInfo= @{face=face,request=request,masks=masks}
in if ot_shape_masks_valid(masks) then planned(b,cache,info)
  else NativePlanRejected(ot_error(OtReference(),@{offset=0,length=0})) end
implement native_shape_plan_dispose(plan) = let val+ ~NativeShapePlan(sub,pos,info)=plan
  val ()=native_shape_sub_plan_dispose(sub) in native_shape_pos_plan_dispose(pos) end

