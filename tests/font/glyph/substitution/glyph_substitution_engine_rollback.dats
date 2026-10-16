#include "font/glyph/substitution/glyph_substitution_engine_test.hats"
fun check(m: !GlyphMetadata,quota: int): int = let var errors: int=0 and remaining: int=quota
  val b=substitution_engine_fixture("0005 0000 0001 0008 0003 0002 0002 0012 0018 0000 0001 0003 0002 0001 0001 0005 0001 0001 0006",
    "0002 0000 0001 0008 0001 0008 0001 000E 0001 0001 0005 0003 0007 0008 0009",
    "0005 0000 0001 0008 0003 0001 0001 000C 0000 0002 0001 0001 0006")
  val g=substitution_engine_parse(b)
  val+ ~GlyphPassResult(r,status,visited,matches)=glyph_substitution_lookup_budget(b,g,m,ligation_test_run("0005 0006",errors),0,
    @{selection= @{kind=GlyphAll(),mask=0u},alternate=1},remaining)
  val rejected=case+ status of | GlyphPassReference() => ieq(quota,4096) | GlyphPassCapacity() => ieq(quota,24)
    | GlyphPassApplied() => false | GlyphPassDomain() => false
  val a=glyph_run_query(r,0) and c=glyph_run_query(r,1) and meta=glyph_run_meta(r)
  val ok=rejected andalso ieq(visited,0) andalso ieq(matches,0) andalso ieq(meta.used,2) andalso ieq(meta.live,2)
    andalso ieq(a.core.glyph,5) andalso ieq(c.core.glyph,6) andalso ieq(a.links.next,1)
  val ()=glyph_run_dispose(r) and ()=ot_substitution_graph_dispose(g) and ()=buf_free(b)
in iadd(errors,if ok then 0 else 1) end
implement substitution_engine_rollback() = let
  val b=ligation_test_metadata_bytes() val m=ligation_test_metadata(b)
  val errors=check(m,4096)+check(m,24)
  val ()=glyph_metadata_dispose(m) and ()=buf_free(b)
in errors end
