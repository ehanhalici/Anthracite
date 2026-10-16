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
fun count {n:nat} .<n>. (n: int(n),code: int,total: int): int =
  if n = 0 then total else count(n-1,idiv(code,2),iadd(total,imul(imod(code,2),2)))
fun offset(code: int,mask: int): int =
  if ieq(imod(idiv(code,mask),2),0) then ~1 else count(8,imod(code,mask),0)
implement ot_value_format(code) =
  if ilt(code,0) orelse igt(code,255) then ValueFormatRejected() else
    ValueFormatAccepted(@{size=count(8,code,0),xp=offset(code,1),yp=offset(code,2),
      xa=offset(code,4),ya=offset(code,8),xd=offset(code,16),yd=offset(code,32),
      xad=offset(code,64),yad=offset(code,128)})
implement ot_value_field(f,field) = case+ field of
  | ValueXPlace() => f.xp | ValueYPlace() => f.yp
  | ValueXAdvance() => f.xa | ValueYAdvance() => f.ya
  | ValueXPlaceDevice() => f.xd | ValueYPlaceDevice() => f.yd
  | ValueXAdvanceDevice() => f.xad | ValueYAdvanceDevice() => f.yad
