#include "glyph_substitution_engine_test.hats"
fun check(m: !GlyphMetadata): int = let var errors: int=0
  val b=substitution_engine_fixture("0005 0000 0002 000A 0020 0003 0002 0000 000A 0010 0001 0001 0005 0001 0001 0006 0003 0002 0002 0012 0018 0001 0002 0000 0001 0001 0001 0005 0001 0001 0006",
    "0001 0000 0001 0008 0001 0006 000A 0001 0001 0005","0001 0000 0000")
  val g=substitution_engine_parse(b)
  val r=substitution_engine_take(glyph_substitution_lookup(b,g,m,ligation_test_run("0005 0006",errors),0,
    @{selection= @{kind=GlyphAll(),mask=0u},alternate=1}),1,errors)
  val a=glyph_run_query(r,0) and c=glyph_run_query(r,1)
  val ok=ieq(a.core.glyph,5) andalso ieq(c.core.glyph,6)
  val ()=glyph_run_dispose(r) and ()=ot_substitution_graph_dispose(g) and ()=buf_free(b)
in iadd(errors,if ok then 0 else 1) end
implement substitution_engine_priority() = let val b=ligation_test_metadata_bytes() val m=ligation_test_metadata(b)
  val errors=check(m)
  val ()=glyph_metadata_dispose(m) and ()=buf_free(b)
in errors end
