staload "mem.sats"
staload "data_font/opentype/position_lookup/ot_position_graph_types.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/glyph/position/glyph_position_types.sats"
(* Whole-lookup atomicity includes all nested actions. Lookup references are
   resolved in the font-scoped graph; no nested call retains an exclusive
   cache-cell loan. Failed cycles/capacity/coordinates leave the run unchanged. *)
fun glyph_position_lookup_graph_lookup(b: !Buf,graph: !OtPositionGraph,metadata: !GlyphMetadata,
  positioned: GlyphPositioned(0),lookup: int,selection: GlyphSelection,
  direction: GlyphPositionDirection): GlyphPositionResult
