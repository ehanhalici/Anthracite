staload "mem.sats"
staload "data_font/glyph_position_types.sats"
staload "data_font/glyph_position_lookup_work.sats"
staload "data_font/glyph_position_lookup_graph_types.sats"
(* One owner per pass/stage, never per candidate glyph. It contains the single
   transactional position column and reusable graph traversal resources. *)
datavtype GlyphPositionLookupWorkspace(int) = {n:nat} GlyphPositionLookupWorkspace(n) of
  (GlyphPositionCache(n),GlyphPositionBases(n),GlyphPositionLookupGraphStack,GlyphPositionLookupGraphMap,Buf)
