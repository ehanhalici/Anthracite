staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/shape/ot_shape_types.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/opentype/layout/ot_layout_plan.sats"
typedef OtShapeContext(kind:int) = @{domain=OtLayoutDomain(kind),request=OtShapeRequest,masks=OtShapeMasks,language=OtChild,required=OtIndex,requiredStage=OtShapeStage}
datatype OtShapeCountKind = ShapeCountReady | ShapeCountRejected
typedef OtShapeCount = @{kind=OtShapeCountKind,count=int,error=OtError}
fun ot_shape_stage_equal(a: OtShapeStage,b: OtShapeStage): bool
fun ot_shape_context{kind:int}(b: !Buf,t: !OtLayoutTable(kind,0),domain: OtLayoutDomain(kind),r: OtShapeRequest,masks: OtShapeMasks): OtShapeContext(kind)
fun ot_shape_plan{kind:int}(b: !Buf,t: !OtLayoutTable(kind,0),c: OtShapeContext(kind),stage: OtShapeStage): OtPlanRead(kind)
fun ot_shape_measure{kind:int}(b: !Buf,t: !OtLayoutTable(kind,0),c: OtShapeContext(kind),remaining: &int >> int): OtShapeCount
fun ot_shape_fill{kind:int}(b: !Buf,t: !OtLayoutTable(kind,0),c: OtShapeContext(kind),s: !OtShapeSchedule(kind),
  remaining: &int >> int): Option_vt(OtError)
fun ot_shape_schedule_make{kind:int}(count: int,font: int,glyphs: int): OtShapeSchedule(kind)
fun ot_shape_schedule_set{kind:int}(s: !OtShapeSchedule(kind),index: int,row: OtShapeLookup): void
fun ot_shape_plan_cost{kind:int}(plan: !OtStagePlan(kind),remaining: &int >> int): bool
fun ot_shape_plan_selection{kind:int}(b: !Buf,t: !OtLayoutTable(kind,0),p: !OtStagePlan(kind),
  c: OtShapeContext(kind),index: int): GlyphSelection
