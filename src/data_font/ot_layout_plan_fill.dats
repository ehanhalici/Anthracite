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

fun edges {n:nat} .<n>. (n: int(n),b: !Buf,f: OtFeatureInfo,cursors: !Buf,seen: !Buf,
  owners: !Buf,feature: int,i: int): void =
  if n = 0 then () else let
    val lookup=ot_u16(b,f.span,iadd(4,imul(i,2)))
    val fresh=ine(buf_get32(seen,lookup),iadd(feature,1))
    val at=buf_get32(cursors,lookup)
    val ()=if fresh then (buf_set32(owners,at,feature);buf_set32(cursors,lookup,iadd(at,1))) else ()
    val ()=buf_set32(seen,lookup,iadd(feature,1))
  in edges(n-1,b,f,cursors,seen,owners,feature,iadd(i,1)) end

fun features {n:nat} .<n>. (n: int(n),b: !Buf,info: OtLayoutInfo,selected: !Buf,
  cursors: !Buf,seen: !Buf,owners: !Buf,i: int): void =
  if n = 0 then () else let
    val ()=if ieq(buf_get(selected,i),0) then () else let val f=ot_feature_at(b,info,i) in
      edges(airlock_nat(f.count),b,f,cursors,seen,owners,i,0) end
  in features(n-1,b,info,selected,cursors,seen,owners,iadd(i,1)) end
implement ot_plan_fill(b,info,selected,cursors,seen,owners) =
  features(airlock_nat(info.features.count),b,info,selected,cursors,seen,owners,0)
