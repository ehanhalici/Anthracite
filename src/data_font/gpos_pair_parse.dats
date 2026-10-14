#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/gpos_value_types.sats"
staload "data_font/gpos_values.sats"
staload "data_font/gpos_value_cache_types.sats"
staload "data_font/gpos_value_cache.sats"
staload "data_font/gpos_pair_types.sats"
staload "data_font/gpos_pairs.sats"
staload "data_font/gpos_pair_work.sats"
fun format_of(b: !Buf,s: OtSpan,glyphs: int,f: GposPairFormat): GposPairRead = case+ ot_u16(b,s,0) of
  | 1 => gpos_pair_explicit(b,s,glyphs,f) | 2 => gpos_pair_classes(b,s,glyphs,f)
  | _ => PairRejected(ot_error(OtFormat(),s))
implement gpos_pair_parse(b,s,glyphs) =
  if not(ot_span_valid(b,s)) orelse ilt(s.length,10) then PairRejected(ot_error(OtBounds(),s))
  else if not(ot_glyph_domain_valid(glyphs)) then PairRejected(ot_error(OtGlyphDomain(),s))
  else case+ gpos_pair_formats(b,s) of
    | ~PairFormatRejected(e) => PairRejected(e) | ~PairFormatAccepted(f) => format_of(b,s,glyphs,f)
