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

fun checked(b: !Buf,caps: OtGdefCapabilities,expected: int): int =
  if ieq(expected,0) then layout_accept(b,OtSubstitution(),caps)
  else layout_reject(b,ot_fixture_span(b),OtSubstitution(),caps)
fun flags(raw: int,caps: OtGdefCapabilities,expected: int): int = let
  val b=layout_fixture()
  val ()=ot_fixture_put16(b,134,raw)
  val errors=checked(b,caps,expected)
  val ()=buf_free(b)
in errors end
fun filtering(caps: OtGdefCapabilities,expected: int): int = let
  val b=layout_fixture()
  val ()=ot_fixture_put16(b,134,16)
  val ()=ot_fixture_put16(b,138,10)
  val ()=ot_fixture_put16(b,140,0)
  val errors=checked(b,caps,expected)
  val ()=buf_free(b)
in errors end
fun kinds {n:nat} .<n>. (n: int(n),b: !Buf,code: int): int =
  if n = 0 then 0 else let
    val ()=ot_fixture_put16(b,132,code)
    val span=ot_fixture_span(b)
    val caps= @{classes=false,attachments=false,markSets=0}
    (* This fixture has only primitive placeholders, not extension headers. *)
    val sub: int=if ige(code,1) andalso ile(code,8) andalso ine(code,7) then layout_accept(b,OtSubstitution(),caps)
      else layout_reject(b,span,OtSubstitution(),caps)
    val pos: int=if ige(code,1) andalso ile(code,8) then layout_accept(b,OtPositioning(),caps)
      else layout_reject(b,span,OtPositioning(),caps)
  in iadd(iadd(sub,pos),kinds(n-1,b,iadd(code,1))) end
implement layout_test_flags() = let
  val absent= @{classes=false,attachments=false,markSets=0}
  val classes= @{classes=true,attachments=false,markSets=0}
  val attached= @{classes=true,attachments=true,markSets=0}
  val sets= @{classes=false,attachments=false,markSets=1}
  val b=layout_fixture()
  val errors=kinds(11,b,0)
  val ()=buf_free(b)
in errors+flags(1,absent,0)+flags(2,absent,1)+flags(2,classes,0)+
  flags(4,absent,1)+flags(8,absent,1)+flags(8,classes,0)+flags(256,classes,1)+
  flags(256,attached,0)+filtering(absent,1)+filtering(sets,0) end
