#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/ot_layout_tags.sats"
staload "data_font/ot_layout_records.sats"
implement ot_record_list(b,s,header) =
  @{span=s,header=header,count=ot_u16(b,s,isub(header,2))}
implement ot_record_tag(b,r,index) = ot_tag_at(b,r.span,iadd(r.header,imul(index,6)))
implement ot_record_child(b,r,index) = ot_optional_child(r.span,
  ot_u16(b,r.span,iadd(iadd(r.header,imul(index,6)),4)),iadd(r.header,imul(r.count,6)))

fun ordered {n:nat} .<n>. (n: int(n),b: !Buf,r: OtRecordList,i: int,previous: int): bool =
  if n = 0 then true else let
    val tag=ot_record_tag(b,r,i)
    val child=ot_record_child(b,r,i)
  in if not(ot_tag_valid(tag.code)) orelse ilt(tag.code,previous) then false else
    case+ child.kind of
    | ChildMissing() => false | ChildInvalid() => false
    | ChildPresent() => ordered(n-1,b,r,iadd(i,1),tag.code) end

fun distinct {n:nat} .<n>. (n: int(n),b: !Buf,r: OtRecordList,i: int,previous: int): bool =
  if n = 0 then true else let val tag=ot_record_tag(b,r,i) in
    if ile(tag.code,previous) then false else distinct(n-1,b,r,iadd(i,1),tag.code) end

implement ot_records_repeated(b,r) = ot_rows_fit(r.span,r.header,r.count,6)
  andalso ordered(airlock_nat(r.count),b,r,0,~1)
implement ot_records_unique(b,r) = ot_records_repeated(b,r)
  andalso distinct(airlock_nat(r.count),b,r,0,~1)

extern fun records_exhausted(): int = "mac#anth_die_int"
fun find {fuel:nat} .<fuel>. (fuel: int(fuel),b: !Buf,r: OtRecordList,tag: OtTag,lo: int,hi: int): int =
  if ige(lo,hi) then ~1 else if fuel = 0 then records_exhausted() else let
    val mid=iadd(lo,idiv(isub(hi,lo),2))
    val value=ot_record_tag(b,r,mid)
  in if ilt(tag.code,value.code) then find(fuel-1,b,r,tag,lo,mid)
    else if igt(tag.code,value.code) then find(fuel-1,b,r,tag,iadd(mid,1),hi) else mid end
implement ot_record_find(b,r,tag) = let val index=find(airlock_nat(iadd(r.count,1)),b,r,tag,0,r.count) in
  @{found=ige(index,0),index=if ige(index,0) then index else 0} end
