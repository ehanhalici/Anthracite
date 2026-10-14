staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/glyph_run_types.sats"
(* Immutable parent font bytes must outlive the metadata. Missing GDEF stays
   explicitly unclassified, not silently guessed to be base or mark. *)
fun glyph_metadata_parse(b: !Buf,gdef: OtChild,font: int,glyphs: int): GlyphMetadataRead
fun glyph_metadata_info(metadata: !GlyphMetadata): GlyphMetadataInfo
fun glyph_metadata_capabilities(metadata: !GlyphMetadata): OtGdefCapabilities
fun glyph_metadata_property(metadata: !GlyphMetadata,glyph: int): GlyphPropertyView
fun glyph_metadata_allows(b: !Buf,metadata: !GlyphMetadata,flags: OtLookupFlags,set: int,glyph: int): bool
fun glyph_metadata_dispose(metadata: GlyphMetadata): void
(* Opt-in fallback needs a Unicode-prepared run. Actual GDEF classes, including
   class zero, always take precedence. No Unicode class is cached by glyph ID. *)
fun glyph_metadata_unicode(metadata: GlyphMetadata): GlyphMetadata
fun glyph_metadata_has_classes(metadata: !GlyphMetadata): bool
fun glyph_metadata_run_ready(metadata: !GlyphMetadata,meta: GlyphRunMeta): bool
fun glyph_metadata_core_property(metadata: !GlyphMetadata,core: GlyphCore): GlyphPropertyView
fun glyph_metadata_allows_core(b: !Buf,metadata: !GlyphMetadata,flags: OtLookupFlags,set: int,core: GlyphCore): bool
