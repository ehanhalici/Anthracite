#include "data_font/glyph/substitution/glyph_substitution_lookup_internal.hats"
staload "data_font/glyph/pass/glyph_pass_ligature_work.sats"
fun apply{n:nat}(b: !Buf,h: OtLookupInfo(1),t: !OtLigationTables(n,n),m: !GlyphMetadata,
  run: &GlyphRun(1) >> GlyphRun(1),o: GlyphSubstitutionOptions,node: int,glyphs: !Buf,nodes: !Buf,
  weights: !Buf,remaining: &int >> int): GlyphSubstitutionStep = let
  val+ @GlyphRun(phase,meta,s)=run
  val r=glyph_ligature_step(b,t,m,s,meta,h.flags,h.markSet,o.selection,node,glyphs,nodes,weights,remaining)
  prval ()=fold@(run)
in glyph_substitution_done(r.status,r.next,r.matched,@{node= ~1,first=0,added=0}) end
implement glyph_substitution_ligature(b,e,m,run,o,node,glyphs,nodes,weights,remaining) = case+ e of
  | SubstitutionGraphLigature(h,t) => let val+ OtLigationLookup(info,count,maximum,tables)=t
    in apply(b,info,tables,m,run,o,node,glyphs,nodes,weights,remaining) end
  | SubstitutionGraphVacant() => glyph_substitution_fault(GlyphPassReference())
  | SubstitutionGraphSingle(h,t) => glyph_substitution_fault(GlyphPassReference())
  | SubstitutionGraphMultiple(h,t) => glyph_substitution_fault(GlyphPassReference())
  | SubstitutionGraphAlternate(h,t) => glyph_substitution_fault(GlyphPassReference())
  | SubstitutionGraphReverse(h,t) => glyph_substitution_fault(GlyphPassReference())
  | SubstitutionGraphContext(h,t) => glyph_substitution_fault(GlyphPassReference())
