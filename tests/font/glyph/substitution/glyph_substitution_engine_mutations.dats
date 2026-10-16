#include "font/glyph/substitution/glyph_substitution_engine_test.hats"
fun multiple(m: !GlyphMetadata): int = let var errors: int=0
  val b=substitution_engine_fixture("0005 0000 0001 0008 0003 0002 0002 0012 0018 0000 0001 0003 0002 0001 0001 0005 0001 0001 0006",
    "0002 0000 0001 0008 0001 0008 0001 000E 0001 0001 0005 0003 0007 0008 0009",
    "0001 0000 0001 0008 0001 0006 000A 0001 0001 0006")
  val g=substitution_engine_parse(b)
  val r=substitution_engine_take(glyph_substitution_lookup(b,g,m,ligation_test_run("0005 0006",errors),0,
    @{selection= @{kind=GlyphAll(),mask=0u},alternate=1}),1,errors)
  val a=glyph_run_query(r,0) and c=glyph_run_query(r,2) and d=glyph_run_query(r,3) and last=glyph_run_query(r,1)
  val meta=glyph_run_meta(r)
  val ok=ieq(meta.live,4) andalso ieq(a.core.glyph,7) andalso ieq(c.core.glyph,8) andalso ieq(d.core.glyph,9)
    andalso ieq(last.core.glyph,16) andalso ieq(a.links.next,2) andalso ieq(c.links.next,3) andalso ieq(d.links.next,1)
    andalso ieq(c.core.sourceStart,0) andalso ieq(c.core.sourceEnd,2) andalso ieq(last.core.sourceStart,2)
  val ()=glyph_run_dispose(r) and ()=ot_substitution_graph_dispose(g) and ()=buf_free(b)
in iadd(errors,if ok then 0 else 1) end
fun ligature(m: !GlyphMetadata): int = let var errors: int=0
  val b=substitution_engine_fixture("0005 0000 0001 0008 0003 0004 0002 0016 001C 0022 0028 0001 0001 0002 0002 0001 0001 0005 0001 0001 0006 0001 0001 0007 0001 0001 0008",
    "0004 0000 0001 0008 0001 0008 0001 000E 0001 0001 0006 0001 0004 000E 0002 0007",
    "0001 0000 0001 0008 0001 0006 000A 0001 0001 0008")
  val g=substitution_engine_parse(b)
  val r=substitution_engine_take(glyph_substitution_lookup(b,g,m,ligation_test_run("0005 0006 0007 0008",errors),0,
    @{selection= @{kind=GlyphAll(),mask=0u},alternate=1}),1,errors)
  val owner=glyph_run_query(r,1) and last=glyph_run_query(r,3) and meta=glyph_run_meta(r)
  val ok=ieq(meta.live,3) andalso ieq(owner.core.glyph,14) andalso ieq(last.core.glyph,18)
    andalso ieq(owner.links.next,3) andalso ieq(owner.core.sourceStart,2) andalso ieq(owner.core.sourceEnd,6)
  val ()=glyph_run_dispose(r) and ()=ot_substitution_graph_dispose(g) and ()=buf_free(b)
in iadd(errors,if ok then 0 else 1) end
implement substitution_engine_mutations() = let
  val b=ligation_test_metadata_bytes() val m=ligation_test_metadata(b)
  val errors=multiple(m)+ligature(m)
  val ()=glyph_metadata_dispose(m) and ()=buf_free(b)
in errors end
