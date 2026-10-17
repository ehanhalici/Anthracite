staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/substitution/gsub_ligature_types.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
(* Font-aware GSUB 4. The caller keeps immutable font bytes alive. This pass
   preserves source spans and attachment component history, and commits only
   after the complete pass succeeds. Default-ignorable script policy is a
   separate scheduler responsibility. *)
fun glyph_pass_ligature(b: !Buf,t: !GsubLigatures,metadata: !GlyphMetadata,run: GlyphRun(1),
  flags: OtLookupFlags,set: int,selection: GlyphSelection): GlyphPassResult(1)
