#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "os/fs.sats"
staload "data_font/opentype_coverage.sats"
staload "data_font/gsub_ligature_types.sats"
staload "data_font/gsub_ligatures.sats"
staload "opentype_fixture.sats"
staload "font_fixture.sats"
staload "gsub_ligature_contracts.sats"

implement ligature_fixture() = ot_fixture_words("0001 0008 0001 000E 0001 0001 0001 0003 0008 000E 0016 0009 0002 0002 0008 0003 0002 0003 0007 0001")
fun input(): Buf = let
  val b=buf_make(16)
  val ()=buf_set32(b,0,99) and ()=buf_set32(b,1,1)
  val ()=buf_set32(b,2,2) and ()=buf_set32(b,3,3)
in b end
fun expect(b: !Buf,t: !GsubLigatures,v: !Buf,count: int,start: int,glyph: int,components: int): int = let
  val r=gsub_ligatures_match(b,t,v,count,start)
  val expected=igt(components,0)
in if (r.matched = expected) andalso ieq(r.glyph,glyph) andalso ieq(r.components,components) then 0 else 1 end
fun queries(b: !Buf,longest: int): int = case+ gsub_ligatures_parse(b,ot_fixture_span(b),10) of
  | ~LigaturesRejected(e) => 1 | ~LigaturesAccepted(t) => let
    val v=input()
    val errors=expect(b,t,v,4,1,longest,if ieq(longest,9) then 2 else 3)+
      expect(b,t,v,3,1,9,2)+expect(b,t,v,2,1,7,1)+expect(b,t,v,4,0,0,0)+
      expect(b,t,v,4,~1,0,0)+expect(b,t,v,4,4,0,0)+expect(b,t,v,5,1,0,0)
    val ()=buf_set32(v,2,4)
    val mismatch=expect(b,t,v,4,1,7,1)
    val ()=buf_free(v) and ()=gsub_ligatures_dispose(t)
  in errors+mismatch end
fun empty(): int = let
  val b=ot_fixture_words("0001 0008 0001 000E 0001 0001 0000 0000")
  val errors: int=case+ gsub_ligatures_parse(b,ot_fixture_span(b),1) of
    | ~LigaturesRejected(e) => 1 | ~LigaturesAccepted(t) => let
      val v=buf_make(4)
      val errors=expect(b,t,v,1,0,0,0)
      val ()=buf_free(v) and ()=gsub_ligatures_dispose(t)
    in errors end
  val ()=buf_free(b)
in errors end
implement ligature_test_priority() = let
  val b=ligature_fixture()
  val first=queries(b,9)
  val ()=ot_fixture_put16(b,16,14) and ()=ot_fixture_put16(b,18,8)
  val second=queries(b,8)
  val ()=buf_free(b)
in first+second+empty() end
