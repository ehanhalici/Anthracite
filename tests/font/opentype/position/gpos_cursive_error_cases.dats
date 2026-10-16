#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_reader.sats"
staload "data_font/opentype/position/gpos_value_types.sats"
staload "data_font/opentype/position/gpos_values.sats"
staload "data_font/opentype/position/gpos_anchor_cache_types.sats"
staload "data_font/opentype/position/gpos_anchor_cache.sats"
staload "data_font/opentype/position/gpos_cursive_types.sats"
staload "data_font/opentype/position/gpos_cursive.sats"
staload "font/opentype/tables/opentype_fixture.sats"
staload "font/opentype/position/gpos_cursive_contracts.sats"
fun reject(b: !Buf,s: OtSpan,glyphs: int): int = case+ gpos_cursive_parse(b,s,glyphs) of
  | ~CursiveRejected(e) => 0 | ~CursiveAccepted(t) => let val ()=gpos_cursive_dispose(t) in 1 end
fun cuts {n:nat} .<n>. (n: int(n),b: !Buf,len: int): int =
  if n = 0 then 0 else iadd(reject(b,@{offset=8,length=len},10),cuts(n-1,b,iadd(len,1)))
fun change(at: int,value: int): int = let val b=gpos_cursive_fixture()
  val ()=ot_fixture_put16(b,at,value)
  val errors=reject(b,ot_fixture_span(b),10) val ()=buf_free(b) in errors end
fun domains(): int = let val b=gpos_cursive_fixture()
  val errors=reject(b,ot_fixture_span(b),0)+reject(b,ot_fixture_span(b),WORD16_MODULUS)+
    reject(b,@{offset= ~1,length=36},10)+reject(b,@{offset=8,length=SIGNED_INT_MAX_VALUE},10)+
    cuts(airlock_nat(isub(buf_len(b),8)),b,0)
  val ()=buf_free(b)
in errors end
fun presence(): int = let val b=ot_fixture_words("0000")
  val s=ot_fixture_span(b)
  val required=case+ ot_anchor_slot_parse(b,s,0,2,AnchorRequired()) of
    | ~AnchorSlotRejected(e) => 0 | ~AnchorSlotAccepted(v) => 1
  val optional=case+ ot_anchor_slot_parse(b,s,0,2,AnchorOptional()) of
    | ~AnchorSlotRejected(e) => 1 | ~AnchorSlotAccepted(v) => (case+ v.kind of | AnchorMissing() => 0 | AnchorPresent() => 1)
  val ()=buf_free(b)
in iadd(required,optional) end
implement gpos_cursive_test_errors() = domains()+presence()+
  change(0,2)+change(2,0)+change(2,12)+change(4,1)+change(6,4)+change(8,WORD16_MAX_VALUE)+
  change(10,4)+change(22,4)+change(28,4)+change(14,3)
