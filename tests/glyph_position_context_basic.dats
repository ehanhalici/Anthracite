#include "glyph_position_context_test.hats"
fun check(root: string,words: string,count: int,second: int): int = let
  var errors: int=0
  val b=position_context_fixture(root,"0001 0000 0001 0008 0001 0008 0001 0020 0001 0001 0005",
    "0001 0000 0001 0008 0001 0008 0001 0040 0001 0001 0006")
  val m=position_test_metadata(b)
  val g=position_context_parse(b,m)
  val p=position_test_take(glyph_position_lookup_graph_lookup(b,g,m,position_test_run(words,errors),0,
    position_test_all(),PositionLTR()),count,1,errors)
  val checked=position_test_values(p,0,1024,0,32,0)+position_test_values(p,second,0,0,64,0)
  val ()=glyph_position_dispose(p) and ()=ot_position_graph_dispose(g)
  val ()=glyph_metadata_dispose(m) and ()=buf_free(b)
in iadd(errors,checked) end
implement position_context_basic() =
  check("0007 0000 0001 0008 0003 0002 0002 0012 0018 0001 0002 0000 0001 0001 0001 0005 0001 0001 0006","0005 0006",2,1)
  +check("0009 0000 0001 0008 0001 0007 0000 0008 0003 0002 0002 0012 0018 0001 0002 0000 0001 0001 0001 0005 0001 0001 0006","0005 0006",2,1)
  +check("0007 0008 0001 0008 0003 0002 0002 0012 0018 0001 0002 0000 0001 0001 0001 0005 0001 0001 0006","0005 0007 0006",3,2)
