#include "font/glyph/substitution/glyph_substitution_engine_test.hats"
fun child(index: int,count: int): Buf =
  if ieq(iadd(index,1),count) then ot_fixture_words("0001 0000 0001 0008 0001 0006 000A 0001 0001 0005")
  else let val b=ot_fixture_words("0005 0000 0001 0008 0003 0001 0001 000C 0000 0000 0001 0001 0005")
    val ()=ot_fixture_put16(b,18,iadd(index,1))
  in b end
fun append{n:nat} .<n>. (left: int(n),b: &Buf >> Buf,index: int,count: int): void =
  if left = 0 then () else let
    val payload=child(index,count)
    val offset=isub(isub(buf_len(b),8),14)
    val ()=ot_fixture_put16(b,iadd(16,imul(index,2)),offset)
    val ()=buf_append_at(b,payload,8,isub(buf_len(payload),8))
    val ()=buf_free(payload)
  in append(left-1,b,iadd(index,1),count) end
fun fixture(count: int): Buf = let
  var b: Buf=ot_fixture_words("0001 0000 000A 000C 000E 0000 0000 0000")
  val ()=ot_fixture_put16(b,14,count)
  val ()=buf_resize(b,iadd(24,imul(count,2))) and ()=buf_set_len(b,iadd(24,imul(count,2)))
  val ()=append(airlock_nat(count),b,0,count)
in b end
implement substitution_engine_stress() = let var errors: int=0
  val mb=ligation_test_metadata_bytes() val m=ligation_test_metadata(mb)
  val b=fixture(2048) val g=substitution_engine_parse(b)
  val run=substitution_engine_take(glyph_substitution_lookup(b,g,m,ligation_test_run("0005",errors),0,
    @{selection= @{kind=GlyphAll(),mask=0u},alternate=1}),1,errors)
  val a=glyph_run_query(run,0)
  val ok=ieq(a.core.glyph,15) andalso ieq(a.core.sourceStart,0) andalso ieq(a.core.sourceEnd,2)
  val ()=glyph_run_dispose(run) and ()=ot_substitution_graph_dispose(g) and ()=buf_free(b)
  val ()=glyph_metadata_dispose(m) and ()=buf_free(mb)
in iadd(errors,if ok then 0 else 1) end
