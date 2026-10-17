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

fun miss(b: !Buf,t: !GsubSingle,glyph: int): int = let val r=gsub_single_query(b,t,glyph) in
  if not(r.matched) andalso ieq(r.glyph,glyph) then 0 else 1 end
fun queries(b: !Buf,t: !GsubSingle): int =
  miss(b,t,~1)+miss(b,t,WORD16_MAX_VALUE)+miss(b,t,WORD16_MODULUS)+miss(b,t,SIGNED_INT_MAX_VALUE)
fun expected(s: string,glyphs: int,input: int,output: int): int = let
  val b=ot_fixture_words(s)
  val errors=single_expect(b,ot_fixture_span(b),glyphs,input,output)
  val ()=buf_free(b)
in errors end
fun empty(): int = let
  val b=ot_fixture_words("0002 0006 0000 0001 0000")
  val errors: int=case+ gsub_single_parse(b,ot_fixture_span(b),8) of
    | ~SingleRejected(e) => 1 | ~SingleAccepted(t) => let
      val errors=queries(b,t)+miss(b,t,0)
      val ()=gsub_single_dispose(t)
    in errors end
  val ()=buf_free(b)
in errors end
implement single_test_formats() = empty()+
  expected("0001 0006 0001 0001 0003 0000 0002 0004",8,4,5)+
  expected("0001 0006 FFFE 0002 0002 0002 0004 0000 0008 000A 0003",12,2,0)+
  expected("0001 0006 FFFE 0001 0002 0000 0002",WORD16_MAX_VALUE,0,65534)+
  expected("0001 0006 FFFE 0001 0002 0000 0002",WORD16_MAX_VALUE,2,0)+
  expected("0001 0006 0002 0001 0001 FFFE",WORD16_MAX_VALUE,65534,0)+
  expected("0001 0006 8000 0001 0001 8000",WORD16_MAX_VALUE,WORD16_SIGN_BIT,0)+
  expected("0001 0006 7FFF 0001 0001 FFFE",WORD16_MAX_VALUE,65534,32765)+
  expected("0001 0006 0000 0001 0001 0000",1,0,0)+
  expected("0002 000C 0003 0007 0000 0005 0001 0003 0001 0003 0006",8,3,0)+
  expected("0002 000E 0004 0004 0003 0002 0001 0002 0002 0000 0001 0000 0003 0004 0002",8,4,1)
