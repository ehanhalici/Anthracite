#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_reader.sats"
staload "data_font/opentype/definition/gdef_types.sats"
staload "data_font/opentype/definition/gdef_header.sats"
staload "data_font/opentype/definition/gdef_classes.sats"
staload "data_font/opentype/definition/gdef_marks.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/core/glyph_metadata_work.sats"
staload "data_font/glyph/core/glyph_metadata.sats"
fun marks(b: !Buf,h: GdefHeaderInfo,c: GdefClassMetadata,font: int,glyphs: int): GlyphMetadataRead =
  case+ gdef_marks_parse(b,h,glyphs) of
  | ~GdefMarksRejected(e) => GlyphMetadataRejected(e)
  | ~GdefMarksAccepted(sets) => GlyphMetadataAccepted(glyph_metadata_build(b,c,sets,font,glyphs))
fun classes(b: !Buf,h: GdefHeaderInfo,font: int,glyphs: int): GlyphMetadataRead =
  case+ gdef_classes_parse(b,h,glyphs) of
  | ~GdefClassRejected(e) => GlyphMetadataRejected(e)
  | ~GdefClassAccepted(c) => marks(b,h,c,font,glyphs)
fun header(b: !Buf,s: OtSpan,font: int,glyphs: int): GlyphMetadataRead = case+ gdef_header_parse(b,s) of
  | ~GdefHeaderRejected(e) => GlyphMetadataRejected(e)
  | ~GdefHeaderAccepted(h) => classes(b,h,font,glyphs)
implement glyph_metadata_parse(b,gdef,font,glyphs) =
  if ilt(font,0) orelse not(ot_glyph_domain_valid(glyphs)) then GlyphMetadataRejected(ot_error(OtGlyphDomain(),gdef.span))
  else case+ gdef.kind of
  | ChildInvalid() => GlyphMetadataRejected(ot_error(OtBounds(),gdef.span))
  | ChildPresent() => header(b,gdef.span,font,glyphs)
  | ChildMissing() => GlyphMetadataAccepted(glyph_metadata_build(b,glyph_metadata_empty_classes(),GdefNoMarks(),font,glyphs))
