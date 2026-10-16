#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_reader.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/layout/ot_layout_parse.sats"
staload "data_font/opentype/layout/ot_layout_plan.sats"
staload "data_font/opentype/layout/ot_layout_plan_work.sats"
staload "data_font/opentype/layout/ot_layout_language.sats"
extern fun plan_mismatch(): void = "mac#anth_die_void"

fun copy {n:nat} .<n>. (n: int(n),source: !Buf,output: !Buf,i: int): void =
  if n = 0 then () else let val ()=buf_set32(output,i,buf_get32(source,i)) in copy(n-1,source,output,iadd(i,1)) end

fun build{kind:int}(b: !Buf,info: OtLayoutInfo,selected: !Buf): OtStagePlan(kind) = let
  val counts=buf_make(imul(info.lookupCount,4))
  val seen=buf_make(imul(info.lookupCount,4))
  val total=ot_plan_count_edges(b,info,selected,counts,seen)
  val offsets=buf_make(imul(iadd(info.lookupCount,1),4))
  val ids=buf_make(imul(info.lookupCount,4))
  val size=ot_plan_lookup_ids(counts,ids,info.lookupCount)
  val owners=buf_make(imul(total,4))
  val cursors=buf_make(imul(info.lookupCount,4))
  val checked=ot_plan_prefix(counts,offsets,info.lookupCount)
  val ()=if ine(checked,total) then plan_mismatch() else ()
  val ()=copy(airlock_nat(info.lookupCount),offsets,cursors,0)
  val ()=buf_zero(seen)
  val ()=ot_plan_fill(b,info,selected,cursors,seen,owners)
  val ()=buf_free(counts) and ()=buf_free(seen) and ()=buf_free(cursors)
in OtStagePlan(ids,offsets,owners,size,total) end

fun finish{kind:int}(b: !Buf,info: OtLayoutInfo,selection: Buf,cost: int): OtPlanRead(kind) =
  if ilt(cost,0) then let val ()=buf_free(selection)
    in PlanRejected(ot_error(OtCapacity(),info.span)) end
  else let
    val plan: OtStagePlan(kind)=build(b,info,selection)
    val ()=buf_free(selection)
  in PlanAccepted(plan) end

fun selected{kind:int}(b: !Buf,info: OtLayoutInfo,language: OtChild,set: !OtFeatureSet): OtPlanRead(kind) = let
  val selection=ot_plan_selection(b,info,language,set)
  val cost=ot_plan_reference_cost(b,info,selection)
in finish(b,info,selection,cost) end
fun requested{kind:int}(b: !Buf,info: OtLayoutInfo,language: OtChild,set: !OtFeatureSet): OtPlanRead(kind) = let
  val selection=ot_plan_selection_requested(b,info,language,set)
  val cost=ot_plan_reference_cost(b,info,selection)
in finish(b,info,selection,cost) end

fun validate_language(b: !Buf,info: OtLayoutInfo,language: OtChild): Option_vt(OtError) =
  case+ language.kind of
  | ChildMissing() => None_vt()
  | ChildInvalid() => Some_vt(ot_error(OtBounds(),language.span))
  | ChildPresent() => let val span=language.span in
    if not(ot_span_valid(b,span)) orelse ilt(span.offset,info.span.offset)
      orelse igt(span.offset,iadd(info.span.offset,info.span.length))
      orelse igt(span.length,isub(iadd(info.span.offset,info.span.length),span.offset))
    then Some_vt(ot_error(OtBounds(),span)) else ot_language_validate(b,span,info.features.count) end

implement ot_stage_plan(b,table,language,set) = let val info=ot_layout_info(table) in
  case+ validate_language(b,info,language) of
  | ~Some_vt(e) => PlanRejected(e)
  | ~None_vt() => selected(b,info,language,set) end
implement ot_stage_plan_requested(b,table,language,set) = let val info=ot_layout_info(table) in
  case+ validate_language(b,info,language) of
  | ~Some_vt(e) => PlanRejected(e)
  | ~None_vt() => requested(b,info,language,set) end
