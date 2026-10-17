#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_classdef.sats"
staload "font/opentype/tables/opentype_fixture.sats"
staload "font/opentype/tables/opentype_contracts.sats"

datatype ClassCase = ClList | ClRanges | ClEmpty
fun expected(test: ClassCase,gid: int): int = case+ test of
  | ClList() => if ieq(gid,2) then 1 else if ieq(gid,4) then WORD16_MAX_VALUE else 0
  | ClRanges() => if ieq(gid,0) orelse ieq(gid,1) then 1
    else if ieq(gid,UNICODE_REPLACEMENT_SCALAR) orelse ieq(gid,65534) then WORD16_MAX_VALUE else 0
  | ClEmpty() => 0

fun compare {n:nat} .<n>. (n: int(n),b: !Buf,c: OtClassInfo,test: ClassCase,
  gid: int,errors: int): int =
  if n = 0 then errors else let
    val want=expected(test,gid)
    val got=ot_classdef_value(b,c,gid)
  in compare(n-1,b,c,test,iadd(gid,1),iadd(errors,if ieq(got,want) then 0 else 1)) end

fun parsed(b: !Buf,test: ClassCase,maximum: int): int =
  case+ ot_classdef_parse(b,ot_fixture_span(b),WORD16_MAX_VALUE) of
  | ~ClassRejected(e) => 1
  | ~ClassAccepted(c) =>
    iadd(compare(65538,b,c,test,~1,0),if ieq(c.maximum,maximum) then 0 else 1)

fun check(s: string,test: ClassCase,maximum: int): int = let
  val baseline=mem_live()
  val b=ot_fixture_words(s)
  val errors=parsed(b,test,maximum)
  val ()=buf_free(b)
in iadd(errors,if ieq(mem_live(),baseline) then 0 else 1) end

implement ot_test_classes() = let
  val a=check("0001 0002 0003 0001 0000 FFFF",ClList(),WORD16_MAX_VALUE)
  val b=check("0002 0003 0000 0001 0001 0003 0003 0000 FFFD FFFE FFFF",ClRanges(),WORD16_MAX_VALUE)
  val c=check("0001 0000 0000",ClEmpty(),0)
  val d=check("0002 0000",ClEmpty(),0)
in a+b+c+d end
