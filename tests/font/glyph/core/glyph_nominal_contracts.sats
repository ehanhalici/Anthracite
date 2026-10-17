staload "mem.sats"
staload "data_font/sfnt/sfnt.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_text/utf8/utf8.sats"
staload "data_text/unicode/unicode_db.sats"
staload "data_text/unicode/unicode_property.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/opentype/sequence_lookup/ot_sequence_lookup_types.sats"
staload "data_text/arabic/joining/arabic_join_types.sats"
fun nominal_test_table(b: !Buf,info: SfntInfo,index: int): OtSequenceLookup(2)
fun nominal_test_metadata(b: !Buf,info: SfntInfo): GlyphMetadata
fun nominal_test_mask(): ArabicMaskPlan
fun nominal_test_bytes(source: string): Buf
fun nominal_test_decode(b: !Buf): ScalarText
fun nominal_test_run(face: !SfntFace,db: !UnicodeDb,text: !ScalarText): GlyphRun(0)
fun nominal_test_mixed(face: !SfntFace,db: !UnicodeDb): int
fun nominal_test_malformed(face: !SfntFace,db: !UnicodeDb): int
fun nominal_test_stress(face: !SfntFace,db: !UnicodeDb): int
fun nominal_test_arabic(face: !SfntFace,db: !UnicodeDb,joining: !PropertyMap(3)): int
fun nominal_test_arabic_run(face: !SfntFace,db: !UnicodeDb,text: !ScalarText,joining: !PropertyMap(3),errors: &int >> _): GlyphRun(1)
fun nominal_test_fonts(latin: string,arabic: string,unicode: string,joining: string): int
fun nominal_test_file(face: !SfntFace,db: !UnicodeDb,path: string): int
