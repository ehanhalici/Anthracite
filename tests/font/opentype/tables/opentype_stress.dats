#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_coverage.sats"
staload "data_font/opentype/tables/opentype_classdef.sats"
staload "font/opentype/tables/opentype_fixture.sats"
staload "font/opentype/tables/opentype_contracts.sats"

datatype Stress = CoverageList | CoverageRanges | ClassList | ClassRanges
fun header_size(test: Stress): int = case+ test of
  | CoverageList() => 4 | CoverageRanges() => 4 | ClassList() => 6 | ClassRanges() => 4
fun row_size(test: Stress): int = case+ test of
  | CoverageList() => 2 | CoverageRanges() => 6 | ClassList() => 2 | ClassRanges() => 6

fun header(b: !Buf,test: Stress,count: int): void = case+ test of
  | CoverageList() => (ot_fixture_put16(b,0,1); ot_fixture_put16(b,2,count))
  | CoverageRanges() => (ot_fixture_put16(b,0,2); ot_fixture_put16(b,2,count))
  | ClassList() => (ot_fixture_put16(b,0,1); ot_fixture_put16(b,2,0); ot_fixture_put16(b,4,count))
  | ClassRanges() => (ot_fixture_put16(b,0,2); ot_fixture_put16(b,2,count))

fun range_row(b: !Buf,index: int,value: int): void = let val at=iadd(4,imul(index,6)) in
  ot_fixture_put16(b,at,index); ot_fixture_put16(b,iadd(at,2),index);
  ot_fixture_put16(b,iadd(at,4),value) end

fun row(b: !Buf,test: Stress,index: int): void = case+ test of
  | CoverageList() => ot_fixture_put16(b,iadd(4,imul(index,2)),index)
  | CoverageRanges() => range_row(b,index,index)
  | ClassList() => ot_fixture_put16(b,iadd(6,imul(index,2)),imod(index,7))
  | ClassRanges() => range_row(b,index,imod(index,7))

fun fill {n:nat} .<n>. (n: int(n),b: !Buf,test: Stress,index: int): void =
  if n = 0 then () else let val ()=row(b,test,index) in fill(n-1,b,test,iadd(index,1)) end

fun fixture(test: Stress,count: int): Buf = let
  val size=iadd(8,iadd(header_size(test),imul(row_size(test),count)))
  val b=buf_make(size)
  val ()=buf_set_len(b,size)
  val ()=header(b,test,count)
  val ()=fill(airlock_nat(count),b,test,0)
in b end

fun coverage_query {n:nat} .<n>. (n: int(n),b: !Buf,c: OtCoverageInfo,gid: int,errors: int): int =
  if n = 0 then errors else let
    val got=ot_coverage_index(b,c,gid)
    val valid=ige(gid,0) andalso ilt(gid,WORD16_MAX_VALUE)
    val equal=if valid then got.found andalso ieq(got.index,gid) else not(got.found)
  in coverage_query(n-1,b,c,iadd(gid,1),iadd(errors,if equal then 0 else 1)) end

fun class_query {n:nat} .<n>. (n: int(n),b: !Buf,c: OtClassInfo,gid: int,errors: int): int =
  if n = 0 then errors else let
    val got=ot_classdef_value(b,c,gid)
    val want=if ige(gid,0) andalso ilt(gid,WORD16_MAX_VALUE) then imod(gid,7) else 0
  in class_query(n-1,b,c,iadd(gid,1),iadd(errors,if ieq(got,want) then 0 else 1)) end

fun coverage(b: !Buf): int = case+ ot_coverage_parse(b,ot_fixture_span(b),WORD16_MAX_VALUE) of
  | ~CoverageRejected(e) => 1
  | ~CoverageAccepted(c) => coverage_query(65538,b,c,~1,0)
fun classes(b: !Buf): int = case+ ot_classdef_parse(b,ot_fixture_span(b),WORD16_MAX_VALUE) of
  | ~ClassRejected(e) => 1
  | ~ClassAccepted(c) => class_query(65538,b,c,~1,0)

fun check(test: Stress): int = let
  val b=fixture(test,WORD16_MAX_VALUE)
  val errors=case+ test of
    | CoverageList() => coverage(b) | CoverageRanges() => coverage(b)
    | ClassList() => classes(b) | ClassRanges() => classes(b)
  val ()=buf_free(b)
in errors end

implement ot_test_stress() =
  check(CoverageList())+check(CoverageRanges())+check(ClassList())+check(ClassRanges())
