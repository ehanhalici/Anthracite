#include "data_font/glyph_pass_reverse_internal.hats"
fun checked{n:nat}(b: !Buf,t: !OtReverseLookup,m: !GlyphMetadata,s: GlyphStorage(n),meta: GlyphRunMeta,
  selection: GlyphSelection,limits: OtContextLimits,remaining: &int >> int): GlyphPassResult(1) =
  case+ glyph_window_make(limits) of
    | ~WindowRejected(e) => GlyphPassResult(GlyphRun(RunSubstitution(),meta,s),glyph_reverse_window_status(e),0,0)
    | ~WindowAllocated(w) => glyph_reverse_execute(b,t,m,s,meta,selection,w,remaining)
implement glyph_pass_reverse_budget(b,t,m,run,selection,remaining) = let
  val+ ~GlyphRun(phase,meta,s)=run
  val+ OtReverseLookup(h,glyphs,limits,rows)=t
  val status=glyph_pass_domain_check(meta,m,glyphs,h.flags,h.markSet,h.count)
in case+ status of
  | GlyphPassApplied() => checked(b,t,m,s,meta,selection,limits,remaining)
  | GlyphPassDomain() => GlyphPassResult(GlyphRun(phase,meta,s),status,0,0)
  | GlyphPassReference() => GlyphPassResult(GlyphRun(phase,meta,s),status,0,0)
  | GlyphPassCapacity() => GlyphPassResult(GlyphRun(phase,meta,s),status,0,0) end
implement glyph_pass_reverse(b,t,m,run,selection) = let var remaining: int=MAX_REC_FUEL
in glyph_pass_reverse_budget(b,t,m,run,selection,remaining) end
