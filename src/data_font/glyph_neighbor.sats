staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/glyph_neighbor_types.sats"
(* Logical-order neighbour, not visual/RTL motion. The current node is already
   selected by the outer lookup; only subsequent context nodes are filtered.
   Default-ignorable/ZWJ script policies and input feature masks are separate.
   Metadata and bytes must refer to the same immutable parent font. *)
fun glyph_neighbor{phase:int}(b: !Buf,metadata: !GlyphMetadata,run: !GlyphRun(phase),
  flags: OtLookupFlags,set: int,node: int,travel: GlyphTravel): GlyphNeighbor
