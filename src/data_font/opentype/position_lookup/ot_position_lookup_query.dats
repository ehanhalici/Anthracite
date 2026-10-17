#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/position_lookup/ot_position_lookup_types.sats"
staload "data_font/opentype/position_lookup/ot_position_lookup_work.sats"
staload "data_font/opentype/position_lookup/ot_position_lookup.sats"
implement ot_position_lookup_info(t) = let val+ OtPositionLookup(h,a,glyphs,rows)=t in h end
implement ot_position_lookup_action(t) = let val+ OtPositionLookup(h,a,glyphs,rows)=t in a end
implement ot_position_lookup_glyphs(t) = let val+ OtPositionLookup(h,a,glyphs,rows)=t in glyphs end
implement ot_position_lookup_dispose(t) = let val+ ~OtPositionLookup(h,a,glyphs,rows)=t in ot_position_tables_dispose(rows) end
