#include "data_font/ot_shape_internal.hats"
fun filled{kind:int}(b: !Buf,t: !OtLayoutTable(kind,0),c: OtShapeContext(kind),s: OtShapeSchedule(kind),
  remaining: &int >> int): OtShapeRead(kind) =
  case+ ot_shape_fill(b,t,c,s,remaining) of | ~None_vt() => ShapeAccepted(s)
    | ~Some_vt(e) => let val ()=ot_shape_schedule_dispose(s) in ShapeRejected(e) end
fun measured{kind:int}(b: !Buf,t: !OtLayoutTable(kind,0),c: OtShapeContext(kind),font: int,glyphs: int): OtShapeRead(kind) = let
  var remaining: int=MAX_REC_FUEL
  val count=ot_shape_measure(b,t,c,remaining)
in case+ count.kind of | ShapeCountRejected() => ShapeRejected(count.error)
  | ShapeCountReady() => filled(b,t,c,ot_shape_schedule_make(count.count,font,glyphs),remaining) end
implement ot_shape_schedule_parse(b,t,domain,r,masks,font,glyphs) =
  if ilt(font,0) orelse not(ot_glyph_domain_valid(glyphs)) orelse not(ot_shape_masks_valid(masks))
  then let val info=ot_layout_info(t) in ShapeRejected(ot_error(OtReference(),info.span)) end
  else measured(b,t,ot_shape_context(b,t,domain,r,masks),font,glyphs)
