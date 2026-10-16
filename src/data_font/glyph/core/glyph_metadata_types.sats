staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/definition/gdef_types.sats"
typedef GlyphProperty = @{kind=GdefGlyphKind,attachment=int}
typedef GlyphPropertyView = @{found=bool,property=GlyphProperty}
datatype GlyphClassSource = GlyphClassesGdef | GlyphClassesUnicode
typedef GlyphMetadataInfo = @{font=int,glyphs=int,classes=bool,attachments=bool,source=GlyphClassSource}
datavtype GlyphPropertyRows(int,int) = {n:nat}{i:nat | i <= n}{l:addr} GlyphPropertyRows(n,i) of
  (arrayptr(GlyphProperty,l,n),int(n),int(i))
datavtype GlyphMetadata = {n:nat} GlyphMetadata of (GlyphMetadataInfo,GlyphPropertyRows(n,n),GdefMarkSets)
datavtype GlyphMetadataRead = GlyphMetadataAccepted of GlyphMetadata | GlyphMetadataRejected of OtError
