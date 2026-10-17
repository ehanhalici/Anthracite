#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_reader.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_text/unicode/unicode_sort.sats"
staload "data_font/opentype/layout/ot_layout_tags.sats"
staload "data_font/opentype/layout/ot_layout_feature_set.sats"

fun convert {n:nat} .<n>. (n: int(n),b: !Buf,s: OtSpan,index: int): bool =
  if n = 0 then true else let val tag=ot_tag_at(b,s,imul(index,4)) in
    if not(ot_tag_valid(tag.code)) then false else let val ()=buf_set32(b,index,tag.code) in
      convert(n-1,b,s,iadd(index,1)) end end

fun reject(b: Buf,reason: OtErrorReason): OtFeatureSetRead = let val ()=buf_free(b) in FeatureSetRejected(reason) end
implement ot_feature_set_parse(b) = let val size=buf_len(b) in
  if ine(imod(size,4),0) orelse igt(size,262140) then reject(b,OtBounds()) else let
    val count=idiv(size,4)
    val span= @{offset=0,length=size}
  in if not(convert(airlock_nat(count),b,span,0)) then reject(b,OtFormat()) else let
      val ()=word_rows_sort(b,count,1,0)
    in FeatureSetAccepted(OtFeatureSet(b,count)) end end end

extern fun set_exhausted(): int = "mac#anth_die_int"
fun find {fuel:nat} .<fuel>. (fuel: int(fuel),b: !Buf,code: int,lo: int,hi: int): int =
  if ige(lo,hi) then 0 else if fuel = 0 then set_exhausted() else let
    val mid=iadd(lo,idiv(isub(hi,lo),2))
    val value=buf_get32(b,mid)
  in if ilt(code,value) then find(fuel-1,b,code,lo,mid)
    else if igt(code,value) then find(fuel-1,b,code,iadd(mid,1),hi) else 1 end
implement ot_feature_set_contains(set,tag) = let val+ OtFeatureSet(b,n)=set in
  ieq(find(airlock_nat(iadd(n,1)),b,tag.code,0,n),1) end
implement ot_feature_set_dispose(set) = let val+ ~OtFeatureSet(b,n)=set in buf_free(b) end
