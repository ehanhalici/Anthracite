#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/definition/gdef_types.sats"
staload "data_font/opentype/definition/gdef_marks.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/core/glyph_metadata_work.sats"
staload "data_font/glyph/core/glyph_metadata.sats"
implement glyph_metadata_info(metadata) = let val+ GlyphMetadata(info,rows,marks)=metadata in info end
implement glyph_metadata_capabilities(metadata) = let val+ GlyphMetadata(info,rows,marks)=metadata in
  @{classes=glyph_metadata_has_classes(metadata),attachments=info.attachments,markSets=gdef_mark_set_count(marks)} end
implement glyph_metadata_property(metadata,glyph) = let val+ GlyphMetadata(info,rows,marks)=metadata in
  if ilt(glyph,0) orelse ige(glyph,info.glyphs) then
    @{found=false,property= @{kind=GlyphUnclassified(),attachment=0}}
  else @{found=true,property=glyph_property_rows_get(rows,glyph)} end
implement glyph_metadata_dispose(metadata) = let val+ ~GlyphMetadata(info,rows,marks)=metadata
  val ()=glyph_property_rows_dispose(rows)
in gdef_marks_dispose(marks) end
