#include "data_font/opentype/substitution_graph/ot_substitution_graph_internal.hats"
fun single(b: !Buf,h: OtLookupInfo(1),glyphs: int): OtSubstitutionGraphEntryRead =
  case+ ot_single_lookup_parse(b,h.span,glyphs) of | ~SingleLookupRejected(e) => SubGraphEntryRejected(e)
  | ~SingleLookupAccepted(t) => SubGraphEntryAccepted(SubstitutionGraphSingle(h,t))
fun multiple(b: !Buf,h: OtLookupInfo(1),glyphs: int): OtSubstitutionGraphEntryRead =
  case+ ot_sequence_lookup_parse(b,h.span,glyphs,GsubMultiple()) of | ~SequenceLookupRejected(e) => SubGraphEntryRejected(e)
  | ~SequenceLookupAccepted(t) => SubGraphEntryAccepted(SubstitutionGraphMultiple(h,t))
fun alternate(b: !Buf,h: OtLookupInfo(1),glyphs: int): OtSubstitutionGraphEntryRead =
  case+ ot_sequence_lookup_parse(b,h.span,glyphs,GsubAlternate()) of | ~SequenceLookupRejected(e) => SubGraphEntryRejected(e)
  | ~SequenceLookupAccepted(t) => SubGraphEntryAccepted(SubstitutionGraphAlternate(h,t))
fun ligature(b: !Buf,h: OtLookupInfo(1),glyphs: int): OtSubstitutionGraphEntryRead =
  case+ ot_ligation_lookup_parse(b,h.span,glyphs) of | ~LigationLookupRejected(e) => SubGraphEntryRejected(e)
  | ~LigationLookupAccepted(t) => SubGraphEntryAccepted(SubstitutionGraphLigature(h,t))
fun reverse(b: !Buf,h: OtLookupInfo(1),glyphs: int): OtSubstitutionGraphEntryRead =
  case+ ot_reverse_lookup_parse(b,h.span,glyphs) of | ~ReverseLookupRejected(e) => SubGraphEntryRejected(e)
  | ~ReverseLookupAccepted(t) => SubGraphEntryAccepted(SubstitutionGraphReverse(h,t))
implement ot_substitution_direct(b,h,glyphs,a) = case+ a of
  | SubSingle() => single(b,h,glyphs) | SubMultiple() => multiple(b,h,glyphs)
  | SubAlternate() => alternate(b,h,glyphs) | SubLigature() => ligature(b,h,glyphs) | SubReverse() => reverse(b,h,glyphs)
  | SubExtension() => reverse(b,h,glyphs) (* Empty extension: no action, no payload. *)
  | SubContext() => SubGraphEntryRejected(ot_error(OtUnsupported(),h.span))
  | SubChained() => SubGraphEntryRejected(ot_error(OtUnsupported(),h.span))
