#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/utf8/utf8.sats"
staload "data_text/unicode/unicode_property.sats"
staload "data_text/unicode/unicode_db.sats"
staload "data_text/line_break/line_types.sats"
staload "data_text/line_break/line_engine.sats"
staload "data_text/line_break/line_break_map.sats"
staload "text/line_break/line_contracts.sats"

datatype Stress = StressMarks | StressSpaces | StressRegional

fun cp_of(test: Stress,i: int,n: int): int = case+ test of
  | StressRegional() => 127462
  | StressSpaces() => if ieq(i,0) then 40 else if ieq(i,isub(n,1)) then 97 else 32
  | StressMarks() => if ieq(i,0) orelse ieq(i,isub(n,1)) then 97
    else if ieq(i,isub(n,2)) then 32 else 776

fun boundary_of(test: Stress,i: int,n: int): int =
  if ieq(i,n) then 2 else if ieq(i,0) then 0 else case+ test of
  | StressRegional() => if ieq(imod(i,2),0) then 1 else 0
  | StressSpaces() => 0
  | StressMarks() => if ieq(i,isub(n,1)) then 1 else 0

fun fill {fuel:nat} .<fuel>. (fuel: int(fuel),test: Stress,cps: !Buf,starts: !Buf,
  ends: !Buf,i: int,n: int): void =
  if fuel = 0 then () else let
    val ()=buf_set32(cps,i,cp_of(test,i,n))
    val ()=buf_set32(starts,i,imul(i,4))
    val ()=buf_set32(ends,i,imul(iadd(i,1),4))
  in fill(fuel-1,test,cps,starts,ends,iadd(i,1),n) end

fun text_of(test: Stress,n: int): ScalarText = let
  val cps=buf_make(imul(n,4))
  val starts=buf_make(imul(n,4))
  val ends=buf_make(imul(n,4))
  val ()=fill(airlock_nat(n),test,cps,starts,ends,0,n)
in ScalarText(cps,starts,ends,n,0) end

fun differences {fuel:nat} .<fuel>. (fuel: int(fuel),test: Stress,
  result: !LineBreakMap,i: int,n: int,errors: int): int =
  if fuel = 0 then errors else let
    val actual=line_break_code(line_break_at(result,i))
    val want=boundary_of(test,i,n)
  in differences(fuel-1,test,result,iadd(i,1),n,iadd(errors,if ieq(actual,want) then 0 else 1)) end

fun check(map: !PropertyMap(4),width: !PropertyMap(5),category: !PropertyMap(6),
  db: !UnicodeDb,test: Stress,n: int): int = let
  val baseline=mem_live()
  val text=text_of(test,n)
  val result=line_boundaries(map,width,category,db,text)
  val errors=differences(airlock_nat(iadd(n,1)),test,result,0,n,0)
  val ()=line_breaks_dispose(result)
  val ()=scalar_dispose(text)
in iadd(errors,if ieq(mem_live(),baseline) then 0 else 1) end

implement line_contract_stress(map,width,category,db) = let
  val a=check(map,width,category,db,StressMarks(),32771)
  val b=check(map,width,category,db,StressSpaces(),32770)
  val c=check(map,width,category,db,StressRegional(),WORD16_SIGN_BIT)
  val ()=println!("event=line_stress marks=32768 spaces=32768 regional=32768 errors=",a+b+c)
in a+b+c end
