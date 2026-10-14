#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/gpos_value_types.sats"
staload "data_font/gpos_values.sats"
staload "opentype_fixture.sats"
staload "gpos_value_contracts.sats"
staload "data_font/gpos_single_types.sats"
staload "data_font/gpos_single.sats"
staload "gpos_single_contracts.sats"
fun reject(b: !Buf,s: OtSpan,glyphs: int): int = case+ gpos_single_parse(b,s,glyphs) of
  | ~PositionSingleRejected(e) => 0
  | ~PositionSingleAccepted(t) => let val ()=gpos_single_dispose(t) in 1 end
fun cuts {n:nat} .<n>. (n: int(n),b: !Buf,len: int): int =
  if n = 0 then 0 else iadd(reject(b,@{offset=8,length=len},10),cuts(n-1,b,iadd(len,1)))
fun fixture(s: string): int = let
  val b=ot_fixture_words(s)
  val errors=cuts(airlock_nat(isub(buf_len(b),8)),b,0)
  val ()=buf_free(b)
in errors end
fun malformed(s: string): int = let val b=ot_fixture_words(s)
  val errors=reject(b,ot_fixture_span(b),10) val ()=buf_free(b) in errors end
fun domains(): int = let
  val b=ot_fixture_words("0001 0006 0000 0001 0001 0005")
  val errors=reject(b,ot_fixture_span(b),0)+reject(b,ot_fixture_span(b),65536)+
    reject(b,@{offset= ~1,length=12},10)+reject(b,@{offset=8,length=2147483647},10)
  val ()=buf_free(b)
in errors end
implement gpos_single_test_errors() = domains()+
  fixture("0001 000A 0005 FFFF 0002 0001 0002 0005 0006")+
  fixture("0002 0010 0005 0002 FFFF 0002 0003 FFFC 0001 0002 0005 0006")+
  malformed("0003 0006 0000 0001 0001 0005")+
  malformed("0001 0006 0100 0001 0001 0005")+
  malformed("0001 0000 0000 0001 0001 0005")+
  malformed("0001 0004 0000 0001 0001 0005")+
  malformed("0002 0008 0000 0001 0001 0002 0005 0006")+
  malformed("0001 0008 0010 0006 0001 0001 0005")+
  malformed("0002 0010 0010 0002 0016 0006 0000 0000 0001 0002 0005 0006 0005 0006 0001 B000")
