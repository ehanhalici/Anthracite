staload "mem.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/opentype/sequence_lookup/ot_sequence_lookup_types.sats"
(* Atomic preflight: font/GDEF/work/capacity/association failures preserve the
   incoming run. Multiple results retain original scalar/bytes/cluster/masks.
   Newly produced nodes are not revisited by the same lookup. Expanding a
   previously associated node currently rejects with GlyphPassReference;
   multiplication/ligature-affinity semantics must not be guessed. *)
fun glyph_pass_multiple(b: !Buf,lookup: !OtSequenceLookup(2),metadata: !GlyphMetadata,
  run: GlyphRun(1),selection: GlyphSelection): GlyphPassResult(1)
fun glyph_pass_alternate(b: !Buf,lookup: !OtSequenceLookup(3),metadata: !GlyphMetadata,
  run: GlyphRun(1),selection: GlyphSelection,choice: int): GlyphPassResult(1)
