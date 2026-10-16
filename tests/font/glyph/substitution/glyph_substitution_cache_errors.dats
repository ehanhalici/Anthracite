#include "font/glyph/substitution/glyph_substitution_cache_test.hats"
fun check(first: string,second: string,third: string,expected: int): int = let
  val a=ot_fixture_words(first) and c=ot_fixture_words(second) and d=ot_fixture_words(third)
  val b=substitution_cache_fixture(a,c,d)
  val error=case+ substitution_cache_parse(b) of | ~SubstitutionGraphRejected(e) => expected
    | ~SubstitutionGraphAccepted(g) => let val ()=ot_substitution_graph_dispose(g) in isub(1,expected) end
  val ()=buf_free(a) and ()=buf_free(c) and ()=buf_free(d) and ()=buf_free(b)
in error end
implement substitution_cache_errors() =
  check("0005 0000 0000","0006 0000 0000","0007 0000 0000",1)
  +check("0005 0000 0001 0008 0003 0001 0001 000C 0000 0003 0001 0001 0005","0001 0000 0000","0008 0000 0000",0)
  +check("0001 0000 0001 0008 0001 0006 0001 0001 0001 0005","0005 0000 0001 0008 FFFF","0008 0000 0000",0)
  +check("0007 0000 0002 000A 001E 0001 0001 0000 0008 0001 0006 0001 0001 0001 0005 0001 0008 0000 0008 0001 000A 0000 0000 0001 000B 0001 0001 000A","0001 0000 0000","0008 0000 0000",0)
