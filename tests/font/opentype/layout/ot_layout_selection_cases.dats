#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "os/fs.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/layout/ot_layout_parse.sats"
staload "data_font/opentype/layout/ot_layout_tags.sats"
staload "data_font/opentype/layout/ot_layout_plan.sats"
staload "data_font/opentype/layout/ot_layout_feature_set.sats"
staload "data_font/opentype/layout/ot_layout_language.sats"
staload "font/opentype/tables/opentype_fixture.sats"
staload "font/opentype/layout/ot_layout_contracts.sats"

fun default_plan(plan: !OtStagePlan(1)): int =
  if ine(ot_plan_lookup_count(plan),3) then 1
  else if ine(ot_plan_lookup(plan,0),0) orelse ine(ot_plan_lookup(plan,1),1) orelse ine(ot_plan_lookup(plan,2),2) then 1
  else if ine(ot_plan_feature_count(plan,0),2) orelse ine(ot_plan_feature_count(plan,1),1)
    orelse ine(ot_plan_feature_count(plan,2),2) then 1
  else if ine(ot_plan_feature(plan,0,0),0) orelse ine(ot_plan_feature(plan,0,1),2)
    orelse ine(ot_plan_feature(plan,1,0),1) orelse ine(ot_plan_feature(plan,2,0),0)
    orelse ine(ot_plan_feature(plan,2,1),1) then 1 else 0
fun named_plan(plan: !OtStagePlan(1)): int =
  if ine(ot_plan_lookup_count(plan),2) then 1
  else if ine(ot_plan_lookup(plan,0),1) orelse ine(ot_plan_lookup(plan,1),2) then 1
  else if ine(ot_plan_feature_count(plan,0),1) orelse ine(ot_plan_feature_count(plan,1),1) then 1
  else if ine(ot_plan_feature(plan,0,0),1) orelse ine(ot_plan_feature(plan,1,0),1) then 1 else 0
datatype PlanExpectation = DefaultPlan | NamedPlan | EmptyPlan | RequiredPlan | FullPlan
fun inspect(plan: !OtStagePlan(1),expected: PlanExpectation): int = case+ expected of
  | DefaultPlan() => default_plan(plan) | NamedPlan() => named_plan(plan)
  | EmptyPlan() => if ieq(ot_plan_lookup_count(plan),0) then 0 else 1
  | FullPlan() => if ieq(ot_plan_lookup_count(plan),4) then 0 else 1
  | RequiredPlan() => if ine(ot_plan_lookup_count(plan),2) then 1
    else if ine(ot_plan_lookup(plan,0),0) orelse ine(ot_plan_lookup(plan,1),2) then 1 else 0
fun plan(b: !Buf,t: !OtLayoutTable(1,0),l: OtChild,set: !OtFeatureSet,expected: PlanExpectation): int =
  case+ ot_stage_plan(b,t,l,set) of
  | ~PlanRejected(e) => 1 | ~PlanAccepted(p) => let
    val errors=inspect(p,expected)
    val ()=ot_plan_dispose(p)
  in errors end
fun selected(b: !Buf,t: !OtLayoutTable(1,0),s: string): int =
  case+ ot_feature_set_parse(layout_bytes(s)) of
  | ~FeatureSetRejected(e) => 1 | ~FeatureSetAccepted(set) => let
    val info=ot_layout_info(t)
    val latin=ot_script_select(b,info,layout_tag("latn"))
    val default=ot_language_default(b,latin)
    val named=ot_language_named(b,latin,layout_tag("TRK "))
    val fallback=ot_language_named(b,latin,layout_tag("ENG "))
    val dflt=ot_language_default(b,ot_script_select(b,info,layout_tag("arab")))
    val errors=plan(b,t,default,set,DefaultPlan())+plan(b,t,named,set,NamedPlan())+
      plan(b,t,fallback,set,DefaultPlan())+plan(b,t,dflt,set,EmptyPlan())
    val ()=ot_feature_set_dispose(set)
  in errors end
fun other(b: !Buf,t: !OtLayoutTable(1,0),s: string,expected: PlanExpectation): int =
  case+ ot_feature_set_parse(layout_bytes(s)) of
  | ~FeatureSetRejected(e) => 1 | ~FeatureSetAccepted(set) => let
    val info=ot_layout_info(t)
    val l=ot_language_default(b,ot_script_select(b,info,layout_tag("latn")))
    val errors=plan(b,t,l,set,expected)
    val ()=ot_feature_set_dispose(set)
  in errors end
fun reject_plan(b: !Buf,t: !OtLayoutTable(1,0),set: !OtFeatureSet,l: OtChild): int =
  case+ ot_stage_plan(b,t,l,set) of
  | ~PlanRejected(e) => 0
  | ~PlanAccepted(p) => let val ()=ot_plan_dispose(p) in 1 end
fun bad_languages(b: !Buf,t: !OtLayoutTable(1,0),set: !OtFeatureSet): int =
  reject_plan(b,t,set,@{kind=ChildInvalid(),span= @{offset=0,length=0}})+
  reject_plan(b,t,set,@{kind=ChildPresent(),span= @{offset=0,length=6}})+
  reject_plan(b,t,set,@{kind=ChildPresent(),span= @{offset=52,length=5}})+
  reject_plan(b,t,set,@{kind=ChildPresent(),span= @{offset=52,length=SIGNED_INT_MAX_VALUE}})+
  reject_plan(b,t,set,@{kind=ChildPresent(),span= @{offset=8,length=10}})+
  plan(b,t,@{kind=ChildMissing(),span= @{offset=0,length=0}},set,EmptyPlan())
fun boundaries(b: !Buf,t: !OtLayoutTable(1,0)): int = case+ ot_feature_set_parse(layout_bytes("liga")) of
  | ~FeatureSetRejected(e) => 1 | ~FeatureSetAccepted(set) => let
    val errors=bad_languages(b,t,set)
    val ()=ot_feature_set_dispose(set)
  in errors end
fun run(b: !Buf): int =
  case+ ot_layout_parse(b,ot_fixture_span(b),OtSubstitution(),@{classes=false,attachments=false,markSets=0}) of
  | ~LayoutRejected(e) => 1 | ~LayoutAccepted(t) => let
    val errors=selected(b,t,"liga")+selected(b,t,"ligakernliga")+
      other(b,t,"",RequiredPlan())+other(b,t,"rligliga",FullPlan())+boundaries(b,t)
    val ()=ot_layout_dispose(t)
  in errors end
implement layout_test_selection() = let val b=layout_fixture()
  val errors=run(b) val ()=buf_free(b) in errors end
