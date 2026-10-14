#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/gdef_types.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/glyph_metadata.sats"
staload "data_font/ot_single_lookup_types.sats"
staload "opentype_fixture.sats"
staload "glyph_lookup_contracts.sats"
fun kind_code(k: GdefGlyphKind): int = case+ k of
  | GlyphUnclassified() => 0 | GlyphBase() => 1 | GlyphLigature() => 2 | GlyphMark() => 3 | GlyphComponent() => 4
fun expect(m: !GlyphMetadata,glyph: int,kind: int,attachment: int): int = let
  val v=glyph_metadata_property(m,glyph)
in if v.found andalso ieq(kind_code(v.property.kind),kind) andalso ieq(v.property.attachment,attachment) then 0 else 1 end
fun properties(b: !Buf): int = let
  val m=lookup_test_metadata(b,3,128)
  val info=glyph_metadata_info(m) and caps=glyph_metadata_capabilities(m)
  val outside=glyph_metadata_property(m,128) and negative=glyph_metadata_property(m,~1)
  val errors=expect(m,0,0,0)+expect(m,10,1,0)+expect(m,11,2,0)+expect(m,12,3,1)+
    expect(m,13,4,0)+expect(m,14,0,0)+expect(m,15,3,2)
  val ok=ieq(info.font,3) andalso ieq(info.glyphs,128) andalso caps.classes andalso caps.attachments
    andalso ieq(caps.markSets,1) andalso not(outside.found orelse negative.found)
  val ()=glyph_metadata_dispose(m)
in iadd(errors,if ok then 0 else 1) end
fun reject(b: !Buf,child: OtChild,font: int,glyphs: int): int = case+ glyph_metadata_parse(b,child,font,glyphs) of
  | ~GlyphMetadataRejected(e) => 0 | ~GlyphMetadataAccepted(m) => let val ()=glyph_metadata_dispose(m) in 1 end
fun cuts{n:nat} .<n>. (n: int(n),b: !Buf,length: int): int =
  if n = 0 then 0 else reject(b,@{kind=ChildPresent(),span= @{offset=8,length=length}},3,128)+cuts(n-1,b,iadd(length,1))
fun maximum(b: !Buf): int = case+ glyph_metadata_parse(b,@{kind=ChildMissing(),span= @{offset=0,length=0}},3,65535) of
  | ~GlyphMetadataRejected(e) => 1 | ~GlyphMetadataAccepted(m) => let
    val errors=expect(m,65534,0,0)
    val outside=glyph_metadata_property(m,65535)
    val caps=glyph_metadata_capabilities(m)
    val ()=glyph_metadata_dispose(m)
  in iadd(errors,if not(outside.found orelse caps.classes orelse caps.attachments) andalso ieq(caps.markSets,0) then 0 else 1) end
implement lookup_test_properties() = let
  val b=lookup_test_fixture(0)
  val present: OtChild= @{kind=ChildPresent(),span= @{offset=8,length=60}}
  val errors=properties(b)+cuts(60,b,0)+maximum(b)+reject(b,present,~1,128)+reject(b,present,3,0)+
    reject(b,present,3,65536)+reject(b,@{kind=ChildInvalid(),span= @{offset=0,length=0}},3,128)
  val ()=ot_fixture_put16(b,20,5)
  val malformed=reject(b,present,3,128)
  val ()=buf_free(b)
in errors+malformed end
