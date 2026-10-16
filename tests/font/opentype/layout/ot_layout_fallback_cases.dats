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

datatype FallbackCase = NamedOnly | MissingDflt | SharedDflt
fun modify(b: !Buf,which: FallbackCase): void = case+ which of
  | NamedOnly() => ot_fixture_put16(b,34,0)
  | MissingDflt() => (ot_fixture_put16(b,12,24946);ot_fixture_put16(b,14,24930))
  | SharedDflt() => ot_fixture_put16(b,16,24)
fun language(b: !Buf,info: OtLayoutInfo,which: FallbackCase): OtChild = case+ which of
  | NamedOnly() => ot_language_named(b,ot_script_select(b,info,layout_tag("latn")),layout_tag("ENG "))
  | MissingDflt() => ot_language_default(b,ot_script_select(b,info,layout_tag("zyyy")))
  | SharedDflt() => ot_language_named(b,ot_script_select(b,info,layout_tag("arab")),layout_tag("TRK "))
fun inspect(plan: !OtStagePlan(1),which: FallbackCase): int = case+ which of
  | NamedOnly() => if ieq(ot_plan_lookup_count(plan),0) then 0 else 1
  | MissingDflt() => if ieq(ot_plan_lookup_count(plan),0) then 0 else 1
  | SharedDflt() => if ine(ot_plan_lookup_count(plan),2) then 1
    else if ine(ot_plan_lookup(plan,0),1) orelse ine(ot_plan_lookup(plan,1),2) then 1 else 0
fun plan(b: !Buf,t: !OtLayoutTable(1,0),set: !OtFeatureSet,which: FallbackCase): int = let
  val l=language(b,ot_layout_info(t),which)
in case+ ot_stage_plan(b,t,l,set) of
  | ~PlanRejected(e) => 1 | ~PlanAccepted(p) => let
    val errors=inspect(p,which) val ()=ot_plan_dispose(p)
  in errors end end
fun request(b: !Buf,t: !OtLayoutTable(1,0),which: FallbackCase): int =
  case+ ot_feature_set_parse(layout_bytes("kernliga")) of
  | ~FeatureSetRejected(e) => 1 | ~FeatureSetAccepted(set) => let
    val errors=plan(b,t,set,which) val ()=ot_feature_set_dispose(set)
  in errors end
fun parsed(b: !Buf,which: FallbackCase): int =
  case+ ot_layout_parse(b,ot_fixture_span(b),OtSubstitution(),@{classes=false,attachments=false,markSets=0}) of
  | ~LayoutRejected(e) => 1 | ~LayoutAccepted(t) => let
    val errors=request(b,t,which) val ()=ot_layout_dispose(t)
  in errors end
fun check(which: FallbackCase): int = let
  val b=layout_fixture()
  val ()=modify(b,which)
  val errors=parsed(b,which)
  val ()=buf_free(b)
in errors end
fun duplicate_script(): int = let
  val b=layout_fixture()
  val ()=ot_fixture_put16(b,18,17478)
  val ()=ot_fixture_put16(b,20,19540)
  val errors=layout_reject(b,ot_fixture_span(b),OtSubstitution(),@{classes=false,attachments=false,markSets=0})
  val ()=buf_free(b)
in errors end
implement layout_test_fallback() = check(NamedOnly())+check(MissingDflt())+check(SharedDflt())+duplicate_script()
