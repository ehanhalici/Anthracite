staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/ot_shape_types.sats"
(* Schedules borrow immutable face bytes. One font-scoped GSUB/GPOS graph can
   execute many schedules without reparsing/duplicating the graph. *)
fun ot_shape_schedule_parse{kind:int}(b: !Buf,t: !OtLayoutTable(kind,0),domain: OtLayoutDomain(kind),request: OtShapeRequest,
  masks: OtShapeMasks,font: int,glyphs: int): OtShapeRead(kind)
fun ot_shape_schedule_info{kind:int}(s: !OtShapeSchedule(kind)): OtShapeInfo
fun ot_shape_schedule_at{kind:int}(s: !OtShapeSchedule(kind),index: int): OtShapeLookup
fun ot_shape_schedule_dispose{kind:int}(s: OtShapeSchedule(kind)): void
