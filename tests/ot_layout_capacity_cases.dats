#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "os/fs.sats"
staload "data_font/opentype_types.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/ot_layout_parse.sats"
staload "data_font/ot_layout_tags.sats"
staload "data_font/ot_layout_plan.sats"
staload "data_font/ot_layout_feature_set.sats"
staload "data_font/ot_layout_language.sats"
staload "opentype_fixture.sats"
staload "ot_layout_contracts.sats"

staload "data_font/ot_layout_header.sats"
staload "data_font/ot_layout_work.sats"
fun capacity(e: OtErrorReason): int = case+ e of
  | OtCapacity() => 0 | OtBounds() => 1 | OtFormat() => 1 | OtGlyphDomain() => 1
  | OtOrder() => 1 | OtCoverageIndex() => 1 | OtPadding() => 1 | OtReference() => 1 | OtUnsupported() => 1
fun rejected(result: Option_vt(OtError)): int = case+ result of
  | ~None_vt() => 1 | ~Some_vt(e) => capacity(e.reason)
fun accepted(result: Option_vt(OtError)): int = case+ result of
  | ~None_vt() => 0 | ~Some_vt(e) => 1
fun charge(): int = let
  var remaining: int=3
  val exact=ot_layout_charge(remaining,3)
  val empty=ot_layout_charge(remaining,0)
  val over=ot_layout_charge(remaining,1)
  val negative=ot_layout_charge(remaining,~1)
in if exact andalso empty andalso not(over) andalso not(negative) andalso ieq(remaining,0) then 0 else 1 end
fun shared(b: !Buf,info: OtLayoutInfo): int = let
  var remaining: int=27
  val first=accepted(ot_lookups_work(b,info,OtSubstitution(),@{classes=false,attachments=false,markSets=0},remaining))
  val second=accepted(ot_features_work(b,info,remaining))
  val third=rejected(ot_scripts_work(b,info,remaining))
in first+second+third end
fun low(b: !Buf,info: OtLayoutInfo): int = let
  var features: int=10
  var scripts: int=10
  var lookups: int=6
  var language: int=2
  val a=rejected(ot_features_work(b,info,features))
  val c=rejected(ot_scripts_work(b,info,scripts))
  val d=rejected(ot_lookups_work(b,info,OtSubstitution(),@{classes=false,attachments=false,markSets=0},lookups))
  val span= @{offset=52,length=128}
  val e=rejected(ot_language_work(b,span,info.features.count,language))
in a+c+d+e end
fun parsed(b: !Buf): int = case+ ot_layout_header_parse(b,ot_fixture_span(b)) of
  | ~HeaderRejected(e) => 1 | ~HeaderAccepted(info) => shared(b,info)+low(b,info)
implement layout_test_capacity() = let
  val b=layout_fixture()
  val errors=charge()+parsed(b)
  val ()=buf_free(b)
in errors end
