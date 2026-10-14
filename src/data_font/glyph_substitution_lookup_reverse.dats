#include "data_font/glyph_substitution_lookup_internal.hats"
staload "data_font/ot_reverse_lookup_types.sats"
staload "data_font/glyph_pass_reverse_work.sats"
fun apply(b: !Buf,t: !OtReverseLookup,m: !GlyphMetadata,run: !GlyphRun(1),o: GlyphSubstitutionOptions,node: int,
  w: !GlyphContextWindow,remaining: &int >> int): GlyphSubstitutionStep = let
  val+ GlyphRun(phase,meta,s)=run
  val links=glyph_storage_links(s,node)
  val r=glyph_reverse_query(b,t,m,s,meta,o.selection,node,w,remaining)
  val ()=if r.matched then let val core=glyph_storage_core(s,node)
    in glyph_storage_set_core(s,node,glyph_run_new_glyph(core,r.glyph)) end else ()
in glyph_substitution_done(r.status,links.next,r.matched,@{node= ~1,first=0,added=0}) end
implement glyph_substitution_reverse(b,e,m,run,o,node,w,remaining) = case+ e of
  | SubstitutionGraphReverse(h,t) => apply(b,t,m,run,o,node,w,remaining)
  | SubstitutionGraphVacant() => glyph_substitution_fault(GlyphPassReference())
  | SubstitutionGraphSingle(h,t) => glyph_substitution_fault(GlyphPassReference())
  | SubstitutionGraphMultiple(h,t) => glyph_substitution_fault(GlyphPassReference())
  | SubstitutionGraphAlternate(h,t) => glyph_substitution_fault(GlyphPassReference())
  | SubstitutionGraphLigature(h,t) => glyph_substitution_fault(GlyphPassReference())
  | SubstitutionGraphContext(h,t) => glyph_substitution_fault(GlyphPassReference())
