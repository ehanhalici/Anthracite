staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/core/glyph_core_draft_types.sats"
fun glyph_core_draft_make{n:nat}(source: GlyphStorage(n),used: int): GlyphCoreDraft(n)
fun glyph_core_draft_commit{n:nat}(draft: GlyphCoreDraft(n)): GlyphStorage(n)
fun glyph_core_draft_rollback{n:nat}(draft: GlyphCoreDraft(n)): GlyphStorage(n)
