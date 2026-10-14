staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/gpos_mark_matrix_types.sats"
staload "data_font/gpos_mark_ligature_types.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/glyph_position_types.sats"
(* A single parsed subtable. Whole-lookup first-match priority is a separate
   scheduler responsibility. Missing GDEF classes are explicitly rejected. *)
fun glyph_position_mark_matrix{kind:int}(b: !Buf,table: !GposMarkMatrix(kind),metadata: !GlyphMetadata,
  positioned: GlyphPositioned(0),flags: OtLookupFlags,set: int,selection: GlyphSelection): GlyphPositionResult
fun glyph_position_mark_ligature(b: !Buf,table: !GposMarkLigature,metadata: !GlyphMetadata,
  positioned: GlyphPositioned(0),flags: OtLookupFlags,set: int,selection: GlyphSelection): GlyphPositionResult
