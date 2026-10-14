#include "data_font/glyph_substitution_engine_internal.hats"
implement glyph_substitution_transition(b,g,m,run,o,w,depth,generation,remaining) = let
  val+ GlyphSubstitutionWorkspace(window,stack,arena,output,glyphs,nodes,weights,maximum)=w
  val frame=glyph_substitution_stack_get(stack,depth)
in case+ frame.state of
  | SubstitutionEnter() => glyph_substitution_enter(b,g,m,run,o,w,depth,generation,remaining)
  | SubstitutionActions() => glyph_substitution_actions(b,run,w,depth,generation,remaining) end
