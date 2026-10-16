#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/layout/ot_layout_parse.sats"
staload "data_font/opentype/layout/ot_layout_plan.sats"
staload "data_font/opentype/layout/ot_layout_feature_set.sats"
staload "data_font/opentype/layout/ot_layout_language.sats"
staload "font/opentype/tables/opentype_fixture.sats"
staload "font/opentype/layout/ot_layout_contracts.sats"
fun inspect(p: !OtStagePlan(1),count: int): int =
  if ine(ot_plan_lookup_count(p),count) then 1 else if ieq(count,0) then 0
  else if ine(ot_plan_lookup(p,0),0) orelse ine(ot_plan_lookup(p,1),1) orelse ine(ot_plan_lookup(p,2),2) then 1
  else if ine(ot_plan_feature(p,0,0),2) orelse ine(ot_plan_feature(p,1,0),1)
    orelse ine(ot_plan_feature(p,2,0),1) then 1 else 0
fun requested(b: !Buf,t: !OtLayoutTable(1,0),l: OtChild,set: !OtFeatureSet,count: int): int =
  case+ ot_stage_plan_requested(b,t,l,set) of
  | ~PlanRejected(e) => 1 | ~PlanAccepted(p) => let
    val errors=inspect(p,count) val ()=ot_plan_dispose(p)
  in errors end
fun check(b: !Buf,t: !OtLayoutTable(1,0),tags: string,count: int): int =
  case+ ot_feature_set_parse(layout_bytes(tags)) of
  | ~FeatureSetRejected(e) => 1 | ~FeatureSetAccepted(set) => let
    val info=ot_layout_info(t)
    val l=ot_language_default(b,ot_script_select(b,info,layout_tag("latn")))
    val errors=requested(b,t,l,set,count)
    val ()=ot_feature_set_dispose(set)
  in errors end
implement layout_test_stages() = let
  val b=layout_fixture()
  val errors: int=case+ ot_layout_parse(b,ot_fixture_span(b),OtSubstitution(),
    @{classes=false,attachments=false,markSets=0}) of
    | ~LayoutRejected(e) => 1 | ~LayoutAccepted(t) => let
      val e=check(b,t,"liga",3)+check(b,t,"",0)+check(b,t,"kern",0)
      val ()=ot_layout_dispose(t)
    in e end
  val ()=buf_free(b)
in errors end
