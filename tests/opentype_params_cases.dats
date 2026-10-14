#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/ot_feature_params.sats"
staload "opentype_fixture.sats"
staload "opentype_contracts.sats"

fun params(s: string): OtChild = let
  val b=ot_fixture_words(s)
  val span=ot_fixture_span(b)
  val ()=buf_free(b)
in @{kind=ChildPresent(),span=span} end

fun size(): int = let
  val b=ot_fixture_words("0258 0003 07D0 0005")
  val t=@{code=1936292453}
  val errors=case+ ot_feature_params_parse(b,t,params("0258 0003 07D0 0005")) of
    | ~FeatureParamsRejected(e) => 1
    | ~FeatureParamsAccepted(p) => case+ p of
      | ParamsSize(v) => if ieq(v.design,600) andalso ieq(v.subfamily,3)
        andalso ieq(v.name,2000) andalso ieq(v.record,5) then 0 else 1
      | ParamsStylistic(_) => 1 | ParamsVariant(_) => 1 | ParamsAbsent() => 1
  val ()=buf_free(b)
in errors end

fun stylistic(): int = let
  val b=ot_fixture_words("0001 04E1")
  val t=@{code=1936928817}
  val errors=case+ ot_feature_params_parse(b,t,params("0001 04E1")) of
    | ~FeatureParamsRejected(e) => 1
    | ~FeatureParamsAccepted(p) => case+ p of
      | ParamsStylistic(v) => if ieq(v.version,1) andalso ieq(v.name,1249) then 0 else 1
      | ParamsSize(_) => 1 | ParamsVariant(_) => 1 | ParamsAbsent() => 1
  val ()=buf_free(b)
in errors end

fun variant(): int = let
  val b=ot_fixture_words("0000 04E1 04E2 04E3 0002 04E4")
  val t=@{code=1668689969}: OtTag
  val errors=case+ ot_feature_params_parse(b,t,params("0000 04E1 04E2 04E3 0002 04E4")) of
    | ~FeatureParamsRejected(e) => 1
    | ~FeatureParamsAccepted(p) => case+ p of
      | ParamsVariant(v) => if ieq(v.format,0) andalso ieq(v.label,1249)
        andalso ieq(v.tooltip,1250) andalso ieq(v.sample,1251)
        andalso ieq(v.named,2) andalso ieq(v.first,1252) then 0 else 1
      | ParamsSize(_) => 1 | ParamsStylistic(_) => 1 | ParamsAbsent() => 1
  val ()=buf_free(b)
in errors end

fun absent_tag(): int = let
  val b=ot_fixture_words("0001 0000")
  val t=@{code=1936928817}
  val errors=case+ ot_feature_params_parse(b,t,@{kind=ChildMissing(),span= @{offset=0,length=0}}) of
    | ~FeatureParamsRejected(e) => 1
    | ~FeatureParamsAccepted(p) => case+ p of | ParamsAbsent() => 0 | _ => 1
  val ()=buf_free(b)
in errors end

fun reject(s: string,t: int): int = let
  val b=ot_fixture_words(s)
  val tag=@{code=t}
  val errors=case+ ot_feature_params_parse(b,tag,params(s)) of
    | ~FeatureParamsRejected(e) => 0 | ~FeatureParamsAccepted(p) => 1
  val ()=buf_free(b)
in errors end

fun truncations {n:nat} .<n>. (n: int(n),words: int,tag: int,errors: int): int =
  if n = 0 then errors else let
    val total=words*2
    val rec cut {k:nat} .<k>. (left: int(k),b: !Buf,count: int,acc: int): int =
      if left = 0 then acc else let
        val ()=buf_set_len(b,8+2*count)
        val outcome=case+ ot_feature_params_parse(b,@{code=tag},ot_fixture_span(b)) of
          | ~FeatureParamsRejected(e) => 0 | ~FeatureParamsAccepted(p) => 1
        val expected=if ilt(count,words) then 0 else 1
      in cut(left-1,b,iadd(count,1),iadd(acc,if ieq(outcome,expected) then 0 else 1)) end
    val b=buf_make(iadd(8,total))
    val errors2=cut(airlock_span(1,total),b,0,0)
    val ()=buf_free(b)
  in iadd(errors,errors2) end

implement ot_test_feature_params() =
  size()+stylistic()+variant()+absent_tag()
  +reject("kern",1801810542)+reject("0002 04E1 04E2 04E3 0002 04E4",1668692281)
  +reject("0002 04E1",1936928817)+reject("0001 04E1",1936292453)
  +truncations(4,2,1936928817,0)
