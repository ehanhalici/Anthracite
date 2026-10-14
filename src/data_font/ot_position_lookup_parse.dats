#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/ot_layout_extension.sats"
staload "data_font/ot_layout_lookup_header.sats"
staload "data_font/ot_position_lookup_types.sats"
staload "data_font/ot_position_lookup_work.sats"
staload "data_font/ot_position_lookup.sats"
fun cache(b: !Buf,h: OtLookupInfo(2),glyphs: int): OtPositionLookupRead = case+ ot_position_tables_read(b,h,glyphs) of
  | ~PositionTablesRejected(e) => PositionLookupRejected(e)
  | ~PositionTablesAccepted(t) => let val action=ot_position_tables_action(t,h.action)
    in PositionLookupAccepted(OtPositionLookup(h,action,glyphs,t)) end
fun extensions(b: !Buf,h: OtLookupInfo(2),glyphs: int): OtPositionLookupRead =
  case+ ot_lookup_extension_validate(b,h.span,h.action,h.count,ot_lookup_header_floor(h)) of
  | ~Some_vt(e) => PositionLookupRejected(e) | ~None_vt() => cache(b,h,glyphs)
fun checked(b: !Buf,h: OtLookupInfo(2),glyphs: int): OtPositionLookupRead = case+ h.action of
  | PosContext() => PositionLookupRejected(ot_error(OtUnsupported(),h.span))
  | PosChained() => PositionLookupRejected(ot_error(OtUnsupported(),h.span))
  | PosSingle() => extensions(b,h,glyphs) | PosPair() => extensions(b,h,glyphs)
  | PosCursive() => extensions(b,h,glyphs) | PosMarkBase() => extensions(b,h,glyphs)
  | PosMarkLigature() => extensions(b,h,glyphs) | PosMarkMark() => extensions(b,h,glyphs)
  | PosExtension() => extensions(b,h,glyphs)
implement ot_position_lookup_parse(b,s,glyphs) =
  if not(ot_glyph_domain_valid(glyphs)) then PositionLookupRejected(ot_error(OtGlyphDomain(),s)) else
  case+ ot_lookup_header_parse(b,s,OtPositioning()) of
  | ~LookupHeaderRejected(e) => PositionLookupRejected(e) | ~LookupHeaderAccepted(h) => checked(b,h,glyphs)
