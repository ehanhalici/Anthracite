staload "mem.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
fun glyph_run_make(font: int,glyphs: int,sourceLength: int,capacity: int): GlyphRunCreated
fun glyph_run_reserve{phase:int}(run: GlyphRun(phase),capacity: int): GlyphRunEdit(phase)
fun glyph_run_append(run: GlyphRun(0),seed: GlyphSeed): GlyphRunEdit(0)
fun glyph_run_substitute(run: GlyphRun(0)): GlyphRun(1)
fun glyph_run_position(run: GlyphRun(1)): GlyphRun(2)
fun glyph_run_freeze(run: GlyphRun(2)): GlyphRun(3)
fun glyph_run_query{phase:int}(run: !GlyphRun(phase),node: int): GlyphView
fun glyph_run_meta{phase:int}(run: !GlyphRun(phase)): GlyphRunMeta
fun glyph_run_capacity{phase:int}(run: !GlyphRun(phase)): int
fun glyph_run_dispose{phase:int}(run: GlyphRun(phase)): void
(* A lookup transaction may stage structural mutations in a private copy.
   The caller accounts for both live column sets before calling this helper. *)
fun glyph_run_clone{phase:int}(run: !GlyphRun(phase)): GlyphRun(phase)
fun glyph_run_single(run: GlyphRun(1),node: int,glyph: int): GlyphRunEdit(1)
(* Output is a uint32 glyph-ID slice. All outputs and capacity are checked
   before mutation; a rejected operation returns the unchanged linear run. *)
fun glyph_run_multiple(run: GlyphRun(1),node: int,output: !Buf,count: int): GlyphRunEdit(1)
(* Selected nodes are logical-order stable IDs, already filtered by the
   scheduler. Ignored nodes stay in place. Nested owner components are counted. *)
fun glyph_run_ligate(run: GlyphRun(1),nodes: !Buf,count: int,glyph: int): GlyphRunEdit(1)
fun glyph_run_bind_mark(run: GlyphRun(1),node: int,owner: int,component: int): GlyphRunEdit(1)
fun glyph_run_mark_association{phase:int}(run: !GlyphRun(phase),node: int): GlyphAssociationView
fun glyph_run_set_position(run: GlyphRun(2),node: int,position: GlyphPosition): GlyphRunEdit(2)
