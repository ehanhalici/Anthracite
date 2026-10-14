#include "ot_shape_test.hats"
staload "data_font/ot_shape_work.sats"
fun check_row(s: !OtShapeSchedule(1),index: int,id: int,stage: OtShapeStage,mask: uint): int = let
  val row=ot_shape_schedule_at(s,index)
  val selected=case+ row.selection.kind of | GlyphAll() => g0uint_eq_uint(mask,0u)
    | GlyphMasked() => g0uint_eq_uint(mask,row.selection.mask)
  val correct=ot_shape_stage_equal(stage,row.stage)
in if ieq(row.lookup,id) andalso selected andalso correct then 0 else 1 end
fun schedule(m: !GlyphMetadata,required: int): int = let
  val b=shape_test_fixture(required,"0001 0000 0001 0008 0001 0006 0001 0001 0001 0007")
  val s=shape_test_schedule(b,m,required) val info=ot_shape_schedule_info(s)
  val errors=if ieq(info.count,4) then check_row(s,0,0,ShapeComposition(),0u)
    +check_row(s,1,1,ShapeIsolated(),8u)+check_row(s,2,1,ShapeInitial(),if ieq(required,1) then 0u else 1u)
    +check_row(s,3,2,ShapeRequiredLigatures(),0u) else 1
  val ()=ot_shape_schedule_dispose(s) and ()=buf_free(b)
in errors end
extern fun shape_layout_failed(): OtLayoutTable(1,0) = "mac#anth_die_box"
fun table(b: !Buf,m: !GlyphMetadata): OtLayoutTable(1,0) = case+ ot_layout_parse(b,ot_fixture_span(b),OtSubstitution(),glyph_metadata_capabilities(m)) of
  | ~LayoutRejected(e) => shape_layout_failed() | ~LayoutAccepted(t) => t
fun rejected(m: !GlyphMetadata): int = let
  val b=shape_test_fixture(65535,"0001 0000 0000") val t=table(b,m)
  val invalid: OtShapeMasks= @{initial=1u,medial=1u,final=4u,isolated=8u,mirror=16u}
  val errors=case+ ot_shape_schedule_parse(b,t,OtSubstitution(),shape_test_request(),invalid,3,128) of
    | ~ShapeRejected(e) => 0 | ~ShapeAccepted(s) => let val ()=ot_shape_schedule_dispose(s) in 1 end
  val ()=ot_layout_dispose(t) and ()=buf_free(b)
in errors end
implement shape_test_cases() = let val b=ligation_test_metadata_bytes() val m=ligation_test_metadata(b)
  val errors=schedule(m,65535)+schedule(m,0)+schedule(m,1)+rejected(m)
  val ()=glyph_metadata_dispose(m) and ()=buf_free(b)
in errors end

