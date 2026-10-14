staload "mem.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/gsub_single_types.sats"
staload "data_font/opentype_types.sats"
staload "data_font/glyph_metadata_types.sats"
fun glyph_pass_domain_check(meta: GlyphRunMeta,metadata: !GlyphMetadata,glyphs: int,
  flags: OtLookupFlags,markSet: int,count: int): GlyphPassStatus
fun glyph_pass_selected(selection: GlyphSelection,mask: uint): bool
fun glyph_pass_single_walk{n:nat}(b: !Buf,table: !GsubSingle,s: !GlyphStorage(n),
  meta: GlyphRunMeta,selection: GlyphSelection): int
