#include "font/native/shape/native_shape_test.hats"
fun signed(value: int): int = if ige(value,WORD16_SIGN_BIT) then isub(value,WORD16_MODULUS) else value
fun row(p: !GlyphPositioned(1),node: int,expected: !Buf,index: int): int = let
  val v=glyph_position_query(p,node) and at=imul(index,8)
  val ok=ieq(v.core.glyph,ot_fixture_read16(expected,at))
    andalso ieq(v.position.xAdvance,ot_fixture_read16(expected,iadd(at,2)))
    andalso ieq(v.position.xOffset,signed(ot_fixture_read16(expected,iadd(at,4))))
    andalso ieq(v.position.yOffset,signed(ot_fixture_read16(expected,iadd(at,6))))
  val ()=if ok then () else println!("event=native_shape_oracle index=",index," glyph=",v.core.glyph,
    " advance=",v.position.xAdvance," x=",v.position.xOffset," y=",v.position.yOffset)
in if ok then 0 else 1 end
fun rows{n:nat} .<n>. (left: int(n),p: !GlyphPositioned(1),expected: !Buf,index: int,node: int): int =
  if left = 0 then (if ieq(node,~1) then 0 else 1) else let val v=glyph_position_query(p,node)
  in row(p,node,expected,index)+rows(left-1,p,expected,iadd(index,1),v.links.next) end
fun check(p: !GlyphPositioned(1),words: string): int = let
  val expected=ot_fixture_words(words) val count=idiv(isub(buf_len(expected),8),8) val meta=glyph_position_meta(p)
  val errors=if ieq(meta.live,count) then rows(airlock_nat(count),p,expected,0,meta.head) else 1
  val ()=buf_free(expected)
in errors end
fun shaped(face: !SfntFace,cache: !NativeShapeCache,plan: !NativeShapePlan,data: !NativeShapeData,
  text: !NativeShapeText,words: string): int = let val+ SfntFace(b,info)=face
in case+ native_shape_run(b,info,cache,plan,data,text,@{before=BoundaryNone(),after=BoundaryNone()},@{xPpem=16,yPpem=16}) of
  | ~NativeShapeRejected(e) => 1 | ~NativeShapeAccepted(p) => let val errors=check(p,words)
    val ()=glyph_position_dispose(p) in errors end end
implement native_test_example(face,cache,plan,data,normalization,mcm,source,words) = let
  val bytes=nominal_test_bytes(source) val text=nominal_test_decode(bytes)
  val+ SfntFace(b,info)=face
  val errors=case+ native_shape_text_parse(b,info,plan,normalization,mcm,text) of | ~NativeTextRejected(e) => 1
    | ~NativeTextAccepted(view) => let val result=shaped(face,cache,plan,data,view,words)
      val ()=native_shape_text_dispose(view) in result end
  val ()=scalar_dispose(text) and ()=buf_free(bytes)
in errors end
