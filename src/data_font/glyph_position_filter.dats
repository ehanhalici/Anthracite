#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/ot_layout_lookups.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/glyph_pass_work.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/glyph_metadata.sats"
staload "data_font/glyph_position_types.sats"
staload "data_font/glyph_position_filter.sats"
implement glyph_position_filter_check(m,meta,glyphs,flags,set) = let val info=glyph_metadata_info(m) in
  if ine(meta.font,info.font) orelse ine(meta.glyphs,info.glyphs) orelse ine(meta.glyphs,glyphs) then PositionDomain()
  else if not(glyph_metadata_run_ready(m,meta))
    orelse not(ot_lookup_dependencies(flags,set,glyph_metadata_capabilities(m))) then PositionReference()
  else PositionReady() end
implement glyph_position_eligible(b,m,flags,set,selection,core) =
  glyph_pass_selected(selection,core.mask) andalso glyph_metadata_allows_core(b,m,flags,set,core)
