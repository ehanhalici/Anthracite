#include "data_font/native_shape_internal.hats"
fun gdef(b: !Buf,info: SfntInfo): OtChild = case+ sfnt_table(b,info.tables,TableGdef()) of
  | NoSfntTable() => @{kind=ChildMissing(),span= @{offset=0,length=0}}
  | HasSfntTable(span) => @{kind=ChildPresent(),span=span}
fun positions(b: !Buf,info: SfntInfo,font: int,m: GlyphMetadata,sub: NativeSubstitution): NativeShapeCacheRead =
  case+ native_shape_pos_cache(b,info,m,font) of
  | ~NativePosRejected(e) => let val ()=native_shape_sub_dispose(sub) and ()=glyph_metadata_dispose(m)
    in NativeCacheRejected(e) end
  | ~NativePosAccepted(pos) => NativeCacheAccepted(NativeShapeCache(m,sub,pos,@{font=font,glyphs=info.glyphs,units=info.units}))
fun substitutions(b: !Buf,info: SfntInfo,font: int,m: GlyphMetadata): NativeShapeCacheRead =
  case+ native_shape_sub_cache(b,info,m,font) of
  | ~NativeSubRejected(e) => let val ()=glyph_metadata_dispose(m) in NativeCacheRejected(e) end
  | ~NativeSubAccepted(sub) => positions(b,info,font,m,sub)
implement native_shape_cache_parse(b,info,font) = case+ glyph_metadata_parse(b,gdef(b,info),font,info.glyphs) of
  | ~GlyphMetadataRejected(e) => NativeCacheRejected(e)
  | ~GlyphMetadataAccepted(m) => substitutions(b,info,font,glyph_metadata_unicode(m))
implement native_shape_cache_dispose(cache) = let val+ ~NativeShapeCache(m,sub,pos,info)=cache
  val ()=native_shape_sub_dispose(sub) and ()=native_shape_pos_dispose(pos)
in glyph_metadata_dispose(m) end

