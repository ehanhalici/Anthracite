#include "data_font/native_shape_internal.hats"
fun rejected(p: GlyphPositioned(0),status: GlyphPositionStatus): NativeShapeRead = let
  val ()=glyph_position_dispose(p) var e: NativeShapeError=native_shape_error(NativeShapePositioning())
  val ()=e.position := status
in NativeShapeRejected(e) end
fun frozen(cache: !NativeShapeCache,plan: !NativeShapePlan,p: GlyphPositioned(0)): NativeShapeRead = let
  val+ NativeShapePlan(sub,pos,info)=plan val p=native_shape_clear_advances(cache,p)
in case+ glyph_position_finish(p,native_shape_direction(info.request)) of
  | ~PositionFinished(result) => NativeShapeAccepted(result)
  | ~PositionUnfinished(p,status) => rejected(p,status) end
fun positioned(b: !Buf,cache: !NativeShapeCache,plan: !NativeShapePlan,p: GlyphPositioned(0)): NativeShapeRead = let
  val+ ~PositionStageResult(p,status,applied,matches)=native_shape_position(b,cache,plan,p)
in if glyph_position_ready(status) then frozen(cache,plan,p) else rejected(p,status) end
implement native_shape_positioned(b,info,cache,plan,run,scale) =
  case+ glyph_position_initialize_bytes(b,info,glyph_run_position(run),scale.xPpem,scale.yPpem) of
  | ~PositionInitialized(p) => positioned(b,cache,plan,p)
  | ~PositionRejected(run,status) => let val ()=glyph_run_dispose(run)
    var e: NativeShapeError=native_shape_error(NativeShapePositioning()) val ()=e.position := status
  in NativeShapeRejected(e) end
