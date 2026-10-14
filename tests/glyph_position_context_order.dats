#include "glyph_position_context_test.hats"
fun check(root: string,expected: int): int = let
  var errors: int=0
  val b=position_context_fixture(root,"0001 0000 0001 0008 0001 0008 0001 0020 0001 0001 0007",
    "0004 0000 0001 0008 0001 000C 0012 0001 0018 0024 0001 0001 0007 0001 0001 0005 0001 0000 0006 0001 000A 0014 0001 0004 0001 0064 00C8")
  val m=position_test_metadata(b) val g=position_context_parse(b,m)
  val p=position_test_take(glyph_position_lookup_graph_lookup(b,g,m,position_test_run("0005 0007",errors),0,
    position_test_all(),PositionLTR()),2,1,errors)
  val checked=position_test_values(p,1,0,0,expected,180)
  val ()=glyph_position_dispose(p) and ()=ot_position_graph_dispose(g)
  val ()=glyph_metadata_dispose(m) and ()=buf_free(b)
in iadd(errors,checked) end
implement position_context_order() =
  check("0007 0000 0001 0008 0003 0002 0002 0012 0018 0001 0001 0001 0002 0001 0001 0005 0001 0001 0007",90)
  +check("0007 0000 0001 0008 0003 0002 0002 0012 0018 0001 0002 0001 0001 0001 0001 0005 0001 0001 0007",122)
