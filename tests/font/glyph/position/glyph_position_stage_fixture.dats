#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/layout/ot_layout_parse.sats"
staload "data_font/opentype/layout/ot_layout_language.sats"
staload "data_font/opentype/layout/ot_layout_feature_set.sats"
staload "data_font/opentype/layout/ot_layout_plan.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/core/glyph_metadata.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/glyph/position/glyph_position_types.sats"
staload "data_font/glyph/position/glyph_position_stage_types.sats"
staload "data_font/glyph/position/glyph_position_stage.sats"
staload "data_font/sfnt/sfnt.sats"
staload "font/glyph/position/glyph_position_contracts.sats"
staload "font/glyph/position/glyph_position_font_contracts.sats"
staload "font/glyph/core/glyph_nominal_contracts.sats"
extern fun stage_fixture_failed(): GlyphPositionStage = "mac#anth_die_box"
fun planned(b: !Buf,t: !OtLayoutTable(2,0),m: !GlyphMetadata,set: !OtFeatureSet): GlyphPositionStage = let
  val language=ot_language_default(b,ot_script_select(b,ot_layout_info(t),@{code=1634885986}))
in case+ ot_stage_plan(b,t,language,set) of | ~PlanRejected(e) => stage_fixture_failed()
  | ~PlanAccepted(p) => let
    val result=glyph_position_stage_parse(b,t,p,m,position_test_all()) val ()=ot_plan_dispose(p)
  in case+ result of | ~PositionStageAccepted(stage) => stage | ~PositionStageRejected(e) => stage_fixture_failed() end end
fun selected(b: !Buf,t: !OtLayoutTable(2,0),m: !GlyphMetadata): GlyphPositionStage =
  case+ ot_feature_set_parse(nominal_test_bytes("markmkmk")) of | ~FeatureSetRejected(e) => stage_fixture_failed()
  | ~FeatureSetAccepted(set) => let val stage=planned(b,t,m,set) val ()=ot_feature_set_dispose(set) in stage end
implement position_test_stage_build(b,s,m) = case+ ot_layout_parse(b,s,OtPositioning(),glyph_metadata_capabilities(m)) of
  | ~LayoutRejected(e) => stage_fixture_failed() | ~LayoutAccepted(t) => let
    val stage=selected(b,t,m) val ()=ot_layout_dispose(t)
  in stage end
implement position_font_stage(b,info,m) = case+ sfnt_table(b,info.tables,TableGpos()) of
  | NoSfntTable() => stage_fixture_failed() | HasSfntTable(s) => position_test_stage_build(b,s,m)
