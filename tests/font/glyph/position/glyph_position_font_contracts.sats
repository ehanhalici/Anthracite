staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/position/gpos_mark_matrix_types.sats"
staload "data_font/glyph/position/glyph_position_types.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/opentype/position_lookup/ot_position_lookup_types.sats"
staload "data_font/glyph/position/glyph_position_stage_types.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/sfnt/sfnt.sats"
staload "data_text/unicode/unicode_db.sats"
staload "data_text/unicode/unicode_property.sats"
datavtype PositionFontTable = PositionFontTable of (GposMarkMatrix(4),OtLookupFlags,int)
fun position_font_table(b: !Buf,info: SfntInfo,index: int): PositionFontTable
fun position_font_lookup(b: !Buf,info: SfntInfo,index: int): OtPositionLookup
fun position_font_stage(b: !Buf,info: SfntInfo,m: !GlyphMetadata): GlyphPositionStage
fun position_test_stage_build(b: !Buf,span: OtSpan,m: !GlyphMetadata): GlyphPositionStage
fun position_font_initialized(face: !SfntFace,run: GlyphRun(2),ppem: int): GlyphPositioned(0)
fun position_font_apply(face: !SfntFace,db: !UnicodeDb,joining: !PropertyMap(3),ppem: int,oracle: string): int
fun position_font_scheduled(b: !Buf,info: SfntInfo,m: !GlyphMetadata,p: GlyphPositioned(0),errors: &int >> int): GlyphPositioned(0)
