#include "data_font/opentype/shape/ot_shape_internal.hats"
fun result(t: OtShapeCountKind,count: int,e: OtError): OtShapeCount = @{kind=t,count=count,error=e}
fun walk{kind:int}{n:nat} .<n>. (left: int(n),b: !Buf,t: !OtLayoutTable(kind,0),c: OtShapeContext(kind),
  index: int,count: int,remaining: &int >> int): OtShapeCount =
  if left = 0 then result(ShapeCountReady(),count,ot_error(OtCapacity(),@{offset=0,length=0})) else let
    val stage=ot_shape_stage_of(c.domain,c.request.profile,index)
  in case+ ot_shape_plan(b,t,c,stage) of | ~PlanRejected(e) => result(ShapeCountRejected(),0,e)
    | ~PlanAccepted(p) => let
      val next=iadd(count,ot_plan_lookup_count(p))
      val fits=ot_shape_plan_cost(p,remaining) andalso ile(next,idiv(MAX_REC_FUEL,g0uint2int_size_int(sizeof<OtShapeLookup>)))
      val ()=ot_plan_dispose(p)
    in if not(fits) then let val info=ot_layout_info(t)
      in result(ShapeCountRejected(),0,ot_error(OtCapacity(),info.span)) end
      else walk(left-1,b,t,c,iadd(index,1),next,remaining) end end
implement ot_shape_measure(b,t,c,remaining) =
  walk(airlock_nat(ot_shape_stage_count(c.domain,c.request.profile)),b,t,c,0,0,remaining)
