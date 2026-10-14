staload "mem.sats"
staload "data_font/sfnt.sats"
staload "data_text/unicode_db.sats"
staload "data_text/unicode_property.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/ot_shape_types.sats"
fun shape_test_fixture(required: int,last: string): Buf
fun shape_test_schedule(b: !Buf,m: !GlyphMetadata,required: int): OtShapeSchedule(1)
fun shape_test_masks(): OtShapeMasks
fun shape_test_request(): OtShapeRequest
fun shape_test_run(errors: &int >> int): GlyphRun(1)
fun shape_test_cases(): int
fun shape_test_font(face: !SfntFace,db: !UnicodeDb,joining: !PropertyMap(3)): int
fun shape_test_execution(): int
