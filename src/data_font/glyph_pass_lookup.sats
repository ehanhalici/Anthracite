staload "mem.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/ot_single_lookup_types.sats"
(* One cached SingleSubst lookup, including current-glyph GDEF filtering and
   first-subtable priority. Font metadata, lookup and bytes must share the same
   immutable parent font. Domain/reference/work-capacity failures are detected
   before mutation. This does not schedule script stages or contextual lookups. *)
fun glyph_pass_lookup(b: !Buf,lookup: !OtSingleLookup,metadata: !GlyphMetadata,
  run: GlyphRun(1),selection: GlyphSelection): GlyphPassResult(1)
