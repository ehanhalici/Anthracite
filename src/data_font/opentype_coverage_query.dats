#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/opentype_coverage.sats"
extern fun coverage_exhausted(): int = "mac#anth_die_int"

fun list_index {fuel:nat} .<fuel>. (fuel: int(fuel),b: !Buf,s: OtSpan,
  gid: int,lo: int,hi: int): int =
  if ige(lo,hi) then ~1 else if fuel = 0 then coverage_exhausted() else let
    val mid=iadd(lo,idiv(isub(hi,lo),2))
    val value=ot_u16(b,s,iadd(4,imul(mid,2)))
  in if ilt(gid,value) then list_index(fuel-1,b,s,gid,lo,mid)
    else if igt(gid,value) then list_index(fuel-1,b,s,gid,iadd(mid,1),hi)
    else mid end

fun range_index {fuel:nat} .<fuel>. (fuel: int(fuel),b: !Buf,s: OtSpan,
  gid: int,lo: int,hi: int): int =
  if ige(lo,hi) then ~1 else if fuel = 0 then coverage_exhausted() else let
    val mid=iadd(lo,idiv(isub(hi,lo),2))
    val row=ot_range(b,s,mid)
  in if ilt(gid,row.first) then range_index(fuel-1,b,s,gid,lo,mid)
    else if igt(gid,row.last) then range_index(fuel-1,b,s,gid,iadd(mid,1),hi)
    else iadd(row.value,isub(gid,row.first)) end

fun index_of(b: !Buf,c: OtCoverageInfo,gid: int): int = case+ c.encoding of
  | OtList() => list_index(airlock_nat(iadd(c.count,1)),b,c.span,gid,0,c.count)
  | OtRanges() => range_index(airlock_nat(iadd(c.count,1)),b,c.span,gid,0,c.count)

implement ot_coverage_index(b,c,gid) = let val index=index_of(b,c,gid) in
  @{found=ige(index,0),index=if ige(index,0) then index else 0} end
