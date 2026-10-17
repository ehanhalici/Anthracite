staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/position/gpos_single_types.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/glyph/position/glyph_position_types.sats"
(* One payload kernel; the outer lookup scheduler supplies its effective flags
   and subtable priority. All resources borrow the same immutable font bytes.
   A failed pass returns the untouched scaled owner, including attachments. *)
fun glyph_position_single(b: !Buf,table: !GposSingle,metadata: !GlyphMetadata,
  positioned: GlyphPositioned(0),flags: OtLookupFlags,set: int,selection: GlyphSelection): GlyphPositionResult
