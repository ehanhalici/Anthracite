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
fun error_code(reason: OtErrorReason): int = case+ reason of
  | OtBounds() => 1 | OtFormat() => 2 | OtGlyphDomain() => 3 | OtOrder() => 4
  | OtCoverageIndex() => 5 | OtPadding() => 6 | OtReference() => 7
  | OtUnsupported() => 8 | OtCapacity() => 9
fun cause(s: string,glyphs: int,reason: OtErrorReason,offset: int): int = let
  val b=ot_fixture_words(s)
  val errors: int=case+ gsub_single_parse(b,ot_fixture_span(b),glyphs) of
    | ~SingleAccepted(t) => let val ()=gsub_single_dispose(t) in 1 end
    | ~SingleRejected(e) => if ieq(error_code(e.reason),error_code(reason)) andalso ieq(e.offset,offset) then 0 else 1
  val ()=buf_free(b)
in errors end
fun causes(): int =
  cause("0003 0006 0000 0001 0000",8,OtFormat(),8)+
  cause("0001 0000 0000 0001 0000",8,OtBounds(),8)+
  cause("0001 0006 0004 0001 0001 0004",8,OtGlyphDomain(),8)+
  cause("0002 000A 0002 0001 0002 0001 0003 0000 0001 0002",8,OtCoverageIndex(),8)+
  cause("0002 000A 0002 0001 0002 0001 0002 0001 0001",8,OtOrder(),18)

fun bad(s: string,glyphs: int): int = let val b=ot_fixture_words(s)
  val errors=single_reject(b,ot_fixture_span(b),glyphs)
  val ()=buf_free(b)
in errors end
fun cuts {n:nat} .<n>. (n: int(n),b: !Buf,length: int): int =
  if n = 0 then 0 else single_reject(b,@{offset=8,length=length},8)+cuts(n-1,b,iadd(length,1))
fun truncations(s: string): int = let
  val b=ot_fixture_words(s)
  val errors=cuts(airlock_nat(isub(buf_len(b),8)),b,0)
  val ()=buf_free(b)
in errors end
fun outside(): int = let
  val b=ot_fixture_words("0001 0006 0001 0001 0001 0000")
  val s=ot_fixture_span(b)
  val errors=single_reject(b,s,0)+single_reject(b,s,WORD16_MODULUS)+
    single_reject(b,@{offset= ~1,length=12},8)+single_reject(b,@{offset=8,length=SIGNED_INT_MAX_VALUE},8)+
    single_reject(b,@{offset=SIGNED_INT_MAX_VALUE,length=1},8)
  val ()=buf_free(b)
in errors end
implement single_test_mutations() = outside()+causes()+
  truncations("0001 0006 0001 0001 0003 0000 0002 0004")+
  truncations("0002 000C 0003 0007 0000 0005 0001 0003 0001 0003 0006")+
  bad("0003 0006 0000 0001 0000",8)+bad("0001 0000 0000 0001 0000",8)+
  bad("0001 0004 0000 0001 0000",8)+bad("0001 FFFF 0000 0001 0000",8)+
  bad("0001 0006 0004 0001 0001 0004",8)+
  bad("0001 0006 FFFE 0002 0001 0000 0002 0000",WORD16_MAX_VALUE)+
  bad("0001 0006 0002 0002 0001 FFFD FFFE 0000",WORD16_MAX_VALUE)+
  bad("0002 000A 0002 0001 0002 0001 0003 0000 0001 0002",8)+
  bad("0002 0008 0001 0008 0001 0001 0000",8)+
  bad("0002 0008 0002 0001 0001 0001 0000",8)+
  bad("0002 000A 0002 0001 0002 0001 0002 0001 0001",8)
