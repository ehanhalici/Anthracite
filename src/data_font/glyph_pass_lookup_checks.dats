#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/ot_layout_lookups.sats"
staload "data_font/ot_single_lookup_types.sats"
staload "data_font/ot_single_lookup.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/glyph_metadata.sats"
staload "data_font/glyph_pass_lookup_work.sats"
staload "data_font/glyph_pass_work.sats"
implement glyph_pass_lookup_check(lookup,metadata,meta) = let
  val header=ot_single_lookup_header(lookup)
in glyph_pass_domain_check(meta,metadata,ot_single_lookup_glyphs(lookup),header.flags,header.markSet,header.count) end
