#include "data_font/native/shape/native_shape_internal.hats"
fun positions(b: !Buf,t: !NativePositioning,sub: NativeSubPlan,info: NativePlanInfo): NativeShapePlanRead =
  case+ native_shape_pos_plan(b,t,info) of
    | ~NativePosPlanRejected(e) => let val ()=native_shape_sub_plan_dispose(sub) in NativePlanRejected(e) end
    | ~NativePosPlanAccepted(pos) => NativePlanAccepted(NativeShapePlan(sub,pos,info))
fun planned(b: !Buf,cache: !NativeShapeCache,info: NativePlanInfo): NativeShapePlanRead = let
  val+ NativeShapeCache(m,sub,pos,face,plans)=cache
in case+ native_shape_sub_plan(b,sub,info) of | ~NativeSubPlanRejected(e) => NativePlanRejected(e)
  | ~NativeSubPlanAccepted(s) => positions(b,pos,s,info) end
implement native_shape_plan_parse(b,cache,request,masks) = let val+ NativeShapeCache(m,sub,pos,face,plans)=cache
  val info: NativePlanInfo= @{face=face,request=request,masks=masks}
in if ot_shape_masks_valid(masks) then planned(b,cache,info)
  else NativePlanRejected(ot_error(OtReference(),@{offset=0,length=0})) end
implement native_shape_plan_dispose(plan) = let val+ ~NativeShapePlan(sub,pos,info)=plan
  val ()=native_shape_sub_plan_dispose(sub) in native_shape_pos_plan_dispose(pos) end

macdef NATIVE_PLAN_CACHE_ENTRIES = 64
fun profile_eq(a: OtShapeProfile,b: OtShapeProfile): bool = case+ a of
  | ShapeCommonHorizontal() => (case+ b of | ShapeCommonHorizontal() => true | ShapeArabicHorizontal() => false)
  | ShapeArabicHorizontal() => (case+ b of | ShapeCommonHorizontal() => false | ShapeArabicHorizontal() => true)
fun direction_eq(a: OtShapeDirection,b: OtShapeDirection): bool = case+ a of
  | ShapeLTR() => (case+ b of | ShapeLTR() => true | ShapeRTL() => false)
  | ShapeRTL() => (case+ b of | ShapeLTR() => false | ShapeRTL() => true)
fun language_eq(a: OtShapeLanguage,b: OtShapeLanguage): bool = case+ a of
  | ShapeDefaultLanguage() => (case+ b of | ShapeDefaultLanguage() => true | ShapeNamedLanguage(y) => false)
  | ShapeNamedLanguage(x) => (case+ b of | ShapeDefaultLanguage() => false | ShapeNamedLanguage(y) => ieq(x.code,y.code))
fun masks_eq(a: OtShapeMasks,b: OtShapeMasks): bool =
  a.initial = b.initial andalso a.medial = b.medial andalso a.final = b.final
  andalso a.isolated = b.isolated andalso a.mirror = b.mirror
fun info_matches(info: NativePlanInfo,request: OtShapeRequest,masks: OtShapeMasks): bool =
  profile_eq(info.request.profile,request.profile) andalso ieq(info.request.script.code,request.script.code)
  andalso language_eq(info.request.language,request.language) andalso direction_eq(info.request.direction,request.direction)
  andalso masks_eq(info.masks,masks)
fun plan_matches(plan: !NativeShapePlan,request: OtShapeRequest,masks: OtShapeMasks): bool = let
  val+ NativeShapePlan(sub,pos,info)=plan in info_matches(info,request,masks) end
(* Removes and returns the first matching plan; the rest keep their order. *)
fun extract{n:nat} .<n>. (fuel: int(n),plans: &NativePlanCache >> _,request: OtShapeRequest,masks: OtShapeMasks): Option_vt(NativeShapePlan) =
  if fuel = 0 then None_vt() else case+ plans of
  | NativePlansEmpty() => None_vt()
  | @NativePlansCons(plan,rest) =>
    if plan_matches(plan,request,masks) then let
      val found=plan val tail=rest val ()=free@(plans) val ()=plans := tail
    in Some_vt(found) end
    else let val result=extract(fuel-1,rest,request,masks) prval ()=fold@(plans) in result end
implement native_shape_plans_dispose(plans) = case+ plans of
  | ~NativePlansEmpty() => ()
  | ~NativePlansCons(plan,rest) => let val ()=native_shape_plan_dispose(plan) in native_shape_plans_dispose(rest) end
fun plans_length{n:nat} .<n>. (fuel: int(n),plans: !NativePlanCache): int =
  if fuel = 0 then 0 else case+ plans of
  | NativePlansEmpty() => 0 | NativePlansCons(plan,rest) => iadd(1,plans_length(fuel-1,rest))
fun truncate{n:nat} .<n>. (left: int(n),plans: &NativePlanCache >> _): void =
  case+ plans of
  | NativePlansEmpty() => ()
  | @NativePlansCons(plan,rest) =>
    if left = 0 then let val tail=rest val ()=native_shape_plan_dispose(plan) val ()=free@(plans)
      in plans := NativePlansEmpty(); native_shape_plans_dispose(tail) end
    else let val ()=truncate(left-1,rest) prval ()=fold@(plans) in () end
implement native_shape_plan_take(b,cache,request,masks) = let
  val+ @NativeShapeCache(m,sub,pos,face,plans)=cache
  val found=extract(airlock_nat(NATIVE_PLAN_CACHE_ENTRIES),plans,request,masks)
  prval ()=fold@(cache)
in case+ found of
  | ~Some_vt(plan) => NativePlanAccepted(plan)
  | ~None_vt() => native_shape_plan_parse(b,cache,request,masks) end
implement native_shape_plan_keep(cache,plan) = let
  val+ @NativeShapeCache(m,sub,pos,face,plans)=cache
  val ()=plans := NativePlansCons(plan,plans)
  val ()=truncate(NATIVE_PLAN_CACHE_ENTRIES,plans)
  prval ()=fold@(cache)
in () end
implement native_shape_plans_count(cache) = let val+ NativeShapeCache(m,sub,pos,face,plans)=cache
in plans_length(airlock_nat(iadd(NATIVE_PLAN_CACHE_ENTRIES,1)),plans) end
