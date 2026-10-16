#include "data_font/glyph/substitution/glyph_substitution_engine_internal.hats"
fun finish(source: GlyphRun(1),run: GlyphRun(1),result: GlyphSubstitutionCounts): GlyphPassResult(1) =
  if glyph_substitution_ready(result.status) then let val ()=glyph_run_dispose(source)
    in GlyphPassResult(run,result.status,result.visited,result.matches) end else let val ()=glyph_run_dispose(run)
    in GlyphPassResult(source,result.status,0,0) end
fun transaction(b: !Buf,g: !OtSubstitutionGraph,m: !GlyphMetadata,source: GlyphRun(1),lookup: int,o: GlyphSubstitutionOptions,
  workspace: GlyphSubstitutionWorkspace,remaining: &int >> int): GlyphPassResult(1) = let
  var run: GlyphRun(1)=glyph_run_clone(source)
  var w: GlyphSubstitutionWorkspace=workspace
  val result=glyph_substitution_walk(b,g,m,run,lookup,o,w,remaining)
  val ()=glyph_substitution_workspace_dispose(w)
in finish(source,run,result) end
fun apply(b: !Buf,g: !OtSubstitutionGraph,m: !GlyphMetadata,run: GlyphRun(1),lookup: int,
  o: GlyphSubstitutionOptions,remaining: &int >> int): GlyphPassResult(1) = let
  val+ OtSubstitutionGraph(font,glyphs,limits,entries)=g
  val capacity=glyph_substitution_capacity(run,limits)
in case+ glyph_substitution_workspace_make(limits,capacity) of | ~SubWorkspaceRejected(e) => GlyphPassResult(run,e,0,0)
  | ~SubWorkspaceAccepted(w) => transaction(b,g,m,run,lookup,o,w,remaining) end
implement glyph_substitution_lookup_budget(b,g,m,run,lookup,o,remaining) = let
  val status=glyph_substitution_validate(g,m,run,lookup)
in if glyph_substitution_ready(status) then apply(b,g,m,run,lookup,o,remaining) else GlyphPassResult(run,status,0,0) end
implement glyph_substitution_lookup(b,g,m,run,lookup,o) = let var remaining: int=MAX_REC_FUEL
in glyph_substitution_lookup_budget(b,g,m,run,lookup,o,remaining) end
