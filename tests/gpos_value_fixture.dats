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
fun scalar(b: !Buf,at: int,field: int,value: int): void =
  if ilt(field,0) then () else ot_fixture_put16(b,iadd(at,field),value)
fun device(b: !Buf,at: int,field: int,floor: int,index: int): void = let
  val d=iadd(floor,imul(index,8))
  val ()=scalar(b,at,field,d)
  val ()=ot_fixture_put16(b,d,if ieq(index,3) then 65535 else 5)
  val ()=ot_fixture_put16(b,iadd(d,2),if ieq(index,3) then 65534 else 6)
  val ()=ot_fixture_put16(b,iadd(d,4),if ieq(index,3) then 32768 else iadd(index,1))
  val word=case+ index of | 0 => 45056 | 1 => 30720 | 2 => 32640 | _ => 0
in ot_fixture_put16(b,iadd(d,6),word) end
implement gpos_fixture_value(f) = let
  val b=buf_make(80)
  val ()=buf_set_len(b,80)
  val floor=iadd(8,f.size)
  val ()=scalar(b,8,f.xp,32768) and ()=scalar(b,8,f.yp,32767)
  val ()=scalar(b,8,f.xa,65535) and ()=scalar(b,8,f.ya,1)
  val ()=device(b,8,f.xd,floor,0) and ()=device(b,8,f.yd,floor,1)
  val ()=device(b,8,f.xad,floor,2) and ()=device(b,8,f.yad,floor,3)
in b end
