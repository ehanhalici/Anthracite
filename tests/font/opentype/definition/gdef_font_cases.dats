#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/sfnt/sfnt.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/definition/gdef_types.sats"
staload "data_font/opentype/definition/gdef_header.sats"
staload "data_font/opentype/definition/gdef_classes.sats"
staload "font/opentype/definition/gdef_contracts.sats"

fun is_mark(k: GdefGlyphKind): bool = case+ k of
  | GlyphMark() => true | GlyphBase() => false | GlyphUnclassified() => false
  | GlyphLigature() => false | GlyphComponent() => false
fun class_code(k: GdefGlyphKind): int = case+ k of
  | GlyphUnclassified() => 0 | GlyphBase() => 1 | GlyphLigature() => 2
  | GlyphMark() => 3 | GlyphComponent() => 4

fun glyphs(b: !Buf,info: SfntInfo,h: GdefHeaderInfo,base: int,mark: int,expected: GdefGlyphKind): int =
  case+ gdef_classes_parse(b,h,info.glyphs) of
  | ~GdefClassRejected(e) => 1
  | ~GdefClassAccepted(m) => let
    val bg=sfnt_map(b,info,base)
    val mg=sfnt_map(b,info,mark)
    val bk=gdef_glyph_kind(b,m,bg)
    val mk=gdef_glyph_kind(b,m,mg)
    val base_ok=ieq(class_code(bk),class_code(expected))
    val mark_ok=is_mark(mk)
    val ()=println!("event=gdef_font base_gid=",bg," mark_gid=",mg,
      " base_class=",class_code(bk)," mark_class=",class_code(mk),
      " base_class_ok=",base_ok," mark_class_ok=",mark_ok)
  in if base_ok andalso mark_ok andalso igt(bg,0) andalso igt(mg,0) then 0 else 1 end

fun table(b: !Buf,info: SfntInfo,base: int,mark: int,expected: GdefGlyphKind): int =
  case+ sfnt_table(b,info.tables,TableGdef()) of
  | ~NoSfntTable() => 1
  | ~HasSfntTable(span) => case+ gdef_header_parse(b,span) of
    | ~GdefHeaderRejected(e) => 1 | ~GdefHeaderAccepted(h) => glyphs(b,info,h,base,mark,expected)

fun face(face: !SfntFace,base: int,mark: int,expected: GdefGlyphKind): int = let val+ SfntFace(b,info)=face in
  table(b,info,base,mark,expected) end

implement gdef_test_font(path,base,mark,expected) = case+ sfnt_open(path) of
  | ~RejectedSfnt(e) => 1 | ~LoadedSfnt(font) => let
    val errors=face(font,base,mark,expected)
    val ()=sfnt_dispose(font)
  in errors end
