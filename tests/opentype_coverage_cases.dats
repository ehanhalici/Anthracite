#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_coverage.sats"
staload "opentype_fixture.sats"
staload "opentype_contracts.sats"

datatype CoverageCase = CovList | CovRanges | CovFull | CovEmpty
fun expected(test: CoverageCase,gid: int): int = case+ test of
  | CovList() => if ieq(gid,0) then 0 else if ieq(gid,3) then 1
    else if ieq(gid,10) then 2 else if ieq(gid,65534) then 3 else ~1
  | CovRanges() => if ieq(gid,0) orelse ieq(gid,1) then gid
    else if ieq(gid,3) then 2 else if ieq(gid,65533) orelse ieq(gid,65534) then isub(gid,65530) else ~1
  | CovFull() => if ige(gid,0) andalso ilt(gid,65535) then gid else ~1
  | CovEmpty() => ~1

fun compare {n:nat} .<n>. (n: int(n),b: !Buf,c: OtCoverageInfo,test: CoverageCase,
  gid: int,errors: int): int =
  if n = 0 then errors else let
    val want=expected(test,gid)
    val got=ot_coverage_index(b,c,gid)
    val equal=if ilt(want,0) then not(got.found) else got.found andalso ieq(got.index,want)
  in compare(n-1,b,c,test,iadd(gid,1),iadd(errors,if equal then 0 else 1)) end

fun parsed(b: !Buf,test: CoverageCase,total: int): int =
  case+ ot_coverage_parse(b,ot_fixture_span(b),65535) of
  | ~CoverageRejected(e) => 1
  | ~CoverageAccepted(c) =>
    iadd(compare(65538,b,c,test,~1,0),if ieq(c.total,total) then 0 else 1)

fun check(s: string,test: CoverageCase,total: int): int = let
  val baseline=mem_live()
  val b=ot_fixture_words(s)
  val errors=parsed(b,test,total)
  val ()=buf_free(b)
in iadd(errors,if ieq(mem_live(),baseline) then 0 else 1) end

implement ot_test_coverages() = let
  val a=check("0001 0004 0000 0003 000A FFFE",CovList(),4)
  val b=check("0002 0003 0000 0001 0000 0003 0003 0002 FFFD FFFE 0003",CovRanges(),5)
  val c=check("0002 0001 0000 FFFE 0000",CovFull(),65535)
  val d=check("0001 0000",CovEmpty(),0)
  val e=check("0002 0000",CovEmpty(),0)
in a+b+c+d+e end
