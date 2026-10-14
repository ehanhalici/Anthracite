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
staload "data_font/gpos_pair_work.sats"
fun second(b: !Buf,s: OtSpan,first: OtValueFormat): GposPairFormatRead =
  case+ ot_value_format(ot_u16(b,s,6)) of
  | ~ValueFormatRejected() => PairFormatRejected(ot_error(OtFormat(),s))
  | ~ValueFormatAccepted(next) => PairFormatAccepted(@{first=first,second=next,
    stride=iadd(first.size,next.size),
    progress=if ieq(next.size,0) then PairContinueSecond() else PairContinueFollowing()})
implement gpos_pair_formats(b,s) = case+ ot_value_format(ot_u16(b,s,4)) of
  | ~ValueFormatRejected() => PairFormatRejected(ot_error(OtFormat(),s))
  | ~ValueFormatAccepted(first) => second(b,s,first)
