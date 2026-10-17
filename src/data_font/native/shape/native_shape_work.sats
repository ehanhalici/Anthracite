staload "mem.sats"
staload "data_font/sfnt/sfnt.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/shape/ot_shape_types.sats"
staload "data_font/native/shape/native_shape_types.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/glyph/substitution/glyph_substitution_stage_types.sats"
staload "data_font/glyph/position/glyph_position_stage_types.sats"
staload "data_font/glyph/position/glyph_position_types.sats"
staload "data_text/utf8/utf8.sats"
staload "data_text/arabic/joining/arabic_join_types.sats"
fun native_shape_sub_cache(b: !Buf,info: SfntInfo,m: !GlyphMetadata,font: int): NativeSubRead
fun native_shape_pos_cache(b: !Buf,info: SfntInfo,m: !GlyphMetadata,font: int): NativePosRead
fun native_shape_sub_dispose(t: NativeSubstitution): void
fun native_shape_pos_dispose(t: NativePositioning): void
fun native_shape_sub_plan(b: !Buf,t: !NativeSubstitution,info: NativePlanInfo): NativeSubPlanRead
fun native_shape_pos_plan(b: !Buf,t: !NativePositioning,info: NativePlanInfo): NativePosPlanRead
fun native_shape_sub_plan_dispose(t: NativeSubPlan): void
fun native_shape_pos_plan_dispose(t: NativePosPlan): void
fun native_shape_direction(r: OtShapeRequest): GlyphPositionDirection
fun native_shape_error(reason: NativeShapeFailure): NativeShapeError
fun native_shape_prepare(data: !NativeShapeData,plan: !NativeShapePlan,context: ArabicContext,run: GlyphRun(0)): GlyphRun(1)
fun native_shape_substitute(b: !Buf,cache: !NativeShapeCache,plan: !NativeShapePlan,run: GlyphRun(1)): GlyphSubstitutionStageResult
fun native_shape_position(b: !Buf,cache: !NativeShapeCache,plan: !NativeShapePlan,p: GlyphPositioned(0)): GlyphPositionStageResult
fun native_shape_positioned(b: !Buf,info: SfntInfo,cache: !NativeShapeCache,plan: !NativeShapePlan,
  run: GlyphRun(1),scale: NativeShapeScale): NativeShapeRead
fun native_shape_clear_advances(cache: !NativeShapeCache,p: GlyphPositioned(0)): GlyphPositioned(0)
fun native_shape_profile_equal(a: OtShapeProfile,b: OtShapeProfile): bool
