#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/ot_layout_lookups.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/glyph_metadata.sats"
staload "data_font/glyph_pass_work.sats"
implement glyph_pass_domain_check(meta,metadata,glyphs,flags,set,count) = let
  val info=glyph_metadata_info(metadata)
in if ine(meta.font,info.font) orelse ine(meta.glyphs,info.glyphs) orelse ine(meta.glyphs,glyphs)
  then GlyphPassDomain()
  else if not(glyph_metadata_run_ready(metadata,meta))
    orelse not(ot_lookup_dependencies(flags,set,glyph_metadata_capabilities(metadata))) then GlyphPassReference()
  else if igt(meta.live,idiv(MAX_REC_FUEL,iadd(count,1))) then GlyphPassCapacity()
  else GlyphPassApplied() end
