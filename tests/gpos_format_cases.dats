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
fun expected(code: int,mask: int): int = let
  val raw=g0int2uint_int_uint(code)
  val bit=g0int2uint_int_uint(mask)
  val on=g0uint_land(raw,bit) != 0u
  val below=g0uint_land(raw,g0int2uint_int_uint(isub(mask,1)))
  fun bits {n:nat} .<n>. (n: int(n),v: uint,total: int): int =
    if n = 0 then total else bits(n-1,g0uint_lsr(v,1),iadd(total,if g0uint_land(v,1u) != 0u then 2 else 0))
in if on then bits(8,below,0) else ~1 end
fun valid(code: int,f: OtValueFormat): int = let
  val ok=ieq(f.xp,expected(code,1)) andalso ieq(f.yp,expected(code,2))
    andalso ieq(f.xa,expected(code,4)) andalso ieq(f.ya,expected(code,8))
    andalso ieq(f.xd,expected(code,16)) andalso ieq(f.yd,expected(code,32))
    andalso ieq(f.xad,expected(code,64)) andalso ieq(f.yad,expected(code,128))
  val size=expected(iadd(code,256),256)
in if ok andalso ieq(f.size,size) then 0 else 1 end
fun masks {n:nat} .<n>. (n: int(n),code: int): int =
  if n = 0 then 0 else let
    val errors: int=case+ ot_value_format(code) of
      | ~ValueFormatRejected() => if igt(code,255) then 0 else 1
      | ~ValueFormatAccepted(f) => if igt(code,255) then 1 else valid(code,f)
  in iadd(errors,masks(n-1,iadd(code,1))) end
implement gpos_test_formats() = masks(65536,0)
