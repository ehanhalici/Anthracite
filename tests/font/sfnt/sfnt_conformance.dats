#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "os/fs.sats"
staload "data_font/sfnt/sfnt.sats"
staload "font/resources/font_fixture.sats"

fun rejects(b: !Buf): int = case+ sfnt_parse(b) of
  | InvalidSfnt(error) => 0 | ValidSfnt(info) => 1

fun mapping(b: !Buf, supplementary: int): int = case+ sfnt_parse(b) of
  | InvalidSfnt(error) => 1
  | ValidSfnt(info) => let
      val m = sfnt_metrics(b,info,1)
      val tail = sfnt_metrics(b,info,2)
      val ok = ieq(sfnt_map(b,info,65),1) andalso ieq(sfnt_map(b,info,128512),supplementary)
        andalso ieq(sfnt_map(b,info,66),0) andalso ieq(sfnt_map(b,info,UNICODE_SURROGATE_START),0)
        andalso ieq(m.advance,0) andalso ieq(m.bearing,~20)
        andalso ieq(tail.advance,0) andalso ieq(tail.bearing,30)
    in if ok then 0 else 1 end

fun valid_maps(): int = let
  val f4 = fixture_font(Fixture4())
  val f12 = fixture_font(Fixture12())
  val errors = iadd(mapping(f4,0),mapping(f12,2))
  val () = buf_free(f4)
  val () = buf_free(f12)
in errors end

fun invalid_word(map: FixtureMap, at: int, value: int): int = let
  val b = fixture_font(map)
  val () = fixture_put16(b,at,value)
  val result = rejects(b)
  val () = buf_free(b)
in result end

fun invalid_dword(map: FixtureMap, at: int, value: int): int = let
  val b = fixture_font(map)
  val () = fixture_put32(b,at,value)
  val result = rejects(b)
  val () = buf_free(b)
in result end

fun invalid_cases(): int =
  invalid_dword(Fixture4(),20,2147483644)
  + invalid_dword(Fixture4(),40,10)
  + invalid_dword(Fixture4(),24,SIGNED_INT_MAX_VALUE)
  + invalid_dword(Fixture4(),28,1668112752)
  + invalid_word(Fixture4(),206,0) + invalid_word(Fixture4(),278,4)
  + invalid_word(Fixture4(),238,2) + invalid_word(Fixture4(),298,2)
  + invalid_word(Fixture4(),142,3) + invalid_word(Fixture4(),164,65534)
  + invalid_word(Fixture4(),160,65500) + invalid_word(Fixture4(),130,0)
  + invalid_dword(Fixture12(),148,SIGNED_INT_MAX_VALUE)
  + invalid_dword(Fixture12(),168,1114112) + invalid_dword(Fixture12(),172,3)
  + invalid_dword(Fixture12(),164,65)

fun truncated {n:nat} .<n>. (n: int(n), b: !Buf, length: int, errors: int): int =
  if n = 0 then errors else let
    val () = buf_set_len(b,length)
    val failed = rejects(b)
  in truncated(n-1,b,iadd(length,1),iadd(errors,failed)) end

fun truncation_cases(): int = let
  val b = fixture_font(Fixture12())
  val result = truncated(332,b,0,0)
  val () = buf_free(b)
in result end

fun range_mapping(): int = let
  val b = fixture_font(Fixture4())
  val () = fixture_put16(b,138,34)
  val () = fixture_put16(b,160,0)
  val () = fixture_put16(b,164,4)
  val () = fixture_put16(b,168,1)
  val result = mapping(b,0)
  val () = buf_free(b)
in result end

fun run(): int = let
  val good = valid_maps()
  val malformed = invalid_cases()
  val short = truncation_cases()
  val range = range_mapping()
  val () = println!("event=sfnt_conformance mapping_errors=",good,
    " malformed_errors=",malformed," truncation_errors=",short," range_errors=",range)
in good + malformed + short + range end

implement main0() = if igt(run(),0) then exit(1) else ()
