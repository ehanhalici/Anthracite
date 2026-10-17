#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_device.sats"
staload "data_font/opentype/tables/opentype_packing.sats"
staload "font/opentype/tables/opentype_fixture.sats"
staload "font/opentype/tables/opentype_contracts.sats"

(* Independent unsigned bit-operation oracle for the division-based kernel. *)
fun expected(packing: OtPacking,word: int,index: int): int = let
  val read_bits=case+ packing of | OtBits2() => 2 | OtBits4() => 4 | OtBits8() => 8
  val base=case+ packing of | OtBits2() => 4 | OtBits4() => 16 | OtBits8() => 256
  val shift=isub(16,imul(iadd(index,1),read_bits))
  val raw=g0uint_lsr(g0int2uint_int_uint(word),airlock_nat(shift))
  val value=g0uint2int_uint_int(g0uint_land(raw,g0int2uint_int_uint(isub(base,1))))
in if ilt(value,idiv(base,2)) then value else isub(value,base) end

fun positions {n:nat} .<n>. (n: int(n),b: !Buf,d: OtDeviceInfo,word: int,index: int,errors: int): int =
  if n = 0 then errors else let
    val want=expected(d.packing,word,index)
    val got=ot_device_pixels(b,d,iadd(d.first,index))
  in positions(n-1,b,d,word,iadd(index,1),iadd(errors,if ieq(got,want) then 0 else 1)) end

fun words {n:nat} .<n>. (n: int(n),b: !Buf,d: OtDeviceInfo,word: int,errors: int): int =
  if n = 0 then errors else let
    val ()=ot_fixture_put16(b,6,word)
    val count=iadd(isub(d.last,d.first),1)
    val next=positions(airlock_nat(count),b,d,word,0,errors)
  in words(n-1,b,d,iadd(word,1),next) end

fun parsed(b: !Buf): int = case+ ot_device_parse(b,ot_fixture_span(b)) of
  | ~DeviceRejected(e) => 1 | ~DeviceVariation(a,b) => 1
  | ~DeviceAccepted(d) => let
    val errors=words(WORD16_MODULUS,b,d,0,0)
    val outside=ot_device_pixels(b,d,isub(d.first,1)) + ot_device_pixels(b,d,iadd(d.last,1))
  in iadd(errors,if ieq(outside,0) then 0 else 1) end

fun check(s: string): int = let
  val baseline=mem_live()
  val b=ot_fixture_words(s)
  val errors=parsed(b)
  val ()=buf_free(b)
in iadd(errors,if ieq(mem_live(),baseline) then 0 else 1) end

fun variation(): int = let
  val b=ot_fixture_words("FFFF FFFE 8000")
  val errors=case+ ot_device_parse(b,ot_fixture_span(b)) of
    | ~DeviceAccepted(d) => 1 | ~DeviceRejected(e) => 1
    | ~DeviceVariation(outer,inner) => if ieq(outer,WORD16_MAX_VALUE) andalso ieq(inner,65534) then 0 else 1
  val ()=buf_free(b)
in errors end

implement ot_test_devices() =
  check("000A 0011 0001 0000") + check("000A 000D 0002 0000") +
  check("000A 000B 0003 0000") + variation()
