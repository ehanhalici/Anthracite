#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_reader.sats"
staload "data_font/opentype/context/ot_context_types.sats"
staload "data_font/opentype/context/ot_context_header.sats"
fun sets(b: !Buf,s: OtSpan,glyphs: int,lookups: int,mode: OtContextMode,
  encoding: OtContextEncoding,header: int): OtContextHeaderRead =
  if ilt(s.length,header) then ContextHeaderRejected(ot_error(OtBounds(),s)) else let
    val count=ot_u16(b,s,isub(header,2))
    val floor=iadd(header,imul(count,2))
    val info=ot_context_info(s,mode,encoding,header,count,floor,glyphs,lookups)
  in if not(ot_rows_fit(s,header,count,2)) then ContextHeaderRejected(ot_error(OtBounds(),s))
    else case+ encoding of
      | ContextClasses() => ot_context_classes(b,info)
      | ContextGlyphs() => ContextHeaderAccepted(info)
      | ContextCoverages() => ContextHeaderRejected(ot_error(OtFormat(),s)) end
fun classes_header(mode: OtContextMode): int = case+ mode of
  | ContextPlain() => 8 | ContextChained() => 12
implement ot_context_header_parse(b,s,glyphs,lookups,mode) =
  if not(ot_span_valid(b,s)) orelse ilt(s.length,2) then ContextHeaderRejected(ot_error(OtBounds(),s))
  else if not(ot_glyph_domain_valid(glyphs)) then ContextHeaderRejected(ot_error(OtGlyphDomain(),s))
  else if ilt(lookups,0) orelse igt(lookups,WORD16_MAX_VALUE) then ContextHeaderRejected(ot_error(OtReference(),s))
  else case+ ot_u16(b,s,0) of
    | 1 => sets(b,s,glyphs,lookups,mode,ContextGlyphs(),6)
    | 2 => sets(b,s,glyphs,lookups,mode,ContextClasses(),classes_header(mode))
    | 3 => ot_context_direct(b,s,glyphs,lookups,mode)
    | _ => ContextHeaderRejected(ot_error(OtFormat(),s))
