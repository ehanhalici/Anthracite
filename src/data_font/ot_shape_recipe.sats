staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/ot_shape_types.sats"
staload "data_font/glyph_pass_types.sats"
fun ot_shape_stage_count{kind:int}(domain: OtLayoutDomain(kind),profile: OtShapeProfile): int
fun ot_shape_stage_of{kind:int}(domain: OtLayoutDomain(kind),profile: OtShapeProfile,index: int): OtShapeStage
fun ot_shape_stage_tags(request: OtShapeRequest,stage: OtShapeStage): string
fun ot_shape_feature_selection(tag: OtTag,masks: OtShapeMasks): GlyphSelection
fun ot_shape_masks_valid(masks: OtShapeMasks): bool
