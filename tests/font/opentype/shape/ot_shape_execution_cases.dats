#include "font/opentype/shape/ot_shape_test.hats"
fun ready(status: GlyphPassStatus): bool = case+ status of | GlyphPassApplied() => true
  | GlyphPassDomain() => false | GlyphPassReference() => false | GlyphPassCapacity() => false
fun applied(m: !GlyphMetadata,required: int): int = let
  val b=shape_test_fixture(required,"0001 0000 0001 0008 0001 0006 0001 0001 0001 0007")
  val s=shape_test_schedule(b,m,required) val g=substitution_engine_parse(b) var errors: int=0
  val+ ~SubStageResult(r,status,count,matches)=glyph_substitution_schedule_apply(b,g,s,m,shape_test_run(errors))
  val a=glyph_run_query(r,0) and c=glyph_run_query(r,1) and d=glyph_run_query(r,2)
  val ok=ready(status) andalso ieq(count,4) andalso ieq(matches,if ieq(required,1) then 9 else 7)
    andalso ieq(a.core.glyph,8) andalso ieq(c.core.glyph,8) andalso ieq(d.core.glyph,if ieq(required,1) then 8 else 6)
    andalso ieq(a.core.sourceStart,0) andalso ieq(d.core.sourceEnd,6)
  val ()=glyph_run_dispose(r) and ()=ot_shape_schedule_dispose(s) and ()=ot_substitution_graph_dispose(g) and ()=buf_free(b)
in iadd(errors,if ok then 0 else 1) end
fun rollback(m: !GlyphMetadata): int = let
  val b=shape_test_fixture(WORD16_MAX_VALUE,"0005 0000 0001 0008 0003 0001 0001 000C 0000 0002 0001 0001 0007")
  val s=shape_test_schedule(b,m,WORD16_MAX_VALUE) val g=substitution_engine_parse(b) var errors: int=0
  val+ ~SubStageResult(r,status,count,matches)=glyph_substitution_schedule_apply(b,g,s,m,shape_test_run(errors))
  val row=glyph_run_query(r,0)
  val rejected=case+ status of | GlyphPassReference() => true | GlyphPassApplied() => false
    | GlyphPassDomain() => false | GlyphPassCapacity() => false
  val ok=rejected andalso ieq(count,0) andalso ieq(matches,0) andalso ieq(row.core.glyph,5)
  val ()=glyph_run_dispose(r) and ()=ot_shape_schedule_dispose(s) and ()=ot_substitution_graph_dispose(g) and ()=buf_free(b)
in iadd(errors,if ok then 0 else 1) end
implement shape_test_execution() = let val b=ligation_test_metadata_bytes() val m=ligation_test_metadata(b)
  val errors=applied(m,WORD16_MAX_VALUE)+applied(m,1)+rollback(m)
  val ()=glyph_metadata_dispose(m) and ()=buf_free(b)
in errors end
