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
staload "data_font/opentype/position/gpos_mark_shared_types.sats"
staload "data_font/opentype/position/gpos_mark_shared.sats"
staload "data_font/opentype/position/gpos_mark_ligature_types.sats"
staload "data_font/opentype/position/gpos_mark_ligature.sats"
staload "font/opentype/tables/opentype_fixture.sats"
staload "font/opentype/position/gpos_mark_ligature_contracts.sats"
fun reject(b: !Buf,s: OtSpan,glyphs: int): int = case+ gpos_mark_ligature_parse(b,s,glyphs) of
  | ~MarkLigatureRejected(e) => 0 | ~MarkLigatureAccepted(t) => let val ()=gpos_mark_ligature_dispose(t) in 1 end
fun cuts {n:nat} .<n>. (n: int(n),b: !Buf,len: int): int =
  if n = 0 then 0 else iadd(reject(b,@{offset=8,length=len},10),cuts(n-1,b,iadd(len,1)))
fun change(at: int,value: int): int = let val b=mark_ligature_fixture()
  val ()=ot_fixture_put16(b,at,value)
  val errors=reject(b,ot_fixture_span(b),10)
  val ()=if igt(errors,0) then println!("event=mark_ligature_mutation field=",at," value=",value," expected_rejected=false") else ()
  val ()=buf_free(b)
in errors end
fun domains(): int = let val b=mark_ligature_fixture()
  val errors=reject(b,ot_fixture_span(b),0)+reject(b,ot_fixture_span(b),WORD16_MODULUS)+
    reject(b,@{offset= ~1,length=96},10)+reject(b,@{offset=8,length=SIGNED_INT_MAX_VALUE},10)+
    cuts(airlock_nat(isub(buf_len(b),8)),b,0)
  val ()=buf_free(b)
in errors end
fun empty_component(): int = let val b=mark_ligature_fixture()
  val ()=ot_fixture_put16(b,56,0)
  val errors=case+ gpos_mark_ligature_parse(b,ot_fixture_span(b),10) of
    | ~MarkLigatureRejected(e) => 1 | ~MarkLigatureAccepted(t) => let
      val r=gpos_mark_ligature_query(b,t,7,5,0)
      val ()=gpos_mark_ligature_dispose(t)
    in if r.matched then 1 else 0 end
  val ()=buf_free(b)
in errors end
implement mark_ligature_test_errors() = domains()+empty_component()+
  change(0,2)+change(2,0)+change(4,10)+change(6,0)+change(8,0)+change(10,0)+
  change(28,1)+change(30,2)+change(32,0)+change(36,0)+change(50,1)+
  change(52,0)+change(54,4)+change(56,WORD16_MAX_VALUE)+change(58,8)+change(60,WORD16_MAX_VALUE)+change(84,WORD16_MAX_VALUE)
