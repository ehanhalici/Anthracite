staload "mem.sats"
staload "data_font/ot_context_types.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/glyph_pass_window_types.sats"
staload "data_font/gsub_reverse_types.sats"
staload "data_font/gsub_single_types.sats"
fun glyph_window_reverse_match(b: !Buf,t: !GsubReverse,w: !GlyphContextWindow,span: GlyphWindowSpan): GsubSingleResult
fun glyph_window_make(limits: OtContextLimits): GlyphWindowRead
fun glyph_window_dispose(w: GlyphContextWindow): void
(* One reusable pair of native uint32 columns, allocated outside candidate
   traversal. Mask/association restrictions bound INPUT, never back/look text.
   Bytes, metadata and the borrowed run must belong to one immutable font. *)
fun glyph_window_gather{n:nat}(b: !Buf,m: !GlyphMetadata,s: !GlyphStorage(n),meta: GlyphRunMeta,
  options: GlyphWindowSelection,node: int,w: !GlyphContextWindow,remaining: &int >> _): GlyphWindowSpan
(* A graph reuses a maximum-sized owner, but each subtable retains its own
   input/look boundary. Lookahead must not acquire another table's mask or
   ligature-affinity restrictions. *)
fun glyph_window_gather_limits{n:nat}(b: !Buf,m: !GlyphMetadata,s: !GlyphStorage(n),meta: GlyphRunMeta,
  options: GlyphWindowSelection,node: int,w: !GlyphContextWindow,limits: OtContextLimits,
  remaining: &int >> _): GlyphWindowSpan
fun glyph_window_match{kind:int}(b: !Buf,p: !OtContextProgram(kind),w: !GlyphContextWindow,span: GlyphWindowSpan): OtContextMatch(kind)
fun glyph_window_node(w: !GlyphContextWindow,span: GlyphWindowSpan,sequence: int): int
