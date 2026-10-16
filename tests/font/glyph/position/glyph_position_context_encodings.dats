#include "font/glyph/position/glyph_position_context_test.hats"
fun check(which: ContextFixture): int = let
  var errors: int=0
  val b=position_context_program(which) val m=position_test_metadata(b) val g=position_context_parse(b,m)
  val p=position_test_take(glyph_position_lookup_graph_lookup(b,g,m,position_test_run("0001 0002 0005 0006 0007 0008",errors),0,
    position_test_all(),PositionLTR()),6,1,errors)
  val checked=position_test_values(p,2,0,0,32,0)+position_test_values(p,3,0,0,64,0)
  val ()=glyph_position_dispose(p) and ()=ot_position_graph_dispose(g)
  val ()=glyph_metadata_dispose(m) and ()=buf_free(b)
in iadd(errors,checked) end
implement position_context_encodings() = check(PlainGlyph())+check(PlainClass())+check(PlainCoverage())
  +check(ChainGlyph())+check(ChainClass())+check(ChainCoverage())
