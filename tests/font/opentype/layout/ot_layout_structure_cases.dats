#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "os/fs.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/layout/ot_layout_parse.sats"
staload "data_font/opentype/layout/ot_layout_tags.sats"
staload "data_font/opentype/layout/ot_layout_plan.sats"
staload "data_font/opentype/layout/ot_layout_feature_set.sats"
staload "data_font/opentype/layout/ot_layout_language.sats"
staload "font/opentype/tables/opentype_fixture.sats"
staload "font/opentype/layout/ot_layout_contracts.sats"

val caps= @{classes=false,attachments=false,markSets=0}
fun changed(at: int,value: int): int = let
  val b=layout_fixture()
  val ()=ot_fixture_put16(b,at,value)
  val errors=layout_reject(b,ot_fixture_span(b),OtSubstitution(),caps)
  val ()=buf_free(b)
in errors end
fun cuts {n:nat} .<n>. (n: int(n),b: !Buf,length: int): int =
  if n = 0 then 0 else layout_reject(b,@{offset=8,length=length},OtSubstitution(),caps)+cuts(n-1,b,iadd(length,1))
fun small(s: string): int = let val b=ot_fixture_words(s)
  val errors=layout_accept(b,OtSubstitution(),caps)+layout_accept(b,OtPositioning(),caps)
  val ()=buf_free(b) in errors end
fun outside(b: !Buf): int =
  layout_reject(b,@{offset= ~1,length=172},OtSubstitution(),caps)+
  layout_reject(b,@{offset=8,length=SIGNED_INT_MAX_VALUE},OtSubstitution(),caps)+
  layout_reject(b,@{offset=SIGNED_INT_MAX_VALUE,length=1},OtSubstitution(),caps)
fun versions(): int = let
  val b=ot_fixture_words("0001 0001 000E 0010 0012 0000 0001 0000 0000 0000")
  val errors=layout_reject(b,ot_fixture_span(b),OtSubstitution(),caps)
  val ()=buf_free(b)
in errors+changed(0,2)+changed(2,2) end
implement layout_test_structure() = let
  val b=layout_fixture()
  val errors=layout_accept(b,OtSubstitution(),caps)+layout_accept(b,OtPositioning(),caps)+
    cuts(airlock_nat(isub(buf_len(b),8)),b,0)+outside(b)
  val ()=buf_free(b)
in errors+versions()+small("0001 0000 000A 000C 000E 0000 0000 0000")+
  small("0001 0001 000E 0010 0012 0000 0000 0000 0000 0000")+
  changed(4,0)+changed(6,9)+changed(8,172)+changed(12,0)+changed(16,2)+
  changed(18,16705)+changed(20,0)+changed(24,0)+changed(24,3)+
  changed(38,1)+changed(42,0)+changed(44,1)+changed(46,4)+changed(50,4)+
  changed(72,25)+changed(94,WORD16_MAX_VALUE)+changed(96,4)+changed(66,WORD16_MAX_VALUE)+
  changed(124,0)+changed(132,0)+changed(134,32)+changed(136,WORD16_MAX_VALUE)+changed(138,7) end
