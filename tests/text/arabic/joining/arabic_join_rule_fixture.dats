#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/utf8/utf8.sats"
staload "data_text/unicode/unicode_property.sats"
staload "data_text/arabic/joining/arabic_join_types.sats"
staload "data_text/arabic/joining/arabic_join.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "text/utf8/utf8_contracts.sats"
staload "font/opentype/tables/opentype_fixture.sats"
staload "text/arabic/joining/arabic_join_contracts.sats"
extern fun invalid_fixture(): int = "mac#anth_die_int"
fun scalar_of(code: int): int = case+ code of
  | 0 => 32 | 1 => 1575 | 2 => 69337 | 3 => 1576 | 4 => 8205 | 5 => 1614 | _ => invalid_fixture()
implement arabic_test_rule_kind(index,i) =
  arabic_joining_of(if ieq(i,0) then idiv(index,36) else if ieq(i,1) then imod(idiv(index,6),6) else imod(index,6))
fun append(b: &Buf >> _,scratch: !Buf,code: int): void = let
  val count=utf8_test_write(scratch,scalar_of(code))
in buf_append_at(b,scratch,0,count) end
implement arabic_test_rule_source(index) = let
  var b=buf_make(12) val scratch=buf_make(4)
  val ()=append(b,scratch,idiv(index,36))
  val ()=append(b,scratch,imod(idiv(index,6),6))
  val ()=append(b,scratch,imod(index,6)) val ()=buf_free(scratch)
in b end
fun prior{n:nat} .<n>. (n: int(n),index: int,i: int): ArabicJoining =
  if n = 0 then JoinNone() else let val k=arabic_test_rule_kind(index,i) in case+ k of
    | JoinTransparent() => prior(n-1,index,isub(i,1)) | JoinNone() => k | JoinRight() => k
    | JoinLeft() => k | JoinDual() => k | JoinCausing() => k end
fun next{n:nat} .<n>. (n: int(n),index: int,i: int): ArabicJoining =
  if n = 0 then JoinNone() else let val k=arabic_test_rule_kind(index,i) in case+ k of
    | JoinTransparent() => next(n-1,index,iadd(i,1)) | JoinNone() => k | JoinRight() => k
    | JoinLeft() => k | JoinDual() => k | JoinCausing() => k end
fun output(index: int,i: int): int = arabic_test_form_code(arabic_test_model(
  arabic_test_rule_kind(index,i),prior(airlock_nat(i),index,isub(i,1)),next(airlock_nat(isub(2,i)),index,iadd(i,1))))
implement arabic_test_rule_expected(index) = let val b=ot_fixture_words("0000 0000 0000")
  val ()=ot_fixture_put16(b,0,output(index,0)) and ()=ot_fixture_put16(b,2,output(index,1))
  val ()=ot_fixture_put16(b,4,output(index,2))
in b end
