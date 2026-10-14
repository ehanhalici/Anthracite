#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "opentype_fixture.sats"
staload "opentype_contracts.sats"

datatype Check = CheckCoverage | CheckClass | CheckDevice
fun rejected(b: !Buf,s: OtSpan,test: Check,glyphs: int): int = case+ test of
  | CheckCoverage() => ot_fixture_reject_coverage(b,s,glyphs)
  | CheckClass() => ot_fixture_reject_class(b,s,glyphs)
  | CheckDevice() => ot_fixture_reject_device(b,s)

fun truncated {n:nat} .<n>. (n: int(n),b: !Buf,test: Check,size: int,errors: int): int =
  if n = 0 then errors else let
    val ()=buf_set_len(b,iadd(8,size))
    val next=rejected(b,ot_fixture_span(b),test,65535)
  in truncated(n-1,b,test,iadd(size,1),iadd(errors,next)) end

fun prefixes(s: string,test: Check): int = let
  val b=ot_fixture_words(s)
  val size=isub(buf_len(b),8)
  val errors=truncated(airlock_nat(size),b,test,0,0)
  val ()=buf_free(b)
in errors end

fun invalid(s: string,test: Check,glyphs: int): int = let
  val b=ot_fixture_words(s)
  val errors=rejected(b,ot_fixture_span(b),test,glyphs)
  val ()=buf_free(b)
  val ()=if igt(errors,0) then println!("event=opentype_invalid_accepted data=",s) else ()
in errors end

fun spans(test: Check): int = let
  val b=ot_fixture_words("0001 0001 0001 0000")
  val a=rejected(b,@{offset= ~1,length=8},test,65535)
  val c=rejected(b,@{offset=2147483647,length=1},test,65535)
  val d=rejected(b,@{offset=8,length=2147483647},test,65535)
  val e=rejected(b,@{offset=8,length= ~1},test,65535)
  val ()=buf_free(b)
in a+c+d+e end

fun coverage_errors(): int =
  invalid("0003 0000",CheckCoverage(),65535) +
  invalid("0001 0002 0003 0002",CheckCoverage(),65535) +
  invalid("0001 0002 0003 0003",CheckCoverage(),65535) +
  invalid("0001 0001 FFFF",CheckCoverage(),65535) +
  invalid("0002 0001 0003 0002 0000",CheckCoverage(),65535) +
  invalid("0002 0002 0000 0002 0000 0002 0003 0003",CheckCoverage(),65535) +
  invalid("0002 0002 0000 0002 0000 0003 0003 0002",CheckCoverage(),65535) +
  invalid("0001 0000",CheckCoverage(),0) + invalid("0001 0000",CheckCoverage(),65536)

fun class_errors(): int =
  invalid("0000 0000",CheckClass(),65535) +
  invalid("0001 FFFF 0002 0000 0001",CheckClass(),65535) +
  invalid("0002 0001 0003 0002 0000",CheckClass(),65535) +
  invalid("0002 0002 0000 0002 0000 0002 0003 0003",CheckClass(),65535) +
  invalid("0002 0001 FFFF FFFF 0000",CheckClass(),65535) +
  invalid("0001 0000 0000",CheckClass(),0) + invalid("0002 0000",CheckClass(),65536)

fun device_errors(): int =
  invalid("000A 0009 0001 0000",CheckDevice(),65535) +
  invalid("000A 000B 0000 0000",CheckDevice(),65535) +
  invalid("000A 000B 8001 0000",CheckDevice(),65535) +
  invalid("000A 000A 0001 0001",CheckDevice(),65535) +
  invalid("000A 000A 0002 0001",CheckDevice(),65535) +
  invalid("000A 000A 0003 0001",CheckDevice(),65535)

implement ot_test_mutations() = let
  val a=prefixes("0001 0004 0000 0003 000A FFFE",CheckCoverage())
  val b=prefixes("0002 0002 0000 0001 0000 FFFD FFFE 0002",CheckCoverage())
  val c=prefixes("0001 0002 0003 0001 0000 FFFF",CheckClass())
  val d=prefixes("0002 0002 0000 0001 0001 FFFD FFFE FFFF",CheckClass())
  val e=prefixes("000A 0012 0001 0000 0000",CheckDevice())
  val f=spans(CheckCoverage())+spans(CheckClass())+spans(CheckDevice())
  val rows: int=if ot_rows_fit(@{offset=0,length=8},4,2147483647,6) then 1 else 0
in iadd(a+b+c+d+e+f,rows)+coverage_errors()+class_errors()+device_errors() end
