staload "mem.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/gsub_single_types.sats"
(* A primitive pass, not an outer lookup scheduler. The caller supplies its
   eligibility mask after lookup filtering. Font bytes stay immutable and
   must be the same parent used to parse table. Match count includes identities.
   A mismatched glyph domain returns the run untouched before any mutation. *)
fun glyph_pass_single(b: !Buf,table: !GsubSingle,run: GlyphRun(1),
  selection: GlyphSelection): GlyphPassResult(1)
