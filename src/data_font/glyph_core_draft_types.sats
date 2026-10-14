staload "data_font/glyph_run_types.sats"
(* Only the core column is transactional. Links/positions move into the draft
   without copying and must not be edited by a core-only substitution kernel. *)
datavtype GlyphCoreDraft(int) = {n:nat}{l:addr} GlyphCoreDraft(n) of (arrayptr(GlyphCore,l,n),GlyphStorage(n))
