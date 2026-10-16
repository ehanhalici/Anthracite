#include "data_font/opentype/shape/ot_shape_internal.hats"
fun rows{kind:int}{n:nat} .<n>. (left: int(n),b: !Buf,t: !OtLayoutTable(kind,0),p: !OtStagePlan(kind),
  c: OtShapeContext(kind),s: !OtShapeSchedule(kind),stage: OtShapeStage,index: int,start: int): void =
  if left = 0 then () else let
    val row: OtShapeLookup= @{lookup=ot_plan_lookup(p,index),stage=stage,selection=ot_shape_plan_selection(b,t,p,c,index)}
    val ()=ot_shape_schedule_set(s,iadd(start,index),row)
  in rows(left-1,b,t,p,c,s,stage,iadd(index,1),start) end
fun walk{kind:int}{n:nat} .<n>. (left: int(n),b: !Buf,t: !OtLayoutTable(kind,0),c: OtShapeContext(kind),
  s: !OtShapeSchedule(kind),index: int,start: int,remaining: &int >> int): Option_vt(OtError) =
  if left = 0 then None_vt() else let val stage=ot_shape_stage_of(c.domain,c.request.profile,index)
  in case+ ot_shape_plan(b,t,c,stage) of | ~PlanRejected(e) => Some_vt(e)
    | ~PlanAccepted(p) => let
      val next=iadd(start,ot_plan_lookup_count(p))
      val valid=ot_shape_plan_cost(p,remaining)
      val ()=if valid then rows(airlock_nat(ot_plan_lookup_count(p)),b,t,p,c,s,stage,0,start) else ()
      val ()=ot_plan_dispose(p)
    in if valid then walk(left-1,b,t,c,s,iadd(index,1),next,remaining)
      else let val info=ot_layout_info(t) in Some_vt(ot_error(OtCapacity(),info.span)) end end end
implement ot_shape_fill(b,t,c,s,remaining) =
  walk(airlock_nat(ot_shape_stage_count(c.domain,c.request.profile)),b,t,c,s,0,0,remaining)
