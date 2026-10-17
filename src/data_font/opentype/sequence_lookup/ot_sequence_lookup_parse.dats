#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_reader.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/layout/ot_layout_extension.sats"
staload "data_font/opentype/layout/ot_layout_lookup_header.sats"
staload "data_font/opentype/substitution/gsub_sequence_types.sats"
staload "data_font/opentype/sequence_lookup/ot_sequence_lookup_types.sats"
staload "data_font/opentype/sequence_lookup/ot_sequence_lookup_work.sats"
staload "data_font/opentype/sequence_lookup/ot_sequence_lookup.sats"
fun cache{kind:int}(b: !Buf,h: OtLookupInfo(1),glyphs: int,d: GsubSequenceDomain(kind)): OtSequenceLookupRead(kind) =
  case+ ot_sequence_tables_read(b,h,glyphs,d) of
  | ~SequenceTablesRejected(e) => SequenceLookupRejected(e)
  | ~SequenceTablesAccepted(t) => SequenceLookupAccepted(OtSequenceLookup(h,glyphs,t))
fun checked{kind:int}(b: !Buf,h: OtLookupInfo(1),glyphs: int,d: GsubSequenceDomain(kind)): OtSequenceLookupRead(kind) =
  if ot_sequence_action_matches(d,h.action) then cache(b,h,glyphs,d) else case+ h.action of
  | SubExtension() => (case+ ot_extension_lookup_validate(b,h.span,OtSubstitution(),h.count,ot_lookup_header_floor(h)) of
    | ~Some_vt(e) => SequenceLookupRejected(e) | ~None_vt() => cache(b,h,glyphs,d))
  | SubSingle() => SequenceLookupRejected(ot_error(OtUnsupported(),h.span))
  | SubMultiple() => SequenceLookupRejected(ot_error(OtUnsupported(),h.span))
  | SubAlternate() => SequenceLookupRejected(ot_error(OtUnsupported(),h.span))
  | SubLigature() => SequenceLookupRejected(ot_error(OtUnsupported(),h.span))
  | SubContext() => SequenceLookupRejected(ot_error(OtUnsupported(),h.span))
  | SubChained() => SequenceLookupRejected(ot_error(OtUnsupported(),h.span))
  | SubReverse() => SequenceLookupRejected(ot_error(OtUnsupported(),h.span))
implement ot_sequence_lookup_parse(b,s,glyphs,d) =
  if not(ot_glyph_domain_valid(glyphs)) then SequenceLookupRejected(ot_error(OtGlyphDomain(),s)) else
  case+ ot_lookup_header_parse(b,s,OtSubstitution()) of
  | ~LookupHeaderRejected(e) => SequenceLookupRejected(e)
  | ~LookupHeaderAccepted(h) => checked(b,h,glyphs,d)
