#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/gpos_mark_matrix_types.sats"
staload "data_font/gpos_mark_ligature_types.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/gdef_types.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/glyph_metadata.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/glyph_position_types.sats"
staload "data_font/glyph_position_work.sats"
staload "data_font/glyph_position_filter.sats"
staload "data_font/glyph_position_mark_work.sats"
implement glyph_position_is_mark(m,core) = let val v=glyph_metadata_core_property(m,core) in
  v.found andalso (case+ v.property.kind of | GlyphMark() => true | GlyphBase() => false
    | GlyphLigature() => false | GlyphComponent() => false | GlyphUnclassified() => false) end
implement glyph_position_mark_flags(f) = @{rtl=f.rtl,ignoreBase=false,ignoreLigature=false,
  ignoreMarks=false,useMarkSet=f.useMarkSet,attachment=f.attachment}
implement glyph_position_mark_check(m,meta,glyphs,f,set) = let val info=glyph_metadata_info(m)
  val status=glyph_position_filter_check(m,meta,glyphs,f,set)
in if not(glyph_position_ready(status)) then status else if not(glyph_metadata_has_classes(m)) then PositionReference() else PositionReady() end
