#include "font/glyph/substitution/glyph_substitution_cache_test.hats"
fun inspect(g: !OtSubstitutionGraph,which: ContextFixture): int = let
  val+ OtSubstitutionGraph(font,glyphs,limits,entries)=g
  val+ OtSubstitutionGraphEntries(pf,gc | rows,count,filled)=entries
  val chained=case+ context_fixture_mode(which) of | ContextPlain() => false | ContextChained() => true
  val ok=ieq(font,3) andalso ieq(glyphs,128) andalso ieq(count,3) andalso ieq(limits.input,2)
    andalso ieq(limits.back,if chained then 2 else 0) andalso ieq(limits.look,if chained then 2 else 0)
in if ok then 0 else 1 end
fun check(which: ContextFixture): int = let
  val p=context_fixture(which)
  val words=case+ context_fixture_mode(which) of | ContextPlain() => "0005 0000 0001 0008"
    | ContextChained() => "0006 0000 0001 0008"
  var root: Buf=ot_fixture_words(words)
  val ()=buf_append_at(root,p,8,isub(buf_len(p),8))
  val second=ot_fixture_words("0001 0000 0001 0008 0001 0006 0001 0001 0001 0005")
  val third=ot_fixture_words("0001 0000 0000")
  val b=substitution_cache_fixture(root,second,third)
  val error=case+ substitution_cache_parse(b) of | ~SubstitutionGraphRejected(e) => 1
    | ~SubstitutionGraphAccepted(g) => let val checked=inspect(g,which) val ()=ot_substitution_graph_dispose(g) in checked end
  val ()=buf_free(b) and ()=buf_free(root) and ()=buf_free(p) and ()=buf_free(second) and ()=buf_free(third)
in error end
implement substitution_cache_contexts() = check(PlainGlyph())+check(PlainClass())+check(PlainCoverage())
  +check(ChainGlyph())+check(ChainClass())+check(ChainCoverage())
