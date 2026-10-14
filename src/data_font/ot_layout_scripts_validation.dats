#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/ot_layout_records.sats"
staload "data_font/ot_layout_tags.sats"
staload "data_font/ot_layout_language.sats"
staload "data_font/ot_layout_work.sats"

fun languages {n:nat} .<n>. (n: int(n),b: !Buf,r: OtRecordList,index: int,features: int,remaining: &int >> _): Option_vt(OtError) =
  if n = 0 then None_vt() else let val child=ot_record_child(b,r,index) in
    case+ ot_language_work(b,child.span,features,remaining) of
    | ~Some_vt(e) => Some_vt(e) | ~None_vt() => languages(n-1,b,r,iadd(index,1),features,remaining) end

fun default_language(b: !Buf,r: OtRecordList,tag: OtTag,features: int,remaining: &int >> _): Option_vt(OtError) = let
  val child=ot_optional_child(r.span,ot_u16(b,r.span,0),iadd(4,imul(r.count,6)))
  val default=ot_tag_default()
in case+ child.kind of
  | ChildInvalid() => Some_vt(ot_error(OtBounds(),r.span))
  | ChildMissing() => if ieq(tag.code,default.code) then Some_vt(ot_error(OtReference(),r.span)) else None_vt()
  | ChildPresent() => ot_language_work(b,child.span,features,remaining) end

fun script(b: !Buf,s: OtSpan,tag: OtTag,features: int,remaining: &int >> _): Option_vt(OtError) =
  if ilt(s.length,4) then Some_vt(ot_error(OtBounds(),s)) else let val r=ot_record_list(b,s,4) in
    if not(ot_layout_charge(remaining,iadd(r.count,1))) then Some_vt(ot_error(OtCapacity(),s))
    else if not(ot_records_unique(b,r)) then Some_vt(ot_error(OtOrder(),s)) else
      case+ default_language(b,r,tag,features,remaining) of
      | ~Some_vt(e) => Some_vt(e) | ~None_vt() => languages(airlock_nat(r.count),b,r,0,features,remaining) end

fun scripts {n:nat} .<n>. (n: int(n),b: !Buf,info: OtLayoutInfo,index: int,remaining: &int >> _): Option_vt(OtError) =
  if n = 0 then None_vt() else let val child=ot_record_child(b,info.scripts,index) in
    case+ script(b,child.span,ot_record_tag(b,info.scripts,index),info.features.count,remaining) of
    | ~Some_vt(e) => Some_vt(e) | ~None_vt() => scripts(n-1,b,info,iadd(index,1),remaining) end

implement ot_scripts_work(b,info,remaining) =
  if not(ot_layout_charge(remaining,info.scripts.count)) then Some_vt(ot_error(OtCapacity(),info.scripts.span))
  else if not(ot_records_unique(b,info.scripts)) then Some_vt(ot_error(OtOrder(),info.scripts.span))
  else scripts(airlock_nat(info.scripts.count),b,info,0,remaining)

implement ot_scripts_validate(b,info) = let var remaining: int=MAX_REC_FUEL in
  ot_scripts_work(b,info,remaining) end
