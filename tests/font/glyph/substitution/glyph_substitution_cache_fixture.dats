#include "font/glyph/substitution/glyph_substitution_cache_test.hats"
fun append(b: &Buf >> Buf,child: !Buf,index: int): void = let
  val offset=isub(buf_len(b),8)
  val ()=ot_fixture_put16(b,iadd(16,imul(index,2)),isub(offset,14))
in buf_append_at(b,child,8,isub(buf_len(child),8)) end
implement substitution_cache_fixture(first,second,third) = let
  var b: Buf=ot_fixture_words("0001 0000 000A 000C 000E 0000 0000 0003 0000 0000 0000")
  val ()=append(b,first,0) and ()=append(b,second,1) and ()=append(b,third,2)
in b end
implement substitution_cache_parse(b) = case+ ot_layout_parse(b,ot_fixture_span(b),OtSubstitution(),
  @{classes=true,attachments=true,markSets=0}) of
  | ~LayoutRejected(e) => SubstitutionGraphRejected(e) | ~LayoutAccepted(t) => let
    val result=ot_substitution_graph_parse(b,t,3,128)
    val ()=ot_layout_dispose(t)
  in result end
