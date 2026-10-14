#include "data_font/native_shape_internal.hats"
fun substitutions(b: !Buf,info: SfntInfo,cache: !NativeShapeCache,plan: !NativeShapePlan,
  run: GlyphRun(1),scale: NativeShapeScale): NativeShapeRead = let
  val+ ~SubStageResult(run,status,applied,matches)=native_shape_substitute(b,cache,plan,run)
  val ready=case+ status of | GlyphPassApplied() => true | GlyphPassDomain() => false
    | GlyphPassReference() => false | GlyphPassCapacity() => false
in if ready then native_shape_positioned(b,info,cache,plan,run,scale) else let
  val ()=glyph_run_dispose(run) var e: NativeShapeError=native_shape_error(NativeShapeSubstitution())
  val ()=e.substitution := status
in NativeShapeRejected(e) end end
fun nominal(b: !Buf,info: SfntInfo,cache: !NativeShapeCache,plan: !NativeShapePlan,data: !NativeShapeData,
  text: !ScalarText,context: ArabicContext,scale: NativeShapeScale): NativeShapeRead = let
  val+ NativeShapeData(db,category,ignored,joining)=data val+ NativeShapePlan(sub,pos,p)=plan
in case+ glyph_nominal_read_bytes(b,info,db,text,p.face.font,0u) of
  | ~GlyphRunRejected(status) => let var e: NativeShapeError=native_shape_error(NativeShapeNominal())
    val ()=e.edit := status in NativeShapeRejected(e) end
  | ~GlyphRunCreated(run) => substitutions(b,info,cache,plan,native_shape_prepare(data,plan,context,run),scale) end
implement native_shape_run(b,info,cache,plan,data,text,context,scale) = let
  val+ NativeShapeCache(m,sub,pos,face)=cache val+ NativeShapePlan(selected,positions,p)=plan
  val+ NativeShapeText(source,profile)=text
  val valid=ieq(face.font,p.face.font) andalso ieq(face.glyphs,p.face.glyphs) andalso ieq(face.units,p.face.units)
    andalso ieq(info.glyphs,face.glyphs) andalso ieq(info.units,face.units)
    andalso native_shape_profile_equal(profile,p.request.profile)
in if valid then nominal(b,info,cache,plan,data,source,context,scale)
  else NativeShapeRejected(native_shape_error(NativeShapeFace())) end
