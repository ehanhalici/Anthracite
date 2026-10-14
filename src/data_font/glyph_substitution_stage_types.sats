staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/ot_substitution_graph_types.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/glyph_substitution_lookup_types.sats"
datavtype GlyphSubstitutionStage = GlyphSubstitutionStage of (OtSubstitutionGraph,Buf,GlyphSubstitutionOptions,int)
datavtype GlyphSubstitutionStageRead = SubStageAccepted of GlyphSubstitutionStage | SubStageRejected of OtError
datavtype GlyphSubstitutionStageResult = SubStageResult of (GlyphRun(1),GlyphPassStatus,int,int)
