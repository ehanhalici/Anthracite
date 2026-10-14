#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/gpos_mark_matrix_types.sats"
staload "data_font/gpos_mark_ligature_types.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_run_storage.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/glyph_position_types.sats"
staload "data_font/glyph_position_mark_work.sats"
implement glyph_position_mark_base_accept(m,s,c,previous) =
  if not(c.multiplied) orelse ieq(c.component,0) orelse ieq(previous,~1) then true else let
    val p=glyph_storage_core(s,previous)
  in glyph_position_is_mark(m,p) orelse not(p.multiplied) orelse ine(c.ligature,p.ligature)
    orelse ine(c.component,iadd(p.component,1)) end
