#include "data_font/opentype/shape/ot_shape_internal.hats"
staload "os/fs.sats"
extern fun shape_literal_failed(): int = "mac#anth_die_int"
fun copy{n:nat} .<n>. (left: int(n),text: string,b: !Buf,index: int): void =
  if left = 0 then () else let val ()=buf_set(b,index,c_str_byte(text,index))
  in copy(left-1,text,b,iadd(index,1)) end
fun feature_set(text: string): OtFeatureSetRead = let
  val size=c_strlen(text) val b=buf_make(size)
  val ()=copy(airlock_nat(size),text,b,0) val ()=buf_set_len(b,size)
in ot_feature_set_parse(b) end
fun contains(tag: OtTag,text: string): bool = case+ feature_set(text) of
  | ~FeatureSetRejected(e) => let val failed=shape_literal_failed() in ieq(failed,1) end
  | ~FeatureSetAccepted(set) => let val result=ot_feature_set_contains(set,tag)
    val ()=ot_feature_set_dispose(set) in result end
fun required_stage{kind:int}{n:nat} .<n>. (left: int(n),domain: OtLayoutDomain(kind),r: OtShapeRequest,
  tag: OtTag,index: int): OtShapeStage =
  if left = 0 then ot_shape_stage_of(domain,r.profile,0) else let val stage=ot_shape_stage_of(domain,r.profile,index)
  in if contains(tag,ot_shape_stage_tags(r,stage)) then stage
    else required_stage(left-1,domain,r,tag,iadd(index,1)) end
fun language(b: !Buf,script: OtChild,request: OtShapeLanguage): OtChild = case+ request of
  | ShapeDefaultLanguage() => ot_language_default(b,script)
  | ShapeNamedLanguage(tag) => ot_language_named(b,script,tag)
fun required(b: !Buf,l: OtChild): OtIndex = case+ l.kind of
  | ChildPresent() => let val info=ot_language_info(b,l.span) in info.required end
  | ChildMissing() => @{found=false,index=0} | ChildInvalid() => @{found=false,index=0}
implement ot_shape_context(b,t,domain,r,masks) = let
  val info=ot_layout_info(t) val script=ot_script_select(b,info,r.script)
  val language=language(b,script,r.language)
  val required=required(b,language)
  val stage=if required.found then required_stage(airlock_nat(ot_shape_stage_count(domain,r.profile)),domain,r,
    ot_record_tag(b,info.features,required.index),0) else ShapeVariation()
in @{domain=domain,request=r,masks=masks,language=language,required=required,requiredStage=stage} end
fun selected{kind:int}(b: !Buf,t: !OtLayoutTable(kind,0),c: OtShapeContext(kind),stage: OtShapeStage,
  set: !OtFeatureSet): OtPlanRead(kind) =
  if ot_shape_stage_equal(stage,c.requiredStage) then ot_stage_plan(b,t,c.language,set)
  else ot_stage_plan_requested(b,t,c.language,set)
implement ot_shape_plan(b,t,c,stage) = case+ feature_set(ot_shape_stage_tags(c.request,stage)) of
  | ~FeatureSetRejected(e) => let val info=ot_layout_info(t) in PlanRejected(ot_error(e,info.span)) end
  | ~FeatureSetAccepted(set) => let
    val result=selected(b,t,c,stage,set)
    val ()=ot_feature_set_dispose(set)
  in result end
