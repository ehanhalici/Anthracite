staload "mem.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/opentype/substitution_graph/ot_substitution_graph_types.sats"
fun substitution_engine_fixture(first: string,second: string,third: string): Buf
fun substitution_engine_parse(b: !Buf): OtSubstitutionGraph
fun substitution_engine_take(result: GlyphPassResult(1),matches: int,errors: &int >> int): GlyphRun(1)
fun substitution_engine_encodings(): int
fun substitution_engine_mutations(): int
fun substitution_engine_rollback(): int
fun substitution_engine_priority(): int
fun substitution_engine_stress(): int
