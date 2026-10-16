staload "mem.sats"
staload "data_font/sfnt/sfnt.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/position/glyph_position_types.sats"
(* All advances/offsets/attachment coordinates are signed 26.6 pixels.
   Source data remains untouched. This owner prevents mixing unscaled edits
   with positioning passes and prevents applying a pass after freezing. *)
fun glyph_position_initialize(face: !SfntFace,run: GlyphRun(2),xPpem: int,yPpem: int): GlyphPositionRead
fun glyph_position_initialize_bytes(b: !Buf,info: SfntInfo,run: GlyphRun(2),xPpem: int,yPpem: int): GlyphPositionRead
fun glyph_position_scale{phase:int}(positioned: !GlyphPositioned(phase)): GlyphScale
fun glyph_position_direction(positioned: !GlyphPositioned(1)): GlyphPositionDirection
fun glyph_position_meta{phase:int}(positioned: !GlyphPositioned(phase)): GlyphRunMeta
fun glyph_position_query{phase:int}(positioned: !GlyphPositioned(phase),node: int): GlyphView
fun glyph_position_dispose{phase:int}(positioned: GlyphPositioned(phase)): void
fun glyph_position_coordinate(units: int,ppem: int,design: int,pixels: int): GlyphCoordinate
(* Horizontal logical order; direction controls advance reconciliation, not
   lookup flags. An invalid attachment graph/overflow returns the exact owner. *)
fun glyph_position_finish(positioned: GlyphPositioned(0),direction: GlyphPositionDirection): GlyphPositionFinished
