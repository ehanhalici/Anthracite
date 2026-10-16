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
staload "font/opentype/tables/opentype_fixture.sats"
staload "font/opentype/position/gpos_value_contracts.sats"
fun expected(code: int,mask: int): int = let
  val raw=g0int2uint_int_uint(code)
  val bit=g0int2uint_int_uint(mask)
  val on=g0uint_land(raw,bit) != 0u
  val below=g0uint_land(raw,g0int2uint_int_uint(isub(mask,1)))
  fun read_bits {n:nat} .<n>. (n: int(n),v: uint,total: int): int =
    if n = 0 then total else read_bits(n-1,g0uint_lsr(v,1),iadd(total,if g0uint_land(v,1u) != 0u then 2 else 0))
in if on then read_bits(8,below,0) else ~1 end
fun valid(code: int,f: OtValueFormat): int = let
  val ok=ieq(f.xp,expected(code,1)) andalso ieq(f.yp,expected(code,2))
    andalso ieq(f.xa,expected(code,4)) andalso ieq(f.ya,expected(code,8))
    andalso ieq(f.xd,expected(code,16)) andalso ieq(f.yd,expected(code,32))
    andalso ieq(f.xad,expected(code,64)) andalso ieq(f.yad,expected(code,128))
  val size=expected(iadd(code,256),256)
in if ok andalso ieq(f.size,size) then 0 else 1 end
(* Errors are accumulated in tail position so the 65536-step scan runs in
   constant stack space at every optimization level. *)
fun masks {n:nat} .<n>. (n: int(n),code: int,acc: int): int =
  if n = 0 then acc else let
    val errors: int=case+ ot_value_format(code) of
      | ~ValueFormatRejected() => if igt(code,255) then 0 else 1
      | ~ValueFormatAccepted(f) => if igt(code,255) then 1 else valid(code,f)
  in masks(n-1,iadd(code,1),iadd(acc,errors)) end
implement gpos_test_formats() = masks(WORD16_MODULUS,0,0)
