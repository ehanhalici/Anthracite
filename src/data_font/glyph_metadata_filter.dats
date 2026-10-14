#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/gdef_types.sats"
staload "data_font/gdef_marks.sats"
staload "data_font/opentype_lookup_flags.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/glyph_metadata.sats"
fun member(b: !Buf,marks: !GdefMarkSets,f: OtLookupFlags,set: int,glyph: int,k: GdefGlyphKind): bool = case+ k of
  | GlyphMark() => if f.ignoreMarks orelse not(f.useMarkSet) then true else gdef_mark_contains(b,marks,set,glyph)
  | GlyphUnclassified() => true | GlyphBase() => true | GlyphLigature() => true | GlyphComponent() => true
fun allows(b: !Buf,metadata: !GlyphMetadata,f: OtLookupFlags,set: int,glyph: int,property: GlyphPropertyView): bool = let
  val+ GlyphMetadata(info,rows,marks)=metadata
in property.found andalso not(ot_lookup_skips_context(f,property.property.kind,
  property.property.attachment,member(b,marks,f,set,glyph,property.property.kind))) end
implement glyph_metadata_allows(b,metadata,f,set,glyph) =
  allows(b,metadata,f,set,glyph,glyph_metadata_property(metadata,glyph))
implement glyph_metadata_allows_core(b,metadata,f,set,core) =
  allows(b,metadata,f,set,core.glyph,glyph_metadata_core_property(metadata,core))
