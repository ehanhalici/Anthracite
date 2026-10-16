#include "data_font/glyph/substitution/glyph_substitution_engine_internal.hats"
fun make(window: GlyphContextWindow,limits: OtContextLimits,c: GlyphSubstitutionCapacity): GlyphSubstitutionWorkspace = let
  val stack=glyph_substitution_stack_make(c.frames) and arena=glyph_context_arena_make(c.slots)
  val output=buf_make(64)
  val glyphs=buf_make(imul(limits.input,4)) and nodes=buf_make(imul(limits.input,4)) and weights=buf_make(imul(limits.input,4))
in GlyphSubstitutionWorkspace(window,stack,arena,output,glyphs,nodes,weights,c.rows) end
implement glyph_substitution_workspace_make(limits,capacity) =
  if not(glyph_substitution_ready(capacity.status)) then SubWorkspaceRejected(capacity.status) else
  case+ glyph_window_make(limits) of | ~WindowAllocated(window) => SubWorkspaceAccepted(make(window,limits,capacity))
    | ~WindowRejected(e) => (case+ e of | WindowCapacity() => SubWorkspaceRejected(GlyphPassCapacity())
      | WindowReference() => SubWorkspaceRejected(GlyphPassReference()) | WindowDomain() => SubWorkspaceRejected(GlyphPassDomain())
      | WindowSkipped() => SubWorkspaceRejected(GlyphPassReference()) | WindowReady() => SubWorkspaceRejected(GlyphPassReference()))
implement glyph_substitution_workspace_dispose(w) = let
  val+ ~GlyphSubstitutionWorkspace(window,stack,arena,output,glyphs,nodes,weights,maximum)=w
  val ()=glyph_window_dispose(window) and ()=glyph_substitution_stack_dispose(stack) and ()=glyph_context_arena_dispose(arena)
  val ()=buf_free(output) and ()=buf_free(glyphs) and ()=buf_free(nodes)
in buf_free(weights) end
