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
staload "data_font/gpos_pair_sets.sats"
staload "data_font/gpos_pair_work.sats"
fun sets(b: !Buf,s: OtSpan,c: OtCoverageInfo,f: GposPairFormat,glyphs: int,count: int): GposPairRead =
  if ine(c.total,count) then PairRejected(ot_error(OtCoverageIndex(),s)) else
    case+ gpos_pair_sets_read(b,s,count,f,glyphs) of
    | ~PairSetsRejected(e) => PairRejected(e) | ~PairSetsAccepted(cache,total) =>
      gpos_pair_set_ingest(b,gpos_pair_info(s,c,f,glyphs),cache,airlock_nat(total))
implement gpos_pair_explicit(b,s,glyphs,f) = let val count=ot_u16(b,s,8) in
  if not(ot_rows_fit(s,10,count,2)) then PairRejected(ot_error(OtBounds(),s)) else
    case+ gpos_pair_coverage(b,s,iadd(10,imul(count,2)),glyphs) of
    | ~CoverageRejected(e) => PairRejected(e) | ~CoverageAccepted(c) => sets(b,s,c,f,glyphs,count) end
