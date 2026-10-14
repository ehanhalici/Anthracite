#include "data_font/glyph_pass_reverse_internal.hats"
staload "data_font/glyph_core_draft_types.sats"
staload "data_font/glyph_core_draft.sats"
fun finish{n:nat}(draft: GlyphCoreDraft(n),meta: GlyphRunMeta,r: GlyphReverseCount): GlyphPassResult(1) =
  case+ r.status of
    | GlyphPassApplied() => GlyphPassResult(GlyphRun(RunSubstitution(),meta,glyph_core_draft_commit(draft)),r.status,r.visited,r.matches)
    | GlyphPassDomain() => GlyphPassResult(GlyphRun(RunSubstitution(),meta,glyph_core_draft_rollback(draft)),r.status,0,0)
    | GlyphPassReference() => GlyphPassResult(GlyphRun(RunSubstitution(),meta,glyph_core_draft_rollback(draft)),r.status,0,0)
    | GlyphPassCapacity() => GlyphPassResult(GlyphRun(RunSubstitution(),meta,glyph_core_draft_rollback(draft)),r.status,0,0)
implement glyph_reverse_execute(b,t,m,s,meta,selection,w,remaining) = let
  val draft=glyph_core_draft_make(s,meta.used)
  val+ GlyphCoreDraft(original,scratch)=draft
  val r=glyph_reverse_walk(b,t,m,scratch,meta,selection,w,remaining)
  val ()=glyph_window_dispose(w)
in finish(draft,meta,r) end
