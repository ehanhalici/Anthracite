#include "data_font/glyph/substitution/glyph_substitution_lookup_internal.hats"
staload "data_font/opentype/substitution_graph/ot_substitution_graph_work.sats"
fun present(kind: GlyphViewKind): bool = case+ kind of | GlyphPresent() => true | GlyphMissing() => false
fun dispatch(b: !Buf,e: !OtSubstitutionGraphEntry,m: !GlyphMetadata,run: &GlyphRun(1) >> GlyphRun(1),
  o: GlyphSubstitutionOptions,node: int,w: !GlyphContextWindow,arena: &GlyphContextArena >> GlyphContextArena,
  output: &Buf >> Buf,glyphs: !Buf,nodes: !Buf,weights: !Buf,maximum: int,remaining: &int >> int): GlyphSubstitutionStep = case+ e of
  | SubstitutionGraphVacant() => glyph_substitution_fault(GlyphPassReference())
  | SubstitutionGraphSingle(h,t) => glyph_substitution_scalar(b,e,run,o,node)
  | SubstitutionGraphAlternate(h,t) => glyph_substitution_scalar(b,e,run,o,node)
  | SubstitutionGraphMultiple(h,t) => glyph_substitution_multiple(b,e,run,node,output,maximum,remaining)
  | SubstitutionGraphLigature(h,t) => glyph_substitution_ligature(b,e,m,run,o,node,glyphs,nodes,weights,remaining)
  | SubstitutionGraphReverse(h,t) => glyph_substitution_reverse(b,e,m,run,o,node,w,remaining)
  | SubstitutionGraphContext(h,t) => glyph_substitution_context(b,e,m,run,o,node,w,arena,remaining)
fun selected(b: !Buf,e: !OtSubstitutionGraphEntry,m: !GlyphMetadata,run: &GlyphRun(1) >> GlyphRun(1),
  o: GlyphSubstitutionOptions,node: int,w: !GlyphContextWindow,arena: &GlyphContextArena >> GlyphContextArena,
  output: &Buf >> Buf,glyphs: !Buf,nodes: !Buf,weights: !Buf,maximum: int,remaining: &int >> int): GlyphSubstitutionStep = let
  val h=glyph_substitution_entry_header(e) and current=glyph_run_query(run,node)
in if not(glyph_pass_selected(o.selection,current.core.mask)) orelse not(glyph_metadata_allows_core(b,m,h.flags,h.markSet,current.core))
  then glyph_substitution_unchanged(current.links.next)
  else if igt(h.count,remaining) then glyph_substitution_fault(GlyphPassCapacity()) else let
    val ()=remaining := isub(remaining,h.count)
  in dispatch(b,e,m,run,o,node,w,arena,output,glyphs,nodes,weights,maximum,remaining) end end
implement glyph_substitution_step(b,g,m,run,o,lookup,node,w,arena,output,glyphs,nodes,weights,maximum,remaining) = let
  val+ OtSubstitutionGraph(font,glyphCount,limits,entries)=g
  val+ OtSubstitutionGraphEntries(pf,gc | rows,count,filled)=entries
  val current=glyph_run_query(run,node)
in if ilt(lookup,0) orelse ige(lookup,count) orelse not(present(current.kind))
  then glyph_substitution_fault(GlyphPassReference()) else let
    var loan: OtSubstitutionGraphEntry=SubstitutionGraphVacant()
    val ()=array_exch_at<OtSubstitutionGraphEntry>(!rows,i2sz(airlock_below(lookup,count)),loan)
    val result=selected(b,loan,m,run,o,node,w,arena,output,glyphs,nodes,weights,maximum,remaining)
    val ()=array_exch_at<OtSubstitutionGraphEntry>(!rows,i2sz(airlock_below(lookup,count)),loan)
    val ()=ot_substitution_graph_entry_dispose(loan)
  in result end end
