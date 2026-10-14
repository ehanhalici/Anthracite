#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "mem.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/glyph_pass_work.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/glyph_metadata.sats"
staload "data_font/ot_sequence_lookup_types.sats"
staload "data_font/ot_sequence_lookup.sats"
staload "data_font/glyph_pass_sequence_work.sats"
implement glyph_pass_sequence_check(t,m,meta) = let val h=ot_sequence_lookup_header(t) in
  glyph_pass_domain_check(meta,m,ot_sequence_lookup_glyphs(t),h.flags,h.markSet,h.count) end
implement glyph_pass_sequence_eligible(b,m,h,selection,core) =
  glyph_pass_selected(selection,core.mask) andalso glyph_metadata_allows_core(b,m,h.flags,h.markSet,core)
