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
staload "data_font/ot_layout_plan_work.sats"

fun edges {n:nat} .<n>. (n: int(n),b: !Buf,f: OtFeatureInfo,counts: !Buf,seen: !Buf,
  feature: int,i: int,total: int): int =
  if n = 0 then total else let
    val lookup=ot_u16(b,f.span,iadd(4,imul(i,2)))
    val stamp=iadd(feature,1)
    val fresh=ine(buf_get32(seen,lookup),stamp)
    val ()=if fresh then buf_set32(counts,lookup,iadd(buf_get32(counts,lookup),1)) else ()
    val ()=buf_set32(seen,lookup,stamp)
  in edges(n-1,b,f,counts,seen,feature,iadd(i,1),iadd(total,if fresh then 1 else 0)) end

fun features {n:nat} .<n>. (n: int(n),b: !Buf,info: OtLayoutInfo,selected: !Buf,
  counts: !Buf,seen: !Buf,i: int,total: int): int =
  if n = 0 then total else let
    val next=if ieq(buf_get(selected,i),0) then total else let val f=ot_feature_at(b,info,i) in
      edges(airlock_nat(f.count),b,f,counts,seen,i,0,total) end
  in features(n-1,b,info,selected,counts,seen,iadd(i,1),next) end

implement ot_plan_count_edges(b,info,selected,counts,seen) =
  features(airlock_nat(info.features.count),b,info,selected,counts,seen,0,0)

fun prefixes {n:nat} .<n>. (n: int(n),counts: !Buf,offsets: !Buf,i: int,total: int): int = let
  val ()=buf_set32(offsets,i,total)
in if n = 0 then total else prefixes(n-1,counts,offsets,iadd(i,1),iadd(total,buf_get32(counts,i))) end
implement ot_plan_prefix(counts,offsets,n) = prefixes(airlock_nat(n),counts,offsets,0,0)

fun ids {n:nat} .<n>. (n: int(n),counts: !Buf,output: !Buf,i: int,index: int): int =
  if n = 0 then index else let
    val present=igt(buf_get32(counts,i),0)
    val ()=if present then buf_set32(output,index,i) else ()
  in ids(n-1,counts,output,iadd(i,1),iadd(index,if present then 1 else 0)) end
implement ot_plan_lookup_ids(counts,output,n) = ids(airlock_nat(n),counts,output,0,0)
