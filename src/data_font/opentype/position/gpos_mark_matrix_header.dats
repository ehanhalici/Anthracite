#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_reader.sats"
staload "data_font/opentype/position/gpos_value_types.sats"
staload "data_font/opentype/position/gpos_values.sats"
staload "data_font/opentype/position/gpos_anchor_cache_types.sats"
staload "data_font/opentype/position/gpos_anchor_cache.sats"
staload "data_font/opentype/position/gpos_mark_matrix_types.sats"
staload "data_font/opentype/tables/opentype_coverage.sats"
staload "data_font/opentype/position/gpos_mark_matrix_work.sats"
staload "data_font/opentype/position/gpos_mark_shared_types.sats"
staload "data_font/opentype/position/gpos_mark_shared.sats"
implement gpos_mark_matrix_header(b,s,glyphs) = case+ gpos_mark_header(b,s,glyphs) of
  | ~MarkHeaderRejected(e) => MarkMatrixHeaderRejected(e)
  | ~MarkHeaderAccepted(info) => gpos_mark_matrix_validate(info)
