#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/opentype_classdef.sats"
extern fun classes_exhausted(): int = "mac#anth_die_int"

fun range_value {fuel:nat} .<fuel>. (fuel: int(fuel),b: !Buf,s: OtSpan,
  gid: int,lo: int,hi: int): int =
  if ige(lo,hi) then 0 else if fuel = 0 then classes_exhausted() else let
    val mid=iadd(lo,idiv(isub(hi,lo),2))
    val row=ot_range(b,s,mid)
  in if ilt(gid,row.first) then range_value(fuel-1,b,s,gid,lo,mid)
    else if igt(gid,row.last) then range_value(fuel-1,b,s,gid,iadd(mid,1),hi)
    else row.value end

fun list_value(b: !Buf,c: OtClassInfo,gid: int): int =
  if ilt(gid,c.first) orelse ige(isub(gid,c.first),c.count) then 0
  else ot_u16(b,c.span,iadd(6,imul(isub(gid,c.first),2)))

implement ot_classdef_value(b,c,gid) = case+ c.encoding of
  | OtList() => list_value(b,c,gid)
  | OtRanges() => range_value(airlock_nat(iadd(c.count,1)),b,c.span,gid,0,c.count)
