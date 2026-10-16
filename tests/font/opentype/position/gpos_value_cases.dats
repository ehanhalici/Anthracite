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
fun scalar(a: int,b: int): int = if ieq(a,b) then 0 else 1
fun pixels(p: OtPixelSample,want: int): int = case+ p.kind of
  | PixelResolved() => scalar(p.pixels,want) | PixelVariation() => 1
fun variation(p: OtPixelSample): int = case+ p.kind of
  | PixelResolved() => 1 | PixelVariation() => scalar(p.outer,WORD16_MAX_VALUE)+scalar(p.inner,65534)
fun unit_checks(v: OtVector,f: OtValueFormat): int = let
  val xp=scalar(v.xPlace,if ilt(f.xp,0) then 0 else ~WORD16_SIGN_BIT)
  val yp=scalar(v.yPlace,if ilt(f.yp,0) then 0 else 32767)
  val xa=scalar(v.xAdvance,if ilt(f.xa,0) then 0 else ~1)
  val ya=scalar(v.yAdvance,if ilt(f.ya,0) then 0 else 1)
in iadd(iadd(xp,yp),iadd(xa,ya)) end
fun sample_checks(a: OtValueSample,z: OtValueSample,f: OtValueFormat): int = let
  val xp=iadd(pixels(a.xPlace,if ilt(f.xd,0) then 0 else ~2),pixels(z.xPlace,if ilt(f.xd,0) then 0 else ~1))
  val yp=iadd(pixels(a.yPlace,if ilt(f.yd,0) then 0 else 7),pixels(z.yPlace,if ilt(f.yd,0) then 0 else ~8))
  val xa=iadd(pixels(a.xAdvance,if ilt(f.xad,0) then 0 else 127),pixels(z.xAdvance,if ilt(f.xad,0) then 0 else ~128))
  val ya: int=if ilt(f.yad,0) then pixels(a.yAdvance,0) else variation(a.yAdvance)
in iadd(iadd(xp,yp),iadd(xa,ya)) end
fun samples(b: !Buf,v: OtValueInfo,f: OtValueFormat): int = let
  val a=ot_value_sample(b,v,5) and z=ot_value_sample(b,v,6)
  val outside=ot_value_sample(b,v,4)
  val missing=iadd(pixels(outside.xPlace,0),iadd(pixels(outside.yPlace,0),pixels(outside.xAdvance,0)))
in iadd(unit_checks(v.units,f),iadd(sample_checks(a,z,f),missing)) end
fun check(f: OtValueFormat): int = let val b=gpos_fixture_value(f) in
  case+ ot_value_parse(b,ot_fixture_span(b),8,f,iadd(8,f.size)) of
  | ~ValueRejected(e) => let val ()=buf_free(b) in 1 end
  | ~ValueAccepted(v) => let val errors=samples(b,v,f) val ()=buf_free(b) in errors end end
fun formats {n:nat} .<n>. (n: int(n),code: int): int =
  if n = 0 then 0 else let val errors=case+ ot_value_format(code) of
    | ~ValueFormatRejected() => 1 | ~ValueFormatAccepted(f) => check(f)
  in iadd(errors,formats(n-1,iadd(code,1))) end
implement gpos_test_values() = formats(256,0)
