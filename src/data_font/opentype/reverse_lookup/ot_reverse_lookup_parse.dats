#include "data_font/opentype/reverse_lookup/ot_reverse_lookup_internal.hats"
fun cache(b: !Buf,h: OtLookupInfo(1),glyphs: int): OtReverseLookupRead = let
  var limits: OtContextLimits= @{back=0,input=1,look=0}
in case+ ot_reverse_tables_read(b,h,glyphs,limits) of | ~ReverseTablesRejected(e) => ReverseLookupRejected(e)
  | ~ReverseTablesAccepted(t) => ReverseLookupAccepted(OtReverseLookup(h,glyphs,limits,t)) end
fun checked(b: !Buf,h: OtLookupInfo(1),glyphs: int): OtReverseLookupRead =
  case+ ot_lookup_extension_validate(b,h.span,h.action,h.count,ot_lookup_header_floor(h)) of
  | ~Some_vt(e) => ReverseLookupRejected(e) | ~None_vt() => cache(b,h,glyphs)
fun selected(b: !Buf,h: OtLookupInfo(1),glyphs: int): OtReverseLookupRead = case+ h.action of
  | SubReverse() => checked(b,h,glyphs) | SubExtension() => checked(b,h,glyphs)
  | SubSingle() => ReverseLookupRejected(ot_error(OtUnsupported(),h.span))
  | SubMultiple() => ReverseLookupRejected(ot_error(OtUnsupported(),h.span))
  | SubAlternate() => ReverseLookupRejected(ot_error(OtUnsupported(),h.span))
  | SubLigature() => ReverseLookupRejected(ot_error(OtUnsupported(),h.span))
  | SubContext() => ReverseLookupRejected(ot_error(OtUnsupported(),h.span))
  | SubChained() => ReverseLookupRejected(ot_error(OtUnsupported(),h.span))
implement ot_reverse_lookup_parse(b,s,glyphs) =
  if not(ot_glyph_domain_valid(glyphs)) then ReverseLookupRejected(ot_error(OtGlyphDomain(),s)) else
  case+ ot_lookup_header_parse(b,s,OtSubstitution()) of | ~LookupHeaderRejected(e) => ReverseLookupRejected(e)
  | ~LookupHeaderAccepted(h) => selected(b,h,glyphs)
