#include "font/glyph/position/glyph_position_context_test.hats"
fun context(index: int): Buf = let
  val b=ot_fixture_words("0007 0000 0001 0008 0003 0001 0001 000C 0000 0000 0001 0001 0005")
  val ()=ot_fixture_put16(b,18,index)
in b end
fun child(index: int,count: int): Buf =
  if ieq(iadd(index,1),count) then ot_fixture_words("0001 0000 0001 0008 0001 0008 0001 0020 0001 0001 0005")
  else context(iadd(index,1))
fun append{n:nat} .<n>. (left: int(n),b: &Buf >> Buf,index: int,count: int): void =
  if left = 0 then () else let
    val child=child(index,count)
    val offset=isub(isub(buf_len(b),8),14)
    val ()=ot_fixture_put16(b,iadd(16,imul(index,2)),offset)
    val ()=buf_append_at(b,child,8,isub(buf_len(child),8))
    val ()=buf_free(child)
  in append(left-1,b,iadd(index,1),count) end
fun fixture(count: int): Buf = let
  var b: Buf=ot_fixture_words("0001 0000 000A 000C 000E 0000 0000 0000")
  val ()=ot_fixture_put16(b,14,count)
  val ()=buf_resize(b,iadd(24,imul(count,2)))
  val ()=buf_set_len(b,iadd(24,imul(count,2)))
  val ()=append(airlock_nat(count),b,0,count)
  val length=isub(buf_len(b),8)
  val g=position_test_fixture("",TestBaseClasses())
  val ()=buf_set32(b,0,length)
  val ()=buf_append_at(b,g,8,isub(buf_len(g),8))
  val ()=buf_free(g)
in b end
implement position_context_stress() = let
  var errors: int=0
  val b=fixture(2048) val m=position_test_metadata(b) val g=position_context_parse(b,m)
  val p=position_test_take(glyph_position_lookup_graph_lookup(b,g,m,position_test_run("0005",errors),0,
    position_test_all(),PositionLTR()),1,1,errors)
  val checked=position_test_values(p,0,1024,0,32,0)
  val ()=glyph_position_dispose(p) and ()=ot_position_graph_dispose(g)
  val ()=glyph_metadata_dispose(m) and ()=buf_free(b)
in iadd(errors,checked) end
