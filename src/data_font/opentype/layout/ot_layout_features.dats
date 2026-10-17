#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_reader.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/layout/ot_layout_records.sats"
staload "data_font/opentype/layout/ot_layout_features.sats"
staload "data_font/opentype/layout/ot_layout_work.sats"
staload "data_font/opentype/features/ot_feature_params.sats"
implement ot_feature_info(b,s) = let val count=ot_u16(b,s,2) in
  @{span=s,count=count,parameters=ot_optional_child(s,ot_u16(b,s,0),iadd(4,imul(count,2)))} end
implement ot_feature_at(b,info,index) = let val child=ot_record_child(b,info.features,index) in
  ot_feature_info(b,child.span) end

fun indices_valid {n:nat} .<n>. (n: int(n),b: !Buf,f: OtFeatureInfo,i: int,lookups: int): bool =
  if n = 0 then true else
    if ige(ot_u16(b,f.span,iadd(4,imul(i,2))),lookups) then false
    else indices_valid(n-1,b,f,iadd(i,1),lookups)

fun feature_params_check(b: !Buf,tag: OtTag,f: OtFeatureInfo): Option_vt(OtError) =
  case+ ot_feature_params_parse(b,tag,f.parameters) of
  | ~FeatureParamsRejected(e) => Some_vt(e)
  | ~FeatureParamsAccepted(params) => let val ()=ot_feature_params_dispose(params) in None_vt() end

fun feature_validate(b: !Buf,tag: OtTag,s: OtSpan,lookups: int,remaining: &int >> _): Option_vt(OtError) =
  if ilt(s.length,4) then Some_vt(ot_error(OtBounds(),s)) else let
    val f=ot_feature_info(b,s)
  in if not(ot_rows_fit(s,4,f.count,2)) orelse not(ot_child_valid(f.parameters)) then Some_vt(ot_error(OtBounds(),s))
    else if not(ot_layout_charge(remaining,iadd(f.count,1))) then Some_vt(ot_error(OtCapacity(),s))
    else if not(indices_valid(airlock_nat(f.count),b,f,0,lookups)) then Some_vt(ot_error(OtReference(),s))
    else feature_params_check(b,tag,f) end

fun validate {n:nat} .<n>. (n: int(n),b: !Buf,info: OtLayoutInfo,index: int,remaining: &int >> _): Option_vt(OtError) =
  if n = 0 then None_vt() else let val child=ot_record_child(b,info.features,index)
    val tag=ot_record_tag(b,info.features,index) in
    case+ feature_validate(b,tag,child.span,info.lookupCount,remaining) of
    | ~Some_vt(e) => Some_vt(e)
    | ~None_vt() => validate(n-1,b,info,iadd(index,1),remaining) end

staload "data_font/opentype/features/ot_feature_variations_types.sats"
staload "data_font/opentype/features/ot_feature_variations.sats"

implement ot_features_work(b,info,remaining) =
  if not(ot_layout_charge(remaining,info.features.count)) then Some_vt(ot_error(OtCapacity(),info.features.span))
  else
  if not(ot_records_repeated(b,info.features)) then Some_vt(ot_error(OtOrder(),info.features.span))
  else case+ validate(airlock_nat(info.features.count),b,info,0,remaining) of
    | ~Some_vt(e) => Some_vt(e)
    | ~None_vt() => ot_feature_variations_validate(b,info,remaining)

implement ot_features_validate(b,info) = let var remaining: int=MAX_REC_FUEL in
  ot_features_work(b,info,remaining) end
