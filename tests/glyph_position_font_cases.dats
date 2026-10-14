#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/gpos_mark_matrix_types.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/glyph_position_types.sats"
staload "data_font/sfnt.sats"
staload "data_text/unicode_db.sats"
staload "data_text/unicode_property.sats"
staload "glyph_position_contracts.sats"
staload "glyph_position_font_contracts.sats"
fun sizes(face: !SfntFace,db: !UnicodeDb,joining: !PropertyMap(3)): int =
  position_font_apply(face,db,joining,16,"011A 0048 FFE0 003D FF48 0345 015A FFE0")
  +position_font_apply(face,db,joining,24,"01A6 006C FFD0 005C FEEC 04E7 0207 FFD0")
  +position_font_apply(face,db,joining,48,"034D 00D7 FFA1 00B8 FDD7 09CE 040E FFA1")
  +position_font_apply(face,db,joining,1000,"44C0 1180 F840 0F00 D300 CC40 5480 F840")
fun loaded(arabic: string,db: !UnicodeDb,joining: !PropertyMap(3)): int = case+ sfnt_open(arabic) of
  | ~RejectedSfnt(e) => 1 | ~LoadedSfnt(face) => let val errors=sizes(face,db,joining) val ()=sfnt_dispose(face) in errors end
fun joined(arabic: string,db: !UnicodeDb,path: string): int = case+ property_load(path,JoiningProperty()) of
  | ~PropertyRejected(e) => 1 | ~PropertyLoaded(p) => let val errors=loaded(arabic,db,p) val ()=property_dispose(p) in errors end
implement position_test_fonts(latin,arabic,unicode,joining) = case+ unicode_load(unicode) of
  | ~UnicodeDataError() => 1 | ~UnicodeLoaded(db) => let val errors=joined(arabic,db,joining) val ()=unicode_dispose(db) in errors end
