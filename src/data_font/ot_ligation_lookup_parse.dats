#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/gsub_ligature_types.sats"
staload "data_font/gsub_ligatures.sats"
staload "data_font/gsub_ligature_work.sats"
staload "data_font/ot_ligation_lookup_types.sats"
staload "data_font/ot_ligation_lookup_work.sats"
staload "data_font/ot_layout_extension.sats"
staload "data_font/ot_layout_lookup_header.sats"
staload "data_font/ot_ligation_lookup.sats"
fun cache(b: !Buf,h: OtLookupInfo(1),glyphs: int): OtLigationLookupRead = let var maximum: int=0
in case+ ot_ligation_tables_read(b,h,glyphs,maximum) of | ~LigationTablesRejected(e) => LigationLookupRejected(e)
  | ~LigationTablesAccepted(t) => LigationLookupAccepted(OtLigationLookup(h,glyphs,maximum,t)) end
fun checked(b: !Buf,h: OtLookupInfo(1),glyphs: int): OtLigationLookupRead =
  case+ ot_lookup_extension_validate(b,h.span,h.action,h.count,ot_lookup_header_floor(h)) of
  | ~Some_vt(e) => LigationLookupRejected(e) | ~None_vt() => cache(b,h,glyphs)
fun selected(b: !Buf,h: OtLookupInfo(1),glyphs: int): OtLigationLookupRead = case+ h.action of
  | SubLigature() => checked(b,h,glyphs) | SubExtension() => checked(b,h,glyphs)
  | SubSingle() => LigationLookupRejected(ot_error(OtUnsupported(),h.span))
  | SubMultiple() => LigationLookupRejected(ot_error(OtUnsupported(),h.span))
  | SubAlternate() => LigationLookupRejected(ot_error(OtUnsupported(),h.span))
  | SubContext() => LigationLookupRejected(ot_error(OtUnsupported(),h.span))
  | SubChained() => LigationLookupRejected(ot_error(OtUnsupported(),h.span))
  | SubReverse() => LigationLookupRejected(ot_error(OtUnsupported(),h.span))
implement ot_ligation_lookup_parse(b,s,glyphs) =
  if not(ot_glyph_domain_valid(glyphs)) then LigationLookupRejected(ot_error(OtGlyphDomain(),s)) else
  case+ ot_lookup_header_parse(b,s,OtSubstitution()) of | ~LookupHeaderRejected(e) => LigationLookupRejected(e)
  | ~LookupHeaderAccepted(h) => selected(b,h,glyphs)
