staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/ot_position_graph_types.sats"
staload "data_font/glyph_metadata_types.sats"
staload "ot_context_contracts.sats"
fun position_context_fixture(first: string,second: string,third: string): Buf
fun position_context_parse(b: !Buf,m: !GlyphMetadata): OtPositionGraph
fun position_context_basic(): int
fun position_context_nested(): int
fun position_context_rollback(): int
fun position_context_cache(): int
fun position_context_stress(): int
fun position_context_program(which: ContextFixture): Buf
fun position_context_encodings(): int
fun position_context_order(): int
