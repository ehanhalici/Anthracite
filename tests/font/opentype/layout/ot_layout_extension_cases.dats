#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "font/opentype/tables/opentype_fixture.sats"
staload "font/opentype/layout/ot_layout_contracts.sats"
val caps= @{classes=false,attachments=false,markSets=0}
fun fixture(): Buf = ot_fixture_words(
  "0001 0000 000A 000C 000E 0000 0000 0001 0004 0007 0000 0002 000A 0014 0001 0001 0000 0008 0001 0001 0001 0000 0008 0001")
fun valid(): int = let
  val b=fixture()
  val a=layout_accept(b,OtSubstitution(),caps)
  val ()=ot_fixture_put16(b,18,9)
  val p=layout_accept(b,OtPositioning(),caps)
  val ()=ot_fixture_put16(b,26,10)
  val alias=layout_accept(b,OtPositioning(),caps)
  val ()=buf_free(b)
in a+p+alias end
fun changed{kind:int}(domain: OtLayoutDomain(kind),outer: int,at: int,value: int): int = let
  val b=fixture()
  val ()=ot_fixture_put16(b,18,outer)
  val ()=ot_fixture_put16(b,at,value)
  val errors=layout_reject(b,ot_fixture_span(b),domain,caps)
  val ()=buf_free(b)
in errors end
fun cuts{n:nat} .<n>. (n: int(n),b: !Buf,length: int): int =
  if n = 0 then 0 else layout_reject(b,@{offset=8,length=length},OtSubstitution(),caps)+cuts(n-1,b,iadd(length,1))
implement layout_test_extensions() = let
  val b=fixture()
  val truncated=cuts(airlock_nat(isub(buf_len(b),8)),b,0)
  val ()=buf_free(b)
in valid()+truncated+changed(OtSubstitution(),7,40,2)+changed(OtSubstitution(),7,40,7)+
  changed(OtSubstitution(),7,38,2)+changed(OtSubstitution(),7,44,0)+
  changed(OtSubstitution(),7,44,9)+changed(OtSubstitution(),7,42,WORD16_SIGN_BIT)+
  changed(OtPositioning(),9,40,2)+changed(OtPositioning(),9,40,9) end
