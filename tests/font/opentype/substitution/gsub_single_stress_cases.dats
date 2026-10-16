#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_reader.sats"
staload "data_font/opentype/tables/opentype_coverage.sats"
staload "data_font/opentype/substitution/gsub_single_types.sats"
staload "os/fs.sats"
staload "data_font/opentype/substitution/gsub_single.sats"
staload "font/opentype/tables/opentype_fixture.sats"
staload "font/resources/font_fixture.sats"
staload "font/opentype/substitution/gsub_single_contracts.sats"

fun array_fixture(): Buf = let
  val b=buf_make(131074)
  val ()=fixture_put16(b,8,2) and ()=fixture_put16(b,10,65534)
  val ()=fixture_put16(b,12,32764)
  val ()=fixture_put16(b,65542,1) and ()=fixture_put16(b,65544,32764)
  val ()=buf_set_len(b,131074)
in b end
fun rows {n:nat} .<n>. (n: int(n),b: !Buf,i: int): void =
  if n = 0 then () else let
    val ()=fixture_put16(b,iadd(14,imul(i,2)),isub(32763,i))
    val ()=fixture_put16(b,iadd(65546,imul(i,2)),i)
  in rows(n-1,b,iadd(i,1)) end
datatype QueryOracle = IdentityRange | ReverseArray
fun oracle(glyph: int,kind: QueryOracle): GsubSingleResult = case+ kind of
  | IdentityRange() => @{matched=ige(glyph,0) andalso ilt(glyph,WORD16_MAX_VALUE),glyph=glyph}
  | ReverseArray() => let val found=ige(glyph,0) andalso ilt(glyph,32764) in
    @{matched=found,glyph=if found then isub(32763,glyph) else glyph} end
fun queries {n:nat} .<n>. (n: int(n),b: !Buf,t: !GsubSingle,kind: QueryOracle,glyph: int,total: int): int =
  if n = 0 then total else let
    val expected=oracle(glyph,kind)
    val result=gsub_single_query(b,t,glyph)
    val ok=(expected.matched = result.matched) andalso ieq(expected.glyph,result.glyph)
  in queries(n-1,b,t,kind,iadd(glyph,1),iadd(total,if ok then 0 else 1)) end
fun parsed(b: !Buf,glyphs: int,kind: QueryOracle): int =
  case+ gsub_single_parse(b,ot_fixture_span(b),glyphs) of
  | ~SingleRejected(e) => 1 | ~SingleAccepted(t) => let
    val errors=queries(65538,b,t,kind,~1,0)
    val ()=gsub_single_dispose(t)
  in errors end
fun deltas {n:nat} .<n>. (n: int(n),b: !Buf,raw: int,total: int): int =
  if n = 0 then total else let
    val ()=ot_fixture_put16(b,4,raw)
    val error: int=if ieq(raw,WORD16_MAX_VALUE) then single_reject(b,ot_fixture_span(b),WORD16_MAX_VALUE)
      else single_expect(b,ot_fixture_span(b),WORD16_MAX_VALUE,0,raw)
  in deltas(n-1,b,iadd(raw,1),iadd(total,error)) end
implement single_test_stress() = let
  val b=array_fixture()
  val ()=rows(32764,b,0)
  val a=parsed(b,32764,ReverseArray())
  val ()=buf_free(b)
  val r=ot_fixture_words("0001 0006 0000 0002 0001 0000 FFFE 0000")
  val c=parsed(r,WORD16_MAX_VALUE,IdentityRange())
  val ()=buf_free(r)
  val d=ot_fixture_words("0001 0006 0000 0001 0001 0000")
  val e=deltas(WORD16_MODULUS,d,0,0)
  val ()=buf_free(d)
in a+c+e end
