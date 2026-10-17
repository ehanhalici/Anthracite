#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/layout/ot_layout_lookups.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/run/glyph_run_storage.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/core/glyph_metadata.sats"
staload "data_font/glyph/core/glyph_neighbor_types.sats"
staload "data_font/glyph/core/glyph_neighbor_work.sats"
implement glyph_neighbor_empty(status) = @{status=status,node= ~1,core=glyph_core_empty()}
implement glyph_neighbor_check(metadata,meta,flags,set) = let
  val info=glyph_metadata_info(metadata)
in if ine(info.font,meta.font) orelse ine(info.glyphs,meta.glyphs) then NeighborDomain()
  else if not(glyph_metadata_run_ready(metadata,meta))
    orelse not(ot_lookup_dependencies(flags,set,glyph_metadata_capabilities(metadata))) then NeighborReference()
  else NeighborFound() end
