#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/opentype_coverage.sats"
staload "data_font/ot_layout_work.sats"
staload "data_font/ot_cov_cache_work.sats"
implement ot_cov_cache_parse_child(b,child,glyphs,remaining) = case+ child.kind of
  | ChildMissing() => CoverageRejected(ot_error(OtBounds(),child.span))
  | ChildInvalid() => CoverageRejected(ot_error(OtBounds(),child.span))
  | ChildPresent() => if ilt(child.span.length,4) then CoverageRejected(ot_error(OtBounds(),child.span))
    else if not(ot_layout_charge(remaining,iadd(ot_u16(b,child.span,2),1)))
      then CoverageRejected(ot_error(OtCapacity(),child.span))
    else ot_coverage_parse(b,child.span,glyphs)
