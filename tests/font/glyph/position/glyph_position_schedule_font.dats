#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/sfnt/sfnt.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/layout/ot_layout_parse.sats"
staload "data_font/opentype/layout/ot_layout_plan.sats"
staload "data_font/opentype/position_lookup/ot_position_graph_types.sats"
staload "data_font/opentype/position_lookup/ot_position_graph.sats"
staload "data_font/opentype/shape/ot_shape_types.sats"
staload "data_font/opentype/shape/ot_shape_schedule.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/core/glyph_metadata.sats"
staload "data_font/glyph/position/glyph_position_types.sats"
staload "data_font/glyph/position/glyph_position.sats"
staload "data_font/glyph/position/glyph_position_work.sats"
staload "data_font/glyph/position/glyph_position_schedule.sats"
staload "data_font/glyph/position/glyph_position_stage_types.sats"
staload "font/glyph/position/glyph_position_font_contracts.sats"
extern fun schedule_font_failed(): GlyphPositioned(0) = "mac#anth_die_box"
fun rejected(p: GlyphPositioned(0)): GlyphPositioned(0) = let val ()=glyph_position_dispose(p) in schedule_font_failed() end
fun apply(b: !Buf,g: !OtPositionGraph,s: !OtShapeSchedule(2),m: !GlyphMetadata,p: GlyphPositioned(0),
  errors: &int >> int): GlyphPositioned(0) = let
  val info=ot_shape_schedule_info(s)
  val+ ~PositionStageResult(result,status,count,matches)=glyph_position_schedule_apply(b,g,s,m,p,PositionRTL())
  val ()=if glyph_position_ready(status) andalso ieq(count,info.count) andalso ieq(matches,3) then ()
    else errors := iadd(errors,1)
in result end
fun planned(b: !Buf,info: SfntInfo,t: !OtLayoutTable(2,0),g: !OtPositionGraph,m: !GlyphMetadata,p: GlyphPositioned(0),
  errors: &int >> int): GlyphPositioned(0) = let
  val request: OtShapeRequest= @{profile=ShapeArabicHorizontal(),script= @{code=1634885986},
    language=ShapeDefaultLanguage(),direction=ShapeRTL()}
  val masks: OtShapeMasks= @{initial=1u,medial=2u,final=4u,isolated=8u,mirror=16u}
in case+ ot_shape_schedule_parse(b,t,OtPositioning(),request,masks,3,info.glyphs) of
  | ~ShapeRejected(e) => rejected(p) | ~ShapeAccepted(s) => let val result=apply(b,g,s,m,p,errors)
    val ()=ot_shape_schedule_dispose(s) in result end end
fun cached(b: !Buf,info: SfntInfo,t: !OtLayoutTable(2,0),m: !GlyphMetadata,p: GlyphPositioned(0),
  errors: &int >> int): GlyphPositioned(0) = case+ ot_position_graph_parse(b,t,3,info.glyphs) of
  | ~PositionGraphRejected(e) => rejected(p) | ~PositionGraphAccepted(g) => let
    val result=planned(b,info,t,g,m,p,errors) val ()=ot_position_graph_dispose(g) in result end
fun table(b: !Buf,info: SfntInfo,span: OtSpan,m: !GlyphMetadata,p: GlyphPositioned(0),
  errors: &int >> int): GlyphPositioned(0) = case+ ot_layout_parse(b,span,OtPositioning(),glyph_metadata_capabilities(m)) of
  | ~LayoutRejected(e) => rejected(p) | ~LayoutAccepted(t) => let
    val result=cached(b,info,t,m,p,errors) val ()=ot_layout_dispose(t) in result end
implement position_font_scheduled(b,info,m,p,errors) = case+ sfnt_table(b,info.tables,TableGpos()) of
  | NoSfntTable() => rejected(p) | HasSfntTable(span) => table(b,info,span,m,p,errors)
