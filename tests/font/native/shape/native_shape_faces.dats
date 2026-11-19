#include "font/native/shape/native_shape_test.hats"
fun examples(face: !SfntFace,cache: !NativeShapeCache,plan: !NativeShapePlan,data: !NativeShapeData,
  n: !NormalizationData,mcm: !PropertyMap(9),profile: OtShapeProfile): int = case+ profile of
  | ShapeCommonHorizontal() => native_test_example(face,cache,plan,data,n,mcm,"Ş İ","0120 0269 0000 0000 0003 0269 0000 0000 00F2 0269 0000 0000")
    +native_test_example(face,cache,plan,data,n,mcm,"a‍b","0044 0269 0000 0000 0000 0000 0000 0000 0045 0269 0000 0000")
  | ShapeArabicHorizontal() => native_test_example(face,cache,plan,data,n,mcm,"بَب",
    "0013 011A 0000 0000 0141 0000 0048 FFE0 017A 0000 003D FF48 000F 0345 0000 0000 0141 0000 015A FFE0")
    +native_test_example(face,cache,plan,data,n,mcm,"بَّ","000E 0317 0000 0000 0141 0000 013B FFE0 0174 0000 011E FEEC 017A 0000 0110 FF53")
    +native_test_example(face,cache,plan,data,n,mcm,"بَّ","000E 0317 0000 0000 0141 0000 013B FFE0 0174 0000 011E FEEC 017A 0000 0110 FF53")
fun other(profile: OtShapeProfile): OtShapeProfile = case+ profile of
  | ShapeCommonHorizontal() => ShapeArabicHorizontal() | ShapeArabicHorizontal() => ShapeCommonHorizontal()
(* A kept plan is handed back for an equal request and must shape identically;
   a different request misses and parses its own plan. *)
fun reused(face: !SfntFace,cache: !NativeShapeCache,data: !NativeShapeData,n: !NormalizationData,mcm: !PropertyMap(9),
  profile: OtShapeProfile): int = let val+ SfntFace(b,info)=face
  val kept=native_shape_plans_count(cache)
  val miss=case+ native_shape_plan_take(b,cache,native_test_request(other(profile)),native_test_masks()) of
    | ~NativePlanRejected(e) => 0 | ~NativePlanAccepted(plan) => let val ()=native_shape_plan_dispose(plan) in 0 end
  val still=native_shape_plans_count(cache)
in case+ native_shape_plan_take(b,cache,native_test_request(profile),native_test_masks()) of
  | ~NativePlanRejected(e) => 1 | ~NativePlanAccepted(plan) => let
    val taken=native_shape_plans_count(cache)
    val errors=examples(face,cache,plan,data,n,mcm,profile)
    val ()=native_shape_plan_keep(cache,plan)
    val counts=if ieq(kept,1) andalso ieq(still,1) andalso ieq(taken,0) andalso ieq(native_shape_plans_count(cache),1) then 0 else 1
    val ()=println!("event=native_plan_cache kept=",kept," after_miss=",still," taken=",taken," errors=",errors)
  in iadd(miss,iadd(errors,counts)) end end
fun planned(face: !SfntFace,cache: !NativeShapeCache,data: !NativeShapeData,n: !NormalizationData,mcm: !PropertyMap(9),
  profile: OtShapeProfile): int = let val+ SfntFace(b,info)=face
in case+ native_shape_plan_parse(b,cache,native_test_request(profile),native_test_masks()) of
  | ~NativePlanRejected(e) => 1 | ~NativePlanAccepted(plan) => let val errors=examples(face,cache,plan,data,n,mcm,profile)
    val ()=native_shape_plan_keep(cache,plan)
  in iadd(errors,reused(face,cache,data,n,mcm,profile)) end end
fun cached(face: !SfntFace,data: !NativeShapeData,n: !NormalizationData,mcm: !PropertyMap(9),profile: OtShapeProfile): int = let
  val+ SfntFace(b,info)=face
in case+ native_shape_cache_parse(b,info,3) of | ~NativeCacheRejected(e) => 1
  | ~NativeCacheAccepted(cache) => let val errors=planned(face,cache,data,n,mcm,profile)
    val ()=native_shape_cache_dispose(cache) in errors end end
fun loaded(path: string,data: !NativeShapeData,n: !NormalizationData,mcm: !PropertyMap(9),profile: OtShapeProfile): int =
  case+ sfnt_open(path) of | ~RejectedSfnt(e) => 1 | ~LoadedSfnt(face) => let
    val errors=cached(face,data,n,mcm,profile) val ()=sfnt_dispose(face) in errors end
implement native_test_faces(data,n,mcm) = loaded(c_argv(1),data,n,mcm,ShapeCommonHorizontal())
  +loaded(c_argv(2),data,n,mcm,ShapeArabicHorizontal())
