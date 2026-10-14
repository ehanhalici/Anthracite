staload "data_font/glyph_substitution_stack_types.sats"
staload "data_font/glyph_substitution_lookup_types.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/glyph_context_arena_types.sats"
staload "data_font/glyph_run_types.sats"
fun glyph_substitution_frame_enter(lookup: int,node: int,generation: int): GlyphSubstitutionFrame
fun glyph_substitution_frame_empty(): GlyphSubstitutionFrame
fun glyph_substitution_frame_nested(old: GlyphSubstitutionFrame,step: GlyphSubstitutionStep): GlyphSubstitutionFrame
fun glyph_substitution_frame_action(old: GlyphSubstitutionFrame): GlyphSubstitutionFrame
fun glyph_substitution_frame_chain(old: GlyphSubstitutionFrame,chain: GlyphContextChain): GlyphSubstitutionFrame
fun glyph_substitution_stack_make(maximum: int): GlyphSubstitutionStack
fun glyph_substitution_stack_dispose(stack: GlyphSubstitutionStack): void
fun glyph_substitution_stack_get(stack: !GlyphSubstitutionStack,index: int): GlyphSubstitutionFrame
fun glyph_substitution_stack_set(stack: !GlyphSubstitutionStack,index: int,frame: GlyphSubstitutionFrame): void
fun glyph_substitution_stack_reserve(stack: &GlyphSubstitutionStack >> GlyphSubstitutionStack,needed: int): GlyphPassStatus
(* A repeated active key is a no-progress recursive cycle. A real GSUB edit
   changes generation, allowing a recursive lookup to examine its new text. *)
fun glyph_substitution_stack_cycle(stack: !GlyphSubstitutionStack,depth: int,lookup: int,node: int,
  generation: int,remaining: &int >> int): GlyphPassStatus
fun glyph_substitution_stack_rebase(stack: !GlyphSubstitutionStack,depth: int,
  arena: &GlyphContextArena >> GlyphContextArena,run: !GlyphRun(1),insertion: GlyphContextInsertion,
  remaining: &int >> int): GlyphPassStatus
