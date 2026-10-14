#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/opentype_coverage.sats"
staload "data_font/gsub_single_types.sats"
staload "data_font/gsub_single_work.sats"
staload "data_font/opentype_glyphs.sats"
implement gsub_array_valid(b,s,count,glyphs) = ot_glyph_array_valid(b,s,6,count,glyphs)
