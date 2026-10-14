#include "data_font/glyph_substitution_engine_internal.hats"
implement glyph_substitution_ready(status) = case+ status of | GlyphPassApplied() => true
  | GlyphPassDomain() => false | GlyphPassReference() => false | GlyphPassCapacity() => false
fun headers{n,i:nat | i <= n} .<n-i>. (index: int(i),entries: !OtSubstitutionGraphEntries(n,n),
  m: !GlyphMetadata,meta: GlyphRunMeta): GlyphPassStatus = let val+ OtSubstitutionGraphEntries(pf,gc | rows,n,filled)=entries
in if index = n then GlyphPassApplied() else let
  var entry: OtSubstitutionGraphEntry=SubstitutionGraphVacant()
  val ()=array_exch_at<OtSubstitutionGraphEntry>(!rows,i2sz(index),entry)
  val h=glyph_substitution_entry_header(entry)
  val status=glyph_pass_domain_check(meta,m,meta.glyphs,h.flags,h.markSet,h.count)
  val ()=array_exch_at<OtSubstitutionGraphEntry>(!rows,i2sz(index),entry)
  val ()=ot_substitution_graph_entry_dispose(entry)
in if glyph_substitution_ready(status) then headers(index+1,entries,m,meta) else status end end
implement glyph_substitution_validate_graph(g,m,run) = let
  val+ OtSubstitutionGraph(font,glyphs,limits,entries)=g
  val+ OtSubstitutionGraphEntries(pf,gc | rows,n,filled)=entries
  val meta=glyph_run_meta(run) and info=glyph_metadata_info(m)
in if ine(meta.font,font) orelse ine(info.font,font) orelse ine(meta.glyphs,glyphs) orelse ine(info.glyphs,glyphs)
  then GlyphPassDomain() else headers(0,entries,m,meta) end
implement glyph_substitution_validate(g,m,run,lookup) = let
  val+ OtSubstitutionGraph(font,glyphs,limits,entries)=g
  val+ OtSubstitutionGraphEntries(pf,gc | rows,n,filled)=entries
in if ilt(lookup,0) orelse ige(lookup,n) then GlyphPassReference()
  else glyph_substitution_validate_graph(g,m,run) end
fun direction(entry: !OtSubstitutionGraphEntry): GlyphSubstitutionTraversal = case+ entry of
  | SubstitutionGraphReverse(h,t) => SubReverse() | SubstitutionGraphVacant() => SubForward()
  | SubstitutionGraphSingle(h,t) => SubForward() | SubstitutionGraphMultiple(h,t) => SubForward()
  | SubstitutionGraphAlternate(h,t) => SubForward() | SubstitutionGraphLigature(h,t) => SubForward()
  | SubstitutionGraphContext(h,t) => SubForward()
implement glyph_substitution_traversal(g,lookup) = let
  val+ OtSubstitutionGraph(font,glyphs,limits,entries)=g
  val+ OtSubstitutionGraphEntries(pf,gc | rows,n,filled)=entries
  val index=airlock_below(lookup,n)
  var entry: OtSubstitutionGraphEntry=SubstitutionGraphVacant()
  val ()=array_exch_at<OtSubstitutionGraphEntry>(!rows,i2sz(index),entry)
  val d=direction(entry)
  val ()=array_exch_at<OtSubstitutionGraphEntry>(!rows,i2sz(index),entry)
  val ()=ot_substitution_graph_entry_dispose(entry)
in d end
