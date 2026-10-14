staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/gpos_cursive_types.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/glyph_position_types.sats"
(* Lookup RightToLeft chooses the cross-axis attachment root; paragraph
   direction separately chooses horizontal advance adjustments. *)
fun glyph_position_cursive(b: !Buf,table: !GposCursive,metadata: !GlyphMetadata,positioned: GlyphPositioned(0),
  flags: OtLookupFlags,set: int,selection: GlyphSelection,direction: GlyphPositionDirection): GlyphPositionResult
