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

(* Maximum unsigned-16 reference arrays remain legal even with duplicates. *)
fun language_fixture(): Buf = let
  var b=ot_fixture_words("0001 0000 0026 000A 0018 0001 6C69 6761 0008 0000 0001 0000 0001 0004 0001 0000 0001 0008 0001 0001 6C61 746E 0008 0004 0000 0000 FFFF FFFF")
  val ()=buf_resize(b,131134)
  val ()=buf_set_len(b,131134)
in b end
fun feature_fixture(): Buf = let
  var b=ot_fixture_words("0001 0000 000A 002C 001E 0001 6C61 746E 0008 0004 0000 0000 FFFF 0001 0000 0001 0004 0001 0000 0001 0008 0001 0001 6C69 6761 0008 0000 FFFF")
  val ()=buf_resize(b,131134)
  val ()=buf_set_len(b,131134)
in b end
fun single(plan: !OtStagePlan(1)): int =
  if ine(ot_plan_lookup_count(plan),1) then 1
  else if ine(ot_plan_lookup(plan,0),0) orelse ine(ot_plan_feature_count(plan,0),1) then 1
  else if ine(ot_plan_feature(plan,0,0),0) then 1 else 0
fun selected(b: !Buf,t: !OtLayoutTable(1,0),set: !OtFeatureSet): int = let
  val info=ot_layout_info(t)
  val lang=ot_language_default(b,ot_script_select(b,info,layout_tag("latn")))
in case+ ot_stage_plan(b,t,lang,set) of
  | ~PlanRejected(e) => 1 | ~PlanAccepted(plan) => let
    val errors=single(plan) val ()=ot_plan_dispose(plan)
  in errors end end
fun request(b: !Buf,t: !OtLayoutTable(1,0)): int =
  case+ ot_feature_set_parse(layout_bytes("liga")) of
  | ~FeatureSetRejected(e) => 1 | ~FeatureSetAccepted(set) => let
    val errors=selected(b,t,set) val ()=ot_feature_set_dispose(set)
  in errors end
fun check(b: Buf): int = let
  val errors: int=case+ ot_layout_parse(b,ot_fixture_span(b),OtSubstitution(),@{classes=false,attachments=false,markSets=0}) of
    | ~LayoutRejected(e) => 1 | ~LayoutAccepted(t) => let
      val errors=request(b,t) val ()=ot_layout_dispose(t) in errors end
  val ()=buf_free(b)
in errors end
implement layout_test_stress() = check(language_fixture())+check(feature_fixture())
