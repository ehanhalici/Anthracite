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
staload "data_font/gpos_cursive_types.sats"
staload "data_font/gpos_cursive.sats"
staload "opentype_fixture.sats"
staload "gpos_cursive_contracts.sats"
fun fixture(): Buf = let
  val b=buf_make(65552) val ()=buf_set_len(b,65552)
  val ()=ot_fixture_put16(b,0,1) and ()=ot_fixture_put16(b,2,65534)
  val ()=ot_fixture_put16(b,4,16382)
  val ()=ot_fixture_put16(b,65534,2) and ()=ot_fixture_put16(b,65536,1)
  val ()=ot_fixture_put16(b,65538,0) and ()=ot_fixture_put16(b,65540,16381)
in b end
fun queries {n:nat} .<n>. (n: int(n),b: !Buf,t: !GposCursive,i: int,acc: int): int =
  if n = 0 then acc else let val r=gpos_cursive_query(b,t,i)
    val entry=case+ r.entry.kind of | AnchorMissing() => true | AnchorPresent() => false
    val exit=case+ r.exit.kind of | AnchorMissing() => true | AnchorPresent() => false
    val errors=if r.matched andalso entry andalso exit then 0 else 1
  in queries(n-1,b,t,iadd(i,1),iadd(acc,errors)) end
implement gpos_cursive_test_stress() = let val b=fixture()
  val errors=case+ gpos_cursive_parse(b,ot_fixture_span(b),16382) of
    | ~CursiveRejected(e) => 1 | ~CursiveAccepted(t) => let val errors=queries(16382,b,t,0,0)
      val ()=gpos_cursive_dispose(t) in errors end
  val ()=buf_free(b)
in errors end
