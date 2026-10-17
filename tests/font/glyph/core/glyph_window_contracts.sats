staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/context/ot_context_types.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/pass/glyph_pass_window_types.sats"
fun window_test_make(limits: OtContextLimits): GlyphContextWindow
fun window_test_gather(b: !Buf,m: !GlyphMetadata,run: !GlyphRun(1),options: GlyphWindowSelection,
  node: int,w: !GlyphContextWindow,remaining: &int >> _): GlyphWindowSpan
fun window_test_basic(): int
fun window_test_masks(): int
fun window_test_rejections(): int
fun window_test_associations(): int
