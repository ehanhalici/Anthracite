#include "data_font/opentype/shape/ot_shape_internal.hats"
fun merge(a: GlyphSelection,b: GlyphSelection): GlyphSelection = case+ a.kind of
  | GlyphAll() => a | GlyphMasked() => (case+ b.kind of
    | GlyphAll() => b | GlyphMasked() => @{kind=GlyphMasked(),mask=a.mask lor b.mask})
fun owner{kind:int}(b: !Buf,t: !OtLayoutTable(kind,0),c: OtShapeContext(kind),index: int): GlyphSelection =
  if c.required.found andalso ieq(index,c.required.index) then @{kind=GlyphAll(),mask=0u}
  else let val info=ot_layout_info(t)
  in ot_shape_feature_selection(ot_record_tag(b,info.features,index),c.masks) end
fun walk{kind:int}{n:nat} .<n>. (left: int(n),b: !Buf,t: !OtLayoutTable(kind,0),p: !OtStagePlan(kind),
  c: OtShapeContext(kind),index: int,at: int,selection: GlyphSelection): GlyphSelection =
  if left = 0 then selection else let val selected=owner(b,t,c,ot_plan_feature(p,index,at))
  in walk(left-1,b,t,p,c,index,iadd(at,1),merge(selection,selected)) end
implement ot_shape_plan_selection(b,t,p,c,index) =
  walk(airlock_nat(ot_plan_feature_count(p,index)),b,t,p,c,index,0,@{kind=GlyphMasked(),mask=0u})
implement ot_shape_plan_cost(p,remaining) = let val+ OtStagePlan(ids,offsets,owners,count,total)=p
  val cost=iadd(count,total)
in if igt(cost,remaining) then false else let val ()=remaining := isub(remaining,cost) in true end end
