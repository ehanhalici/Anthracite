#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_reader.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/layout/ot_layout_extension.sats"
staload "data_font/opentype/substitution/gsub_single_types.sats"
staload "data_font/opentype/single_lookup/ot_single_lookup_types.sats"
staload "data_font/opentype/single_lookup/ot_single_lookup_work.sats"
staload "data_font/opentype/single_lookup/ot_single_lookup.sats"
fun cache(b: !Buf,h: OtSingleHeader,glyphs: int): OtSingleLookupRead =
  case+ ot_single_tables_read(b,h,glyphs) of
  | ~SingleTablesRejected(e) => SingleLookupRejected(e)
  | ~SingleTablesAccepted(tables) => SingleLookupAccepted(OtSingleLookup(h,glyphs,tables))
fun checked(b: !Buf,h: OtSingleHeader,glyphs: int): OtSingleLookupRead = case+ h.envelope of
  | SingleDirect() => cache(b,h,glyphs)
  | SingleExtended() => case+ ot_extension_lookup_validate(b,h.span,OtSubstitution(),h.count,h.floor) of
    | ~Some_vt(e) => SingleLookupRejected(e) | ~None_vt() => cache(b,h,glyphs)
implement ot_single_lookup_parse(b,s,glyphs) =
  if not(ot_glyph_domain_valid(glyphs)) then SingleLookupRejected(ot_error(OtGlyphDomain(),s)) else
  case+ ot_single_header_parse(b,s) of
  | ~SingleHeaderRejected(e) => SingleLookupRejected(e)
  | ~SingleHeaderAccepted(h) => checked(b,h,glyphs)
