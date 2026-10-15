#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/ot_feature_params.sats"
staload "data_font/ot_layout_features.sats"
staload "opentype_fixture.sats"
staload "ot_layout_contracts.sats"

(* Expected outcomes follow OpenType 1.9.1 field layouts; the rejection
   reasons are compared by code, not by string or by a magic integer. *)
fun reason_code(r: OtErrorReason): int = case+ r of
  | OtBounds() => 1 | OtFormat() => 2 | OtGlyphDomain() => 3 | OtOrder() => 4
  | OtCoverageIndex() => 5 | OtPadding() => 6 | OtReference() => 7
  | OtUnsupported() => 8 | OtCapacity() => 9
fun reason_is(a: OtErrorReason, b: OtErrorReason): bool = ieq(reason_code(a),reason_code(b))
fun pack4(a: int, b: int, c: int, d: int): int =
  iadd(iadd(imul(a,16777216),imul(b,65536)),iadd(imul(c,256),d))
fun tag_size(): OtTag = @{code=pack4(115,105,122,101)}
fun tag_ss01(): OtTag = @{code=pack4(115,115,48,49)}
fun tag_ss20(): OtTag = @{code=pack4(115,115,50,48)}
fun tag_ss21(): OtTag = @{code=pack4(115,115,50,49)}
fun tag_ssab(): OtTag = @{code=pack4(115,115,65,66)}
fun tag_cv01(): OtTag = @{code=pack4(99,118,48,49)}
fun tag_cv00(): OtTag = @{code=pack4(99,118,48,48)}
fun tag_cv0a(): OtTag = @{code=pack4(99,118,48,65)}
fun tag_kern(): OtTag = @{code=pack4(107,101,114,110)}
fun child_of(b: !Buf, length: int): OtChild = let val s=ot_fixture_span(b) in
  @{kind=ChildPresent(),span= @{offset=s.offset,length=length}} end

fun expect_reject(r: OtFeatureParamsRead, reason: OtErrorReason): int = case+ r of
  | ~FeatureParamsAccepted(_) => 1
  | ~FeatureParamsRejected(e) => if reason_is(e.reason,reason) then 0 else 1
fun expect_opaque(r: OtFeatureParamsRead): int = case+ r of
  | ~FeatureParamsRejected(_) => 1
  | ~FeatureParamsAccepted(p) => case+ p of | ParamsOpaque() => 0 | _ => 1
fun expect_absent(r: OtFeatureParamsRead): int = case+ r of
  | ~FeatureParamsRejected(_) => 1
  | ~FeatureParamsAccepted(p) => case+ p of | ParamsAbsent() => 0 | _ => 1

fun size_valid(): int = let
  val b=ot_fixture_words("0258 0003 07D0 0005 0028")
  val e=case+ ot_feature_params_parse(b,tag_size(),child_of(b,10)) of
    | ~FeatureParamsRejected(_) => 1
    | ~FeatureParamsAccepted(p) => case+ p of
      | ParamsSize(v) => if ieq(v.design,600) andalso ieq(v.subfamily,3)
        andalso ieq(v.name,2000) andalso ieq(v.rangeStart,5) andalso ieq(v.rangeEnd,40) then 0 else 1
      | _ => 1
  val ()=buf_free(b)
in e end

fun size_no_subfamily(): int = let
  val b=ot_fixture_words("0258 0000 0000 0000 0000")
  val e=case+ ot_feature_params_parse(b,tag_size(),child_of(b,10)) of
    | ~FeatureParamsRejected(_) => 1
    | ~FeatureParamsAccepted(p) => case+ p of
      | ParamsSize(v) => if ieq(v.design,600) andalso ieq(v.subfamily,0) then 0 else 1
      | _ => 1
  val ()=buf_free(b)
in e end

fun size_rejections(): int = let
  val zero=ot_fixture_words("0000 0003 07D0 0005 0028")
  val e1=expect_reject(ot_feature_params_parse(zero,tag_size(),child_of(zero,10)),OtFormat())
  val ()=buf_free(zero)
  val name=ot_fixture_words("0258 0003 0010 0005 0028")
  val e2=expect_reject(ot_feature_params_parse(name,tag_size(),child_of(name,10)),OtFormat())
  val ()=buf_free(name)
  val order=ot_fixture_words("0258 0003 07D0 0028 0005")
  val e3=expect_reject(ot_feature_params_parse(order,tag_size(),child_of(order,10)),OtOrder())
  val ()=buf_free(order)
  val short=ot_fixture_words("0258 0003 07D0 0005")
  val e4=expect_reject(ot_feature_params_parse(short,tag_size(),child_of(short,8)),OtBounds())
  val ()=buf_free(short)
in iadd(iadd(e1,e2),iadd(e3,e4)) end

fun stylistic_valid(): int = let
  val b=ot_fixture_words("0000 04E1")
  val e=case+ ot_feature_params_parse(b,tag_ss01(),child_of(b,4)) of
    | ~FeatureParamsRejected(_) => 1
    | ~FeatureParamsAccepted(p) => case+ p of
      | ParamsStylistic(v) => if ieq(v.version,0) andalso ieq(v.name,1249) then 0 else 1
      | _ => 1
  val ()=buf_free(b)
in e end

fun stylistic_minor(): int = let
  val b=ot_fixture_words("0002 04E1")
  val e=case+ ot_feature_params_parse(b,tag_ss20(),child_of(b,4)) of
    | ~FeatureParamsRejected(_) => 1
    | ~FeatureParamsAccepted(p) => case+ p of
      | ParamsStylistic(v) => if ieq(v.version,2) andalso ieq(v.name,1249) then 0 else 1
      | _ => 1
  val ()=buf_free(b)
in e end

fun stylistic_short(): int = let
  val b=ot_fixture_words("0000")
  val e=expect_reject(ot_feature_params_parse(b,tag_ss01(),child_of(b,2)),OtBounds())
  val ()=buf_free(b)
in e end

(* Valid cv01: format 0, labels 1249-1251, two named parameters from 1252,
   characters U+0041 and U+1F600 as uint24 values. *)
fun variant_valid(): int = let
  val b=ot_fixture_words("0000 04E1 04E2 04E3 0002 04E4 0002 0000 4101 F600")
  val e=case+ ot_feature_params_parse(b,tag_cv01(),child_of(b,20)) of
    | ~FeatureParamsRejected(_) => 1
    | ~FeatureParamsAccepted(p) => case+ p of
      | ParamsVariant(v) => if ieq(v.label,1249) andalso ieq(v.tooltip,1250)
        andalso ieq(v.sample,1251) andalso ieq(v.named,2) andalso ieq(v.first,1252)
        andalso ieq(v.charCount,2) then 0 else 1
      | _ => 1
  val ()=buf_free(b)
in e end

fun variant_rejections(): int = let
  val format=ot_fixture_words("0001 04E1 04E2 04E3 0002 04E4 0002 0000 4101 F600")
  val e1=expect_reject(ot_feature_params_parse(format,tag_cv01(),child_of(format,20)),OtFormat())
  val ()=buf_free(format)
  val orphan=ot_fixture_words("0000 04E1 04E2 04E3 0000 04E4 0000")
  val e2=expect_reject(ot_feature_params_parse(orphan,tag_cv01(),child_of(orphan,14)),OtFormat())
  val ()=buf_free(orphan)
  val surrogate=ot_fixture_words("0000 04E1 04E2 04E3 0002 04E4 0001 00D8 0000")
  val e3=expect_reject(ot_feature_params_parse(surrogate,tag_cv01(),child_of(surrogate,17)),OtFormat())
  val ()=buf_free(surrogate)
  val truncated=ot_fixture_words("0000 04E1 04E2 04E3 0002 04E4 0002 0000 4101")
  val e4=expect_reject(ot_feature_params_parse(truncated,tag_cv01(),child_of(truncated,18)),OtBounds())
  val ()=buf_free(truncated)
in iadd(iadd(e1,e2),iadd(e3,e4)) end

(* Every truncation of a valid 20-byte cv01 table: only the full length parses. *)
fun cut_one(b: !Buf, length: int): int =
  if ieq(length,20) then let val r=ot_feature_params_parse(b,tag_cv01(),child_of(b,length)) in
    case+ r of | ~FeatureParamsAccepted(_) => 0 | ~FeatureParamsRejected(_) => 1 end
  else let val r=ot_feature_params_parse(b,tag_cv01(),child_of(b,length)) in
    case+ r of | ~FeatureParamsAccepted(_) => 1 | ~FeatureParamsRejected(_) => 0 end
fun sweep {n:nat} .<n>. (n: int(n), b: !Buf): int =
  if n = 0 then 0 else iadd(cut_one(b,n-1),sweep(n-1,b))
fun truncations(): int = let
  val b=ot_fixture_words("0000 04E1 04E2 04E3 0002 04E4 0002 0000 4101 F600")
  val e=sweep(airlock_nat(21),b)
  val ()=buf_free(b)
in e end

fun opaque_tags(): int = let
  val kern=ot_fixture_words("1234 5678 9ABC DEF0 1122")
  val e1=expect_opaque(ot_feature_params_parse(kern,tag_kern(),child_of(kern,10)))
  val ()=buf_free(kern)
  val ss21=ot_fixture_words("0000 04E1")
  val e2=expect_opaque(ot_feature_params_parse(ss21,tag_ss21(),child_of(ss21,4)))
  val ()=buf_free(ss21)
  val ssab=ot_fixture_words("0000 04E1")
  val e3=expect_opaque(ot_feature_params_parse(ssab,tag_ssab(),child_of(ssab,4)))
  val ()=buf_free(ssab)
  val cv00=ot_fixture_words("0007 0007 0007 0007")
  val e4=expect_opaque(ot_feature_params_parse(cv00,tag_cv00(),child_of(cv00,8)))
  val ()=buf_free(cv00)
  val cv0a=ot_fixture_words("0007 0007 0007 0007")
  val e5=expect_opaque(ot_feature_params_parse(cv0a,tag_cv0a(),child_of(cv0a,8)))
  val ()=buf_free(cv0a)
in iadd(iadd(iadd(e1,e2),iadd(e3,e4)),e5) end

fun absent_and_invalid(): int = let
  val b=ot_fixture_words("0001 0000")
  val e1=expect_absent(ot_feature_params_parse(b,tag_size(),@{kind=ChildMissing(),span= @{offset=0,length=0}}))
  val e2=expect_reject(ot_feature_params_parse(b,tag_size(),@{kind=ChildInvalid(),span= @{offset=0,length=0}}),OtBounds())
  val ()=buf_free(b)
in iadd(e1,e2) end

staload "data_font/ot_feature_variations_types.sats"
staload "data_font/ot_feature_variations.sats"
staload "data_font/ot_item_variation_types.sats"
staload "data_font/ot_item_variation.sats"

(* Topology: a FeatureList with one feature record, whose FeatureParams
   offset (4) follows the feature table header. *)
fun info_of(b: !Buf): OtLayoutInfo = let val s=ot_fixture_span(b) in
  @{span=s,scripts= @{span=s,header=0,count=0},features= @{span=s,header=2,count=1},
    lookups= @{offset=0,length=0},lookupCount=0,
    variations= @{kind=ChildMissing(),span= @{offset=0,length=0}}} end
fun topo_accepted(words: string): int = let
  val b=ot_fixture_words(words)
  val e=case+ ot_features_validate(b,info_of(b)) of | ~Some_vt(_) => 1 | ~None_vt() => 0
  val ()=buf_free(b)
in e end
fun topo_rejected(words: string, reason: OtErrorReason): int = let
  val b=ot_fixture_words(words)
  val e=case+ ot_features_validate(b,info_of(b)) of
    | ~Some_vt(err) => if reason_is(err.reason,reason) then 0 else 1
    | ~None_vt() => 1
  val ()=buf_free(b)
in e end
fun topology(): int =
  topo_accepted("0001 7369 7A65 0008 0004 0000 0258 0003 07D0 0005 0028")
  +topo_rejected("0001 7369 7A65 0008 0004 0000 0258 0003 07D0 0005",OtBounds())
  +topo_rejected("0001 7369 7A65 0008 0004 0000 0258 0003 0010 0005 0028",OtFormat())
  +topo_accepted("0001 6B65 726E 0008 0004 0000 1234 5678 9ABC DEF0 1122")

fun fvar_test_eval(b: !Buf, vinfo: OtFeatureVariationsInfo): int = let
  val c_in = ot_fixture_words("2000")
  val c_out = ot_fixture_words("6000")
  val act_in = ot_feature_variations_active_subst(b, vinfo, c_in, 1)
  val act_out = ot_feature_variations_active_subst(b, vinfo, c_out, 1)
  val e1 = case+ act_in.kind of
    | ChildPresent() => let
        val alt = ot_feature_table_subst_find(b, act_in.span, 0)
      in case+ alt.kind of
        | ChildPresent() => if ieq(ot_u16(b, alt.span, 2), 1) andalso ieq(ot_u16(b, alt.span, 4), 5) then 0 else 1
        | _ => 1 end
    | _ => 1
  val e2 = case+ act_out.kind of | ChildMissing() => 0 | _ => 1
  val () = buf_free(c_in) and () = buf_free(c_out)
in iadd(e1, e2) end

fun fvar_cases(): int = let
  val b = ot_fixture_words("0001 0000 0000 0001 0000 0010 0000 0020 0001 0000 0006 0001 0000 0000 4000 0000 0001 0000 0001 0000 0000 000C 0000 0001 0005")
  val s = ot_fixture_span(b)
  val err = case+ ot_feature_variations_parse(b, s) of
    | ~FeatureVariationsRejected(_) => 1
    | ~FeatureVariationsAccepted(vinfo) => fvar_test_eval(b, vinfo)
  val () = buf_free(b)
in err end

fun ivar_test_eval(b: !Buf, store: OtItemVarStoreInfo): int = let
  val c_peak = ot_fixture_words("4000")
  val c_half = ot_fixture_words("2000")
  val c_zero = ot_fixture_words("0000")
  val d_peak0 = ot_item_var_store_delta(b, store, 0, 0, c_peak, 1)
  val d_peak1 = ot_item_var_store_delta(b, store, 0, 1, c_peak, 1)
  val d_half0 = ot_item_var_store_delta(b, store, 0, 0, c_half, 1)
  val d_half1 = ot_item_var_store_delta(b, store, 0, 1, c_half, 1)
  val d_zero = ot_item_var_store_delta(b, store, 0, 0, c_zero, 1)
  val ok = ieq(d_peak0, 100) andalso ieq(d_peak1, ~100) andalso ieq(d_half0, 50) andalso ieq(d_half1, ~50) andalso ieq(d_zero, 0)
  val () = buf_free(c_peak) and () = buf_free(c_half) and () = buf_free(c_zero)
in if ok then 0 else 1 end

fun ivar_cases(): int = let
  val b = ot_fixture_words("0001 0000 000C 0001 0000 001A 0001 0001 0000 4000 4000 0000 0000 0002 0001 0001 0000 0064 FF9C")
  val s = ot_fixture_span(b)
  val err = case+ ot_item_var_store_parse(b, s) of
    | ~ItemVarStoreRejected(_) => 1
    | ~ItemVarStoreAccepted(store) => ivar_test_eval(b, store)
  val () = buf_free(b)
in err end

implement layout_test_params() = let
  val size=size_valid()+size_no_subfamily()+size_rejections()
  val stylistic=stylistic_valid()+stylistic_minor()+stylistic_short()
  val variant=variant_valid()+variant_rejections()+truncations()
  val other=opaque_tags()+absent_and_invalid()+topology()
  val variations=fvar_cases()+ivar_cases()
  val ()=println!("event=ot_layout_params size_errors=",size," stylistic_errors=",stylistic,
    " variant_errors=",variant," other_errors=",other," variations_errors=",variations)
in size+stylistic+variant+other+variations end
