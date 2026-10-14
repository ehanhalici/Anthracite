staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/gdef_types.sats"
fun gdef_marks_parse(b: !Buf,header: GdefHeaderInfo,glyphs: int): GdefMarksRead
fun gdef_mark_contains(b: !Buf,sets: !GdefMarkSets,index: int,glyph: int): bool
fun gdef_mark_set_count(sets: !GdefMarkSets): int
fun gdef_marks_dispose(sets: GdefMarkSets): void
