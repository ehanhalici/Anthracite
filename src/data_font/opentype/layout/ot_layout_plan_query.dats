#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_reader.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/layout/ot_layout_plan.sats"
implement ot_plan_lookup_count(plan) = let val+ OtStagePlan(ids,offsets,owners,n,m)=plan in n end
implement ot_plan_lookup(plan,index) = let val+ OtStagePlan(ids,offsets,owners,n,m)=plan in
  buf_get32(ids,airlock_below(index,airlock_pos(n))) end
implement ot_plan_feature_count(plan,index) = let
  val+ OtStagePlan(ids,offsets,owners,n,m)=plan
  val lookup=buf_get32(ids,airlock_below(index,airlock_pos(n)))
in isub(buf_get32(offsets,iadd(lookup,1)),buf_get32(offsets,lookup)) end
implement ot_plan_feature(plan,index,owner) = let
  val+ OtStagePlan(ids,offsets,owners,n,m)=plan
  val lookup=buf_get32(ids,airlock_below(index,airlock_pos(n)))
  val start=buf_get32(offsets,lookup)
  val count=isub(buf_get32(offsets,iadd(lookup,1)),start)
in buf_get32(owners,iadd(start,airlock_below(owner,airlock_pos(count)))) end
implement ot_plan_dispose(plan) = let val+ ~OtStagePlan(a,b,c,n,m)=plan in buf_free(a);buf_free(b);buf_free(c) end
implement ot_layout_dispose(table) = let val+ ~OtLayoutStructure(info)=table in () end
