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
staload "data_font/gpos_anchor_cache_types.sats"
staload "data_font/gpos_anchor_cache.sats"
staload "data_font/gpos_mark_matrix_types.sats"
staload "data_font/gpos_mark_matrix.sats"
staload "opentype_fixture.sats"
staload "gpos_mark_matrix_contracts.sats"
fun reject(b: !Buf,s: OtSpan,glyphs: int): int = case+ gpos_mark_matrix_parse(b,s,glyphs,MarkToBase()) of
  | ~MarkMatrixRejected(e) => 0 | ~MarkMatrixAccepted(t) => let val ()=gpos_mark_matrix_dispose(t) in 1 end
fun cuts {n:nat} .<n>. (n: int(n),b: !Buf,len: int): int =
  if n = 0 then 0 else iadd(reject(b,@{offset=8,length=len},10),cuts(n-1,b,iadd(len,1)))
fun change(at: int,value: int): int = let val b=mark_matrix_fixture()
  val ()=ot_fixture_put16(b,at,value)
  val errors=reject(b,ot_fixture_span(b),10)
  val ()=if igt(errors,0) then println!("event=mark_matrix_mutation field=",at," value=",value," expected_rejected=false") else ()
  val ()=buf_free(b)
in errors end
fun domains(): int = let val b=mark_matrix_fixture()
  val errors=reject(b,ot_fixture_span(b),0)+reject(b,ot_fixture_span(b),65536)+
    reject(b,@{offset= ~1,length=78},10)+reject(b,@{offset=8,length=2147483647},10)+
    cuts(airlock_nat(isub(buf_len(b),8)),b,0)
  val ()=buf_free(b)
in errors end
implement mark_matrix_test_errors() = domains()+
  change(0,2)+change(2,0)+change(4,10)+change(6,0)+change(8,0)+change(10,0)+
  change(28,1)+change(30,2)+change(32,0)+change(36,0)+change(50,1)+change(52,8)+
  change(34,2)+change(60,4)
