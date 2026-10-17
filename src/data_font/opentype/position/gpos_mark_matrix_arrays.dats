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
staload "data_font/opentype/position/gpos_mark_shared_types.sats"
staload "data_font/opentype/position/gpos_mark_shared.sats"
staload "data_font/opentype/position/gpos_mark_matrix_types.sats"
staload "data_font/opentype/position/gpos_mark_matrix_work.sats"
implement gpos_mark_matrix_validate(info) =
  if not(ot_rows_fit(info.targetArray,2,info.targetCount,imul(info.classes,2)))
    then MarkMatrixHeaderRejected(ot_error(OtBounds(),info.targetArray))
  else if not(ot_anchor_cache_capacity(imul(info.targetCount,info.classes)))
    then MarkMatrixHeaderRejected(ot_error(OtCapacity(),info.targetArray))
  else MarkMatrixHeaderAccepted(info)
