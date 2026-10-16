#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "os/fs.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/layout/ot_layout_parse.sats"
staload "data_font/opentype/layout/ot_layout_tags.sats"
staload "data_font/opentype/layout/ot_layout_plan.sats"
staload "data_font/opentype/layout/ot_layout_feature_set.sats"
staload "data_font/opentype/layout/ot_layout_language.sats"
staload "font/opentype/tables/opentype_fixture.sats"
staload "font/opentype/layout/ot_layout_contracts.sats"
staload "font/resources/font_fixture.sats"

fun membership(set: !OtFeatureSet): int =
  if not(ot_feature_set_contains(set,layout_tag("aern"))) orelse
    not(ot_feature_set_contains(set,layout_tag("zern"))) orelse
    not(ot_feature_set_contains(set,layout_tag("kern"))) orelse
    ot_feature_set_contains(set,layout_tag("bern")) then 1 else 0
fun accepted(): int = case+ ot_feature_set_parse(layout_bytes("zernkernaernkernaern")) of
  | ~FeatureSetRejected(e) => 1 | ~FeatureSetAccepted(set) => let
    val errors=membership(set) val ()=ot_feature_set_dispose(set) in errors end
fun rejected(s: string): int = case+ ot_feature_set_parse(layout_bytes(s)) of
  | ~FeatureSetRejected(e) => 0 | ~FeatureSetAccepted(set) => let
    val ()=ot_feature_set_dispose(set) in 1 end
fun bad_tag(s: string): int = case+ ot_tag_of_string(s) of
  | ~None_vt() => 0 | ~Some_vt(tag) => 1
fun empty(): int = case+ ot_feature_set_parse(layout_bytes("")) of
  | ~FeatureSetRejected(e) => 1 | ~FeatureSetAccepted(set) => let
    val found=ot_feature_set_contains(set,layout_tag("kern"))
    val ()=ot_feature_set_dispose(set)
  in if found then 1 else 0 end
fun oversized(): int = let val b=buf_make(262144) val ()=buf_set_len(b,262144) in
  case+ ot_feature_set_parse(b) of
  | ~FeatureSetRejected(e) => 0 | ~FeatureSetAccepted(set) => let val ()=ot_feature_set_dispose(set) in 1 end end
fun stress_tag_of(index: int): OtTag = case+ imod(index,3) of
  | 0 => layout_tag("zern") | 1 => layout_tag("aern") | _ => layout_tag("kern")
fun tags {n:nat} .<n>. (n: int(n),b: !Buf,i: int): void =
  if n = 0 then () else let
    val tag=stress_tag_of(i)
    val ()=fixture_put32(b,imul(i,4),tag.code)
  in tags(n-1,b,iadd(i,1)) end
fun maximum(): int = let
  val b=buf_make(262140)
  val ()=tags(WORD16_MAX_VALUE,b,0)
  val ()=buf_set_len(b,262140)
in case+ ot_feature_set_parse(b) of
  | ~FeatureSetRejected(e) => 1 | ~FeatureSetAccepted(set) => let
    val errors=membership(set) val ()=ot_feature_set_dispose(set) in errors end end
implement layout_test_sets() = accepted()+empty()+oversized()+rejected("lig")+rejected("liga?")+
  rejected("\001iga")+bad_tag("lig")+bad_tag("ligaa")+bad_tag("\001iga")+maximum()
