#include "data_font/opentype/substitution_graph/ot_substitution_graph_internal.hats"
fun context(b: !Buf,h: OtLookupInfo(1),glyphs: int,lookups: int,mode: OtContextMode): OtSubstitutionGraphEntryRead =
  case+ ot_substitution_context_tables(b,h,glyphs,lookups,mode) of
  | ~SubContextTablesRejected(e) => SubGraphEntryRejected(e)
  | ~SubContextTablesAccepted(t) => SubGraphEntryAccepted(SubstitutionGraphContext(h,t))
fun action(b: !Buf,h: OtLookupInfo(1),glyphs: int,lookups: int,a: OtLookupKind(1)): OtSubstitutionGraphEntryRead = case+ a of
  | SubContext() => context(b,h,glyphs,lookups,ContextPlain()) | SubChained() => context(b,h,glyphs,lookups,ContextChained())
  | SubSingle() => ot_substitution_direct(b,h,glyphs,a) | SubMultiple() => ot_substitution_direct(b,h,glyphs,a)
  | SubAlternate() => ot_substitution_direct(b,h,glyphs,a) | SubLigature() => ot_substitution_direct(b,h,glyphs,a)
  | SubReverse() => ot_substitution_direct(b,h,glyphs,a) | SubExtension() => ot_substitution_direct(b,h,glyphs,a)
fun classify(b: !Buf,h: OtLookupInfo(1),glyphs: int,lookups: int): OtSubstitutionGraphEntryRead = case+ h.action of
  | SubExtension() => if ieq(h.count,0) then ot_substitution_direct(b,h,glyphs,h.action) else
    (case+ ot_substitution_graph_child(b,h,0) of | ~ExtensionRejected(e) => SubGraphEntryRejected(e)
      | ~ExtensionAccepted(c) => action(b,h,glyphs,lookups,c.action))
  | SubSingle() => action(b,h,glyphs,lookups,h.action) | SubMultiple() => action(b,h,glyphs,lookups,h.action)
  | SubAlternate() => action(b,h,glyphs,lookups,h.action) | SubLigature() => action(b,h,glyphs,lookups,h.action)
  | SubContext() => action(b,h,glyphs,lookups,h.action) | SubChained() => action(b,h,glyphs,lookups,h.action)
  | SubReverse() => action(b,h,glyphs,lookups,h.action)
fun checked(b: !Buf,h: OtLookupInfo(1),glyphs: int,lookups: int): OtSubstitutionGraphEntryRead =
  case+ ot_lookup_extension_validate(b,h.span,h.action,h.count,ot_lookup_header_floor(h)) of
  | ~Some_vt(e) => SubGraphEntryRejected(e) | ~None_vt() => classify(b,h,glyphs,lookups)
implement ot_substitution_graph_entry(b,span,glyphs,lookups) = case+ ot_lookup_header_parse(b,span,OtSubstitution()) of
  | ~LookupHeaderRejected(e) => SubGraphEntryRejected(e) | ~LookupHeaderAccepted(h) => checked(b,h,glyphs,lookups)
