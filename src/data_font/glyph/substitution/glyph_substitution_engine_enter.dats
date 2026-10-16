#include "data_font/glyph/substitution/glyph_substitution_engine_internal.hats"
fun reconcile(run: !GlyphRun(1),before: GlyphRunMeta,step: GlyphSubstitutionStep,
  stack: !GlyphSubstitutionStack,arena: &GlyphContextArena >> GlyphContextArena,depth: int,
  generation: &int >> int,remaining: &int >> int): GlyphPassStatus = let
  val after=glyph_run_meta(run)
  val structural=ine(before.used,after.used) orelse ine(before.live,after.live)
  val ()=generation := iadd(generation,1)
in if structural then glyph_substitution_stack_rebase(stack,depth,arena,run,step.insertion,remaining)
  else GlyphPassApplied() end
fun result(run: !GlyphRun(1),before: GlyphRunMeta,glyph: int,step: GlyphSubstitutionStep,frame: GlyphSubstitutionFrame,
  stack: !GlyphSubstitutionStack,arena: &GlyphContextArena >> GlyphContextArena,depth: int,
  generation: &int >> int,remaining: &int >> int): GlyphSubstitutionEvent =
  if not(glyph_substitution_ready(step.status)) then glyph_substitution_event_fault(step.status) else
  case+ step.kind of
    | SubstitutionNested() => let val ()=glyph_substitution_stack_set(stack,depth,glyph_substitution_frame_nested(frame,step))
      in glyph_substitution_event_continue(depth) end
    | SubstitutionDone() => let
      val actual=glyph_run_query(run,frame.node)
      val after=glyph_run_meta(run)
      val status=if ine(actual.core.glyph,glyph) orelse ine(before.used,after.used)
        orelse ine(before.live,after.live) then reconcile(run,before,step,stack,arena,depth,generation,remaining)
        else GlyphPassApplied()
    in if glyph_substitution_ready(status) then glyph_substitution_event_done(depth,step.next,step.matched)
      else glyph_substitution_event_fault(status) end
fun execute(b: !Buf,g: !OtSubstitutionGraph,m: !GlyphMetadata,run: &GlyphRun(1) >> GlyphRun(1),o: GlyphSubstitutionOptions,
  w: &GlyphSubstitutionWorkspace >> GlyphSubstitutionWorkspace,depth: int,generation: &int >> int,
  remaining: &int >> int): GlyphSubstitutionEvent = let
  val+ @GlyphSubstitutionWorkspace(window,stack,arena,output,glyphs,nodes,weights,maximum)=w
  val frame=glyph_substitution_stack_get(stack,depth)
  val before=glyph_run_meta(run) and view=glyph_run_query(run,frame.node)
  val step=glyph_substitution_step(b,g,m,run,o,frame.lookup,frame.node,window,arena,output,glyphs,nodes,weights,maximum,remaining)
  val event=result(run,before,view.core.glyph,step,frame,stack,arena,depth,generation,remaining)
  prval ()=fold@(w)
in event end
implement glyph_substitution_enter(b,g,m,run,o,w,depth,generation,remaining) = let
  val+ GlyphSubstitutionWorkspace(window,stack,arena,output,glyphs,nodes,weights,maximum)=w
  val frame=glyph_substitution_stack_get(stack,depth)
  val status=glyph_substitution_stack_cycle(stack,depth,frame.lookup,frame.node,generation,remaining)
in if glyph_substitution_ready(status) then execute(b,g,m,run,o,w,depth,generation,remaining)
  else glyph_substitution_event_fault(status) end
