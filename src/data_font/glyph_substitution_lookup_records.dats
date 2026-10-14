#include "data_font/glyph_substitution_lookup_internal.hats"
fun context(): OtContextMatch(1) = @{domain=OtSubstitution(),matched=false,inputCount=0,
  actions= @{offset=0,length=0},actionCount=0,rule=0}
implement glyph_substitution_done(status,next,matched,insertion) =
  @{kind=SubstitutionDone(),status=status,next=next,matched=matched,context=context(),
    chain=glyph_context_chain_empty(),insertion=insertion}
implement glyph_substitution_unchanged(next) =
  glyph_substitution_done(GlyphPassApplied(),next,false,@{node= ~1,first=0,added=0})
implement glyph_substitution_fault(status) =
  glyph_substitution_done(status,~1,false,@{node= ~1,first=0,added=0})
implement glyph_substitution_edit_status(status) = case+ status of
  | GlyphUpdated() => GlyphPassApplied() | GlyphUnchanged() => GlyphPassApplied()
  | GlyphCapacity() => GlyphPassCapacity() | GlyphNode() => GlyphPassReference()
  | GlyphDomain() => GlyphPassDomain() | GlyphSource() => GlyphPassReference()
  | GlyphOrder() => GlyphPassReference() | GlyphAssociationError() => GlyphPassReference()
  | GlyphOverflow() => GlyphPassCapacity()
extern fun substitution_header_failed(): int = "mac#anth_die_int"
implement glyph_substitution_entry_header(e) = case+ e of
  | SubstitutionGraphSingle(h,t) => h | SubstitutionGraphMultiple(h,t) => h
  | SubstitutionGraphAlternate(h,t) => h | SubstitutionGraphLigature(h,t) => h
  | SubstitutionGraphReverse(h,t) => h | SubstitutionGraphContext(h,t) => h
  | SubstitutionGraphVacant() => let val failed=substitution_header_failed()
    in @{span= @{offset=failed,length=0},action=SubSingle(),flags= @{rtl=false,ignoreBase=false,
      ignoreLigature=false,ignoreMarks=false,useMarkSet=false,attachment=0},count=0,markSet=0} end
