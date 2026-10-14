#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/normalization_bounds.sats"
implement normalization_count_sum(a,b) =
  if ilt(a,0) orelse ilt(b,0) orelse igt(a,isub(MAX_REC_FUEL,b)) then ~1 else iadd(a,b)

