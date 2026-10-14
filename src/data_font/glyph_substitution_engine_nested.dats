#include "data_font/glyph_substitution_engine_internal.hats"
extern fun substitution_nested_failed(): int = "mac#anth_die_int"
fun walk{n:nat} .<n>. (left: int(n),b: !Buf,g: !OtSubstitutionGraph,m: !GlyphMetadata,
  run: &GlyphRun(1) >> GlyphRun(1),o: GlyphSubstitutionOptions,w: &GlyphSubstitutionWorkspace >> GlyphSubstitutionWorkspace,
  depth: int,generation: &int >> int,remaining: &int >> int): GlyphSubstitutionEvent =
  if ile(remaining,0) then glyph_substitution_event_fault(GlyphPassCapacity())
  else if left = 0 then let val failed=substitution_nested_failed()
    in glyph_substitution_event_done(0,failed,false) end else let
      val ()=remaining := isub(remaining,1)
      val event=glyph_substitution_transition(b,g,m,run,o,w,depth,generation,remaining)
    in case+ event.kind of | SubReturned() => event | SubFault() => event
      | SubContinue() => walk(left-1,b,g,m,run,o,w,event.depth,generation,remaining) end
fun prepare(w: &GlyphSubstitutionWorkspace >> GlyphSubstitutionWorkspace,lookup: int,node: int,generation: int): void = let
  val+ @GlyphSubstitutionWorkspace(window,stack,arena,output,glyphs,nodes,weights,maximum)=w
  val ()=glyph_context_arena_reset(arena)
  val ()=glyph_substitution_stack_set(stack,0,glyph_substitution_frame_enter(lookup,node,generation))
  prval ()=fold@(w)
in () end
implement glyph_substitution_nested(b,g,m,run,lookup,node,o,w,generation,remaining) = let
  val ()=prepare(w,lookup,node,generation)
in walk(MAX_REC_FUEL,b,g,m,run,o,w,0,generation,remaining) end
