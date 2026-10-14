#include "glyph_substitution_stage_test.hats"
fun ready(status: GlyphPassStatus): bool = case+ status of | GlyphPassApplied() => true
  | GlyphPassDomain() => false | GlyphPassReference() => false | GlyphPassCapacity() => false
fun basic(m: !GlyphMetadata): int = let
  val b=substitution_stage_fixture("0001 0000 0000") val stage=substitution_stage_build(b,m,"ccmp")
  var errors: int=0 val source=ligation_test_run("0005",errors)
  val+ ~SubStageResult(r,status,applied,matches)=glyph_substitution_stage_apply(b,stage,m,source)
  val row=glyph_run_query(r,0)
  val ok=ready(status) andalso ieq(applied,3) andalso ieq(matches,2) andalso ieq(row.core.glyph,7)
    andalso ieq(row.core.sourceStart,0) andalso ieq(row.core.sourceEnd,2)
  val ()=glyph_run_dispose(r) and ()=glyph_substitution_stage_dispose(stage) and ()=buf_free(b)
in iadd(errors,if ok then 0 else 1) end
fun rollback(m: !GlyphMetadata): int = let
  val b=substitution_stage_fixture("0005 0000 0001 0008 0003 0001 0001 000C 0000 0002 0001 0001 0007")
  val stage=substitution_stage_build(b,m,"ccmp") var errors: int=0
  val+ ~SubStageResult(r,status,applied,matches)=glyph_substitution_stage_apply(b,stage,m,ligation_test_run("0005",errors))
  val rejected=case+ status of | GlyphPassReference() => true | GlyphPassApplied() => false
    | GlyphPassCapacity() => false | GlyphPassDomain() => false
  val row=glyph_run_query(r,0)
  val ok=rejected andalso ieq(applied,0) andalso ieq(matches,0) andalso ieq(row.core.glyph,5)
  val ()=glyph_run_dispose(r) and ()=glyph_substitution_stage_dispose(stage) and ()=buf_free(b)
in iadd(errors,if ok then 0 else 1) end
fun quota(m: !GlyphMetadata): int = let
  val b=substitution_stage_fixture("0001 0000 0000") val g=substitution_engine_parse(b)
  var errors: int=0 and remaining: int=4096
  val first=substitution_engine_take(glyph_substitution_lookup_budget(b,g,m,ligation_test_run("0005",errors),0,
    @{selection= @{kind=GlyphAll(),mask=0u},alternate=1},remaining),1,errors)
  val limit=iadd(isub(4096,remaining),1)
  val ()=glyph_run_dispose(first) and ()=ot_substitution_graph_dispose(g)
  val stage=substitution_stage_build(b,m,"ccmp") val ()=remaining := limit
  val+ ~SubStageResult(r,status,applied,matches)=glyph_substitution_stage_budget(b,stage,m,ligation_test_run("0005",errors),remaining)
  val rejected=case+ status of | GlyphPassCapacity() => true | GlyphPassApplied() => false
    | GlyphPassReference() => false | GlyphPassDomain() => false
  val row=glyph_run_query(r,0)
  val ok=rejected andalso ieq(applied,0) andalso ieq(matches,0) andalso ieq(row.core.glyph,5)
  val ()=glyph_run_dispose(r) and ()=glyph_substitution_stage_dispose(stage) and ()=buf_free(b)
in iadd(errors,if ok then 0 else 1) end
fun empty(m: !GlyphMetadata): int = let
  val b=substitution_stage_fixture("0001 0000 0000") val stage=substitution_stage_build(b,m,"kern")
  var errors: int=0 and remaining: int=0
  val+ ~SubStageResult(r,status,applied,matches)=glyph_substitution_stage_budget(b,stage,m,ligation_test_run("0005",errors),remaining)
  val row=glyph_run_query(r,0)
  val ok=ready(status) andalso ieq(applied,0) andalso ieq(matches,0) andalso ieq(row.core.glyph,5) andalso ieq(remaining,0)
  val ()=glyph_run_dispose(r) and ()=glyph_substitution_stage_dispose(stage) and ()=buf_free(b)
in iadd(errors,if ok then 0 else 1) end
implement substitution_stage_cases() = let val b=ligation_test_metadata_bytes() val m=ligation_test_metadata(b)
  val errors=basic(m)+rollback(m)+quota(m)+empty(m)
  val ()=glyph_metadata_dispose(m) and ()=buf_free(b)
in errors end
