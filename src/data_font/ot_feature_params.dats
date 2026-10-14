#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/ot_feature_params.sats"

fun size(b: !Buf,s: OtSpan): OtFeatureParamsRead =
  if ilt(s.length,8) then FeatureParamsRejected(ot_error(OtBounds(),s))
  else FeatureParamsAccepted(ParamsSize(@{design=ot_u16(b,s,0),subfamily=ot_u16(b,s,2),
    name=ot_u16(b,s,4),record=ot_u16(b,s,6)}))

fun stylistic(b: !Buf,s: OtSpan): OtFeatureParamsRead =
  if ilt(s.length,4) then FeatureParamsRejected(ot_error(OtBounds(),s))
  else if ine(ot_u16(b,s,0),1) then FeatureParamsRejected(ot_error(OtFormat(),s))
  else FeatureParamsAccepted(ParamsStylistic(@{version=1,name=ot_u16(b,s,2)}))

fun variant(b: !Buf,s: OtSpan): OtFeatureParamsRead = let
  val format=ot_u16(b,s,0)
in if ilt(s.length,10) then FeatureParamsRejected(ot_error(OtBounds(),s))
  else if igt(format,1) then FeatureParamsRejected(ot_error(OtFormat(),s))
  else FeatureParamsAccepted(ParamsVariant(@{format=format,label=ot_u16(b,s,2),
    tooltip=ot_u16(b,s,4),sample=ot_u16(b,s,6),named=ot_u16(b,s,8),
    first=if ieq(format,1) then 0 else ot_u16(b,s,10)})) end

fun top(tag: OtTag): int = airlock_nat(idiv(tag.code,65536))
fun size_tag(tag: OtTag): bool = ieq(tag.code,1936292453)
fun variant_tag(tag: OtTag): bool = let val c=tag.code in ige(c,1668689969) andalso ile(c,1668692281) end
fun stylistic_tag(tag: OtTag): bool = ieq(top(tag),29555)

implement ot_feature_params_parse(b,tag,params) = case+ params.kind of
  | ChildMissing() => FeatureParamsAccepted(ParamsAbsent())
  | ChildInvalid() => FeatureParamsRejected(ot_error(OtBounds(),params.span))
  | ChildPresent() => let val s=params.span
    in if not(ot_span_valid(b,s)) orelse ilt(s.length,2) then FeatureParamsRejected(ot_error(OtBounds(),s))
      else if size_tag(tag) then size(b,s)
      else if stylistic_tag(tag) then stylistic(b,s)
      else if variant_tag(tag) then variant(b,s)
      else FeatureParamsRejected(ot_error(OtFormat(),s)) end
