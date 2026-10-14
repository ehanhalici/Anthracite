#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/utf8.sats"
staload "data_text/normalization_types.sats"
staload "data_text/normalization_engine.sats"
staload "normalization_fixture.sats"
staload "data_text/normalization_row.sats"
typedef StableScores = @{scalars=int, errors=int}

fun check_form(data: !NormalizationData, input: !ScalarText, cp: int, form: NormalizationForm): int =
  case+ normalization_apply(data,input,form) of
  | ~CannotNormalize(error) => 1
  | ~NormalizedText(actual) => let
      val valid = ieq(scalar_count(actual),1) andalso ieq(scalar_value(actual,0),cp)
      val () = scalar_dispose(actual)
    in if valid then 0 else 1 end

fun check_scalar(data: !NormalizationData, input: !ScalarText, cp: int): int = let
  val+ ScalarText(values,starts,ends,count,errors) = input
  val () = buf_set32(values,0,cp)
in check_form(data,input,cp,NFC()) + check_form(data,input,cp,NFD())
  + check_form(data,input,cp,NFKC()) + check_form(data,input,cp,NFKD()) end

fun record_scalar(data: !NormalizationData, input: !ScalarText, cp: int, scores: StableScores): StableScores = let
  val errors = check_scalar(data,input,cp)
  val () = if igt(errors,0) andalso ilt(scores.errors,8) then
    println!("event=normalization_stable_failure cp=",cp," errors=",errors) else ()
in @{scalars=iadd(scores.scalars,1),errors=iadd(scores.errors,errors)} end

fun sweep {n:nat} .<n>. (
  n: int(n), data: !NormalizationData, mask: !Buf, input: !ScalarText, cp: int, scores: StableScores
): StableScores = if n = 0 then scores else let
  val test = normalization_scalar_valid(cp) andalso ieq(buf_get(mask,cp),0)
  val next: StableScores = if test then record_scalar(data,input,cp,scores) else scores
in sweep(n-1,data,mask,input,iadd(cp,1),next) end

implement normalization_fixture_stable(data,mask) = let
  val values = buf_make(4)
  val starts = buf_make(4)
  val ends = buf_make(4)
  val input = ScalarText(values,starts,ends,1,0)
  val before = mem_live()
  val scores = sweep(1114112,data,mask,input,0,@{scalars=0,errors=0})
  val balanced = ieq(before,mem_live())
  val () = scalar_dispose(input)
  val () = println!("event=normalization_stable scalars=",scores.scalars," checks=",imul(scores.scalars,4)," errors=",scores.errors," balanced=",balanced)
in iadd(scores.errors,if balanced then 0 else 1) end
