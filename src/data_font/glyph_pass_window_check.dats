#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/ot_context_types.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_run_storage.sats"
staload "data_font/glyph_run_work.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/glyph_metadata.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/glyph_pass_work.sats"
staload "data_font/glyph_pass_window_types.sats"
staload "data_font/glyph_pass_window_work.sats"
staload "data_font/glyph_neighbor_types.sats"
staload "data_font/glyph_neighbor_work.sats"
implement glyph_window_check(b,m,s,meta,o,node) = case+ glyph_neighbor_check(m,meta,o.flags,o.set) of
  | NeighborDomain() => WindowDomain() | NeighborReference() => WindowReference()
  | NeighborNode() => WindowReference() | NeighborEnd() => WindowReference()
  | NeighborFound() => if not(glyph_run_node(s,meta,node)) then WindowReference() else let
    val core=glyph_storage_core(s,node)
  in if not(glyph_pass_selected(o.selection,core.mask)) orelse not(glyph_metadata_allows_core(b,m,o.flags,o.set,core))
    then WindowSkipped() else WindowReady() end
