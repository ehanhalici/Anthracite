staload "mem.sats"
staload "data_font/ot_position_lookup_types.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/glyph_position_types.sats"
(* One complete cached lookup, with first-matching-subtable priority and
   PairPos continuation. All changes are committed together or rolled back. *)
fun glyph_position_lookup(b: !Buf,lookup: !OtPositionLookup,metadata: !GlyphMetadata,positioned: GlyphPositioned(0),
  selection: GlyphSelection,direction: GlyphPositionDirection): GlyphPositionResult
