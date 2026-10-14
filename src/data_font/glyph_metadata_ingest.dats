#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/gdef_types.sats"
staload "data_font/gdef_classes.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/glyph_metadata_work.sats"
fun read{n,i:nat | i <= n} .<n-i>. (b: !Buf,c: GdefClassMetadata,rows: GlyphPropertyRows(n,i)): GlyphPropertyRows(n,n) = let
  val+ GlyphPropertyRows(data,count,filled)=rows
in if filled = count then rows else let
  val property: GlyphProperty= @{kind=gdef_glyph_kind(b,c,filled),attachment=gdef_mark_attachment(b,c,filled)}
in read(b,c,glyph_property_rows_append(rows,property)) end end
implement glyph_property_rows_read(b,c,glyphs) = read(b,c,glyph_property_rows_make(airlock_nat(glyphs)))
implement glyph_metadata_build(b,c,marks,font,glyphs) = let
  val info: GlyphMetadataInfo= @{font=font,glyphs=glyphs,classes=c.defined,attachments=c.attachmentDefined,source=GlyphClassesGdef()}
  val rows=glyph_property_rows_read(b,c,glyphs)
in GlyphMetadata(info,rows,marks) end
