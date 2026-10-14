#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/ot_layout_features.sats"
staload "data_font/ot_layout_records.sats"
staload "data_font/ot_layout_language.sats"
staload "data_font/ot_layout_feature_set.sats"
staload "data_font/ot_layout_plan_work.sats"

fun select {n:nat} .<n>. (n: int(n),b: !Buf,info: OtLayoutInfo,l: OtLanguageInfo,
  set: !OtFeatureSet,selected: !Buf,i: int): void =
  if n = 0 then () else let
    val index=ot_u16(b,l.span,iadd(6,imul(i,2)))
    val tag=ot_record_tag(b,info.features,index)
    val ()=if ot_feature_set_contains(set,tag) then buf_set(selected,index,1) else ()
  in select(n-1,b,info,l,set,selected,iadd(i,1)) end

implement ot_plan_selection_requested(b,info,language,set) = let
  val selected=buf_make(info.features.count)
  val ()=case+ language.kind of
    | ChildMissing() => () | ChildInvalid() => ()
    | ChildPresent() => let val l=ot_language_info(b,language.span) in
      select(airlock_nat(l.count),b,info,l,set,selected,0) end
in selected end
implement ot_plan_selection(b,info,language,set) = let
  val selected=ot_plan_selection_requested(b,info,language,set)
  val ()=case+ language.kind of
    | ChildMissing() => () | ChildInvalid() => ()
    | ChildPresent() => let val l=ot_language_info(b,language.span) in
      if l.required.found then buf_set(selected,l.required.index,1) else () end
in selected end

fun cost {n:nat} .<n>. (n: int(n),b: !Buf,info: OtLayoutInfo,selected: !Buf,i: int,total: int): int =
  if n = 0 then total else let
    val extra=if ieq(buf_get(selected,i),0) then 0 else let val f=ot_feature_at(b,info,i) in iadd(f.count,1) end
  in if igt(extra,isub(MAX_REC_FUEL,total)) then ~1
    else cost(n-1,b,info,selected,iadd(i,1),iadd(total,extra)) end
implement ot_plan_reference_cost(b,info,selected) = cost(airlock_nat(info.features.count),b,info,selected,0,0)
