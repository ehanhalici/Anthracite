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

(* Pinned-font oracle, independently decoded from raw font tables with struct.
   This checks topology/feature provenance, not shaped glyph output. *)
fun latin{kind:int}(domain: OtLayoutDomain(kind)): Buf = case+ domain of
  | OtSubstitution() => ot_fixture_words("0001 0001 0001 0001")
  | OtPositioning() => ot_fixture_words("0002 0006 0001 0001 0007 0001 0001")
fun arabic{kind:int}(domain: OtLayoutDomain(kind)): Buf = case+ domain of
  | OtSubstitution() => ot_fixture_words("0010 0004 0002 0004 000B 000C 0001 0001 000E 0001 0001 000F 0001 0001 0010 0001 0001 0017 0001 0004 0018 0001 000B 0019 0001 0003 001C 0001 000D 001D 0001 000D 001F 0001 000D 0021 0001 000D 0023 0001 000D 0025 0001 000D 0026 0001 000D 0027 0001 0005")
  | OtPositioning() => ot_fixture_words("0018 0000 0001 0000 0001 0001 0000 0002 0001 0000 0003 0001 0000 0004 0001 0000 0005 0001 0000 0006 0001 0000 0007 0001 0000 0008 0001 0000 0009 0001 0000 000A 0001 0000 000B 0001 0000 000C 0001 0000 000D 0001 0000 000E 0001 0000 000F 0001 0000 0010 0001 0000 0011 0001 0000 0012 0001 0001 0013 0001 0001 0014 0001 0001 0015 0001 0001 0016 0001 0001 0017 0001 0001")
fun expected{kind:int}(font: LayoutTestFont,domain: OtLayoutDomain(kind)): Buf = case+ font of
  | LayoutLatin() => latin(domain) | LayoutArabic() => arabic(domain)
fun owners {n:nat}{kind:int} .<n>. (n: int(n),p: !OtStagePlan(kind),b: !Buf,i: int,j: int,cursor: int): int =
  if n = 0 then 0 else let
    val mismatch=ine(ot_plan_feature(p,i,j),ot_fixture_read16(b,cursor))
  in iadd(if mismatch then 1 else 0,owners(n-1,p,b,i,iadd(j,1),iadd(cursor,2))) end
fun rows {n:nat}{kind:int} .<n>. (n: int(n),p: !OtStagePlan(kind),b: !Buf,i: int,cursor: int): int =
  if n = 0 then 0 else let
    val lookup=ot_fixture_read16(b,cursor)
    val size=ot_fixture_read16(b,iadd(cursor,2))
    val start=iadd(cursor,4)
    val rest=iadd(start,imul(size,2))
    val error: int=if ine(ot_plan_lookup(p,i),lookup) orelse ine(ot_plan_feature_count(p,i),size) then 1
      else owners(airlock_nat(size),p,b,i,0,start)
  in iadd(error,rows(n-1,p,b,iadd(i,1),rest)) end
implement layout_font_plan_check(p,font,domain) = let
  val b=expected(font,domain)
  val count=ot_fixture_read16(b,0)
  val errors: int=if ine(ot_plan_lookup_count(p),count) then 1 else rows(airlock_nat(count),p,b,0,2)
  val ()=buf_free(b)
in errors end
implement layout_font_script(font) = case+ font of
  | LayoutLatin() => layout_tag("latn") | LayoutArabic() => layout_tag("arab")
