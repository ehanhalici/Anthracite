#include "data_font/glyph/substitution/glyph_substitution_lookup_internal.hats"
fun replace(run: !GlyphRun(1),node: int,result: GsubSingleResult): GlyphSubstitutionStep = let
  val+ GlyphRun(phase,meta,s)=run
  val links=glyph_storage_links(s,node)
in if not(result.matched) then glyph_substitution_unchanged(links.next) else let
    val core=glyph_storage_core(s,node)
    val ()=glyph_storage_set_core(s,node,glyph_run_new_glyph(core,result.glyph))
  in glyph_substitution_done(GlyphPassApplied(),links.next,true,@{node= ~1,first=0,added=0}) end end
implement glyph_substitution_scalar(b,e,run,options,node) = let val view=glyph_run_query(run,node)
in case+ e of
  | SubstitutionGraphSingle(h,t) => replace(run,node,ot_single_lookup_query(b,t,view.core.glyph))
  | SubstitutionGraphAlternate(h,t) => replace(run,node,ot_alternate_lookup_query(b,t,view.core.glyph,options.alternate))
  | SubstitutionGraphVacant() => glyph_substitution_fault(GlyphPassReference())
  | SubstitutionGraphMultiple(h,t) => glyph_substitution_fault(GlyphPassReference())
  | SubstitutionGraphLigature(h,t) => glyph_substitution_fault(GlyphPassReference())
  | SubstitutionGraphReverse(h,t) => glyph_substitution_fault(GlyphPassReference())
  | SubstitutionGraphContext(h,t) => glyph_substitution_fault(GlyphPassReference()) end
