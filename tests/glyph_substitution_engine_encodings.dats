#include "glyph_substitution_engine_test.hats"
fun fixture(which: ContextFixture): Buf = let
  val p=context_fixture(which)
  val words=case+ context_fixture_mode(which) of | ContextPlain() => "0005 0008 0001 0008"
    | ContextChained() => "0006 0008 0001 0008"
  var root: Buf=ot_fixture_words(words)
  val ()=buf_append_at(root,p,8,isub(buf_len(p),8))
  val a=ot_fixture_words("0001 0000 0001 0008 0001 0006 000A 0001 0001 0005")
  val c=ot_fixture_words("0001 0000 0001 0008 0001 0006 000A 0001 0001 0006")
  val b=substitution_cache_fixture(root,a,c)
  val ()=buf_free(p) and ()=buf_free(root) and ()=buf_free(a) and ()=buf_free(c)
in b end
fun check(which: ContextFixture,m: !GlyphMetadata): int = let
  var errors: int=0
  val b=fixture(which) val g=substitution_engine_parse(b)
  val input=ligation_test_run("0001 0002 0005 000C 0006 0007 0008",errors)
  val r=substitution_engine_take(glyph_substitution_lookup(b,g,m,input,0,
    @{selection= @{kind=GlyphAll(),mask=0u},alternate=1}),1,errors)
  val a=glyph_run_query(r,2) and c=glyph_run_query(r,4) and mark=glyph_run_query(r,3)
  val ok=ieq(a.core.glyph,15) andalso ieq(c.core.glyph,16) andalso ieq(mark.core.glyph,12)
    andalso ieq(a.core.sourceStart,4) andalso ieq(c.core.sourceStart,8)
  val ()=glyph_run_dispose(r) and ()=ot_substitution_graph_dispose(g) and ()=buf_free(b)
in iadd(errors,if ok then 0 else 1) end
implement substitution_engine_encodings() = let
  val b=ligation_test_metadata_bytes() val m=ligation_test_metadata(b)
  val errors=check(PlainGlyph(),m)+check(PlainClass(),m)+check(PlainCoverage(),m)
    +check(ChainGlyph(),m)+check(ChainClass(),m)+check(ChainCoverage(),m)
  val ()=glyph_metadata_dispose(m) and ()=buf_free(b)
in errors end
