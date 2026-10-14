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
fun rows {n:nat} .<n>. (n: int(n),b: !Buf,i: int): void =
  if n = 0 then () else let val ()=ot_fixture_put16(b,iadd(8,imul(i,2)),imod(i,65536))
  in rows(n-1,b,iadd(i,1)) end
fun queries {n:nat} .<n>. (n: int(n),b: !Buf,t: !GposSingle,i: int): int =
  if n = 0 then 0 else let
    val r=gpos_single_query(b,t,i)
    val expected=if ilt(i,32768) then i else isub(i,65536)
    val errors=if r.matched andalso ieq(r.value.units.xPlace,expected) then 0 else 1
  in iadd(errors,queries(n-1,b,t,iadd(i,1))) end
fun fixture(): Buf = let
  val b=buf_make(65552)
  val ()=buf_set_len(b,65552)
  val ()=ot_fixture_put16(b,0,2) and ()=ot_fixture_put16(b,2,6)
  val ()=ot_fixture_put16(b,4,1) and ()=rows(32763,b,0)
  val ()=ot_fixture_put16(b,2,65534) and ()=ot_fixture_put16(b,6,32763)
  val ()=ot_fixture_put16(b,65534,2) and ()=ot_fixture_put16(b,65536,1)
  val ()=ot_fixture_put16(b,65538,0) and ()=ot_fixture_put16(b,65540,32762)
  val ()=ot_fixture_put16(b,65542,0)
in b end
fun indexed(): int = let val b=fixture()
  val errors=case+ gpos_single_parse(b,ot_fixture_span(b),32763) of
    | ~PositionSingleRejected(e) => 1 | ~PositionSingleAccepted(t) => let
      val errors=queries(32763,b,t,0) val ()=gpos_single_dispose(t) in errors end
  val ()=buf_free(b)
in errors end
fun zero_queries {n:nat} .<n>. (n: int(n),b: !Buf,t: !GposSingle,i: int): int =
  if n = 0 then 0 else let val r=gpos_single_query(b,t,i)
    val errors=if r.matched andalso ieq(r.value.units.xPlace,0) then 0 else 1
  in iadd(errors,zero_queries(n-1,b,t,iadd(i,1))) end
fun empty_values(): int = let
  val b=ot_fixture_words("0002 0008 0000 FFFF 0002 0001 0000 FFFE 0000")
  val errors=case+ gpos_single_parse(b,ot_fixture_span(b),65535) of
    | ~PositionSingleRejected(e) => 1 | ~PositionSingleAccepted(t) => let
      val errors=zero_queries(65535,b,t,0) val ()=gpos_single_dispose(t) in errors end
  val ()=buf_free(b)
in errors end
implement gpos_single_test_stress() = indexed()+empty_values()
