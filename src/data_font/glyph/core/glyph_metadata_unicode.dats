#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/definition/gdef_types.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/core/glyph_metadata.sats"
implement glyph_metadata_unicode(metadata) = let val+ ~GlyphMetadata(info,rows,marks)=metadata
  val next: GlyphMetadataInfo= @{font=info.font,glyphs=info.glyphs,classes=info.classes,
    attachments=info.attachments,source=GlyphClassesUnicode()}
in GlyphMetadata(next,rows,marks) end
implement glyph_metadata_has_classes(m) = let val info=glyph_metadata_info(m)
in info.classes orelse (case+ info.source of | GlyphClassesGdef() => false | GlyphClassesUnicode() => true) end
implement glyph_metadata_run_ready(m,meta) = let val info=glyph_metadata_info(m)
in if info.classes then true else case+ info.source of | GlyphClassesGdef() => true
  | GlyphClassesUnicode() => (case+ meta.properties of | GlyphSourceRaw() => false | GlyphSourceUnicode() => true) end
implement glyph_metadata_core_property(m,core) = let val info=glyph_metadata_info(m)
  val property=glyph_metadata_property(m,core.glyph)
in if not(property.found) orelse info.classes then property else case+ info.source of
  | GlyphClassesGdef() => property | GlyphClassesUnicode() =>
    @{found=true,property= @{kind=core.unicodeKind,attachment=property.property.attachment}} end
