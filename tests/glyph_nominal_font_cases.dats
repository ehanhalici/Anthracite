#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "os/fs.sats"
staload "data_font/sfnt.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_run.sats"
staload "data_font/glyph_nominal.sats"
staload "data_text/utf8.sats"
staload "data_text/unicode_db.sats"
staload "opentype_fixture.sats"
staload "glyph_nominal_contracts.sats"
staload "data_text/unicode_property.sats"
staload "ot_shape_contracts.sats"
fun note(face: !SfntFace,db: !UnicodeDb): int = if ieq(c_argc(),6) then nominal_test_file(face,db,c_argv(5)) else 0
fun latin(path: string,db: !UnicodeDb): int = case+ sfnt_open(path) of
  | ~RejectedSfnt(e) => 1 | ~LoadedSfnt(face) => let
    val errors=nominal_test_mixed(face,db)+nominal_test_malformed(face,db)+nominal_test_stress(face,db)+note(face,db)
    val ()=sfnt_dispose(face)
  in errors end
fun arabic(path: string,db: !UnicodeDb,joining: !PropertyMap(3)): int = case+ sfnt_open(path) of
  | ~RejectedSfnt(e) => 1 | ~LoadedSfnt(face) => let
    val errors=nominal_test_mixed(face,db)+nominal_test_malformed(face,db)+nominal_test_stress(face,db)+note(face,db)
    val ccmp=nominal_test_arabic(face,db,joining)
    val scheduled=shape_test_font(face,db,joining)
    val ()=sfnt_dispose(face)
    val ()=println!("event=glyph_nominal_arabic source_errors=",errors," ccmp_form_errors=",ccmp)
    val ()=println!("event=ot_shape_arabic_font errors=",scheduled)
  in errors+ccmp+scheduled end
fun joining(latin_path: string,arabic_path: string,db: !UnicodeDb,path: string): int =
  case+ property_load(path,JoiningProperty()) of
  | ~PropertyRejected(e) => 1 | ~PropertyLoaded(map) => let
    val errors=latin(latin_path,db)+arabic(arabic_path,db,map)
    val ()=property_dispose(map)
  in errors end
implement nominal_test_fonts(latin,arabic,unicode,joining_path) = case+ unicode_load(unicode) of
  | ~UnicodeDataError() => 1 | ~UnicodeLoaded(db) => let
    val errors=joining(latin,arabic,db,joining_path)
    val ()=unicode_dispose(db)
  in errors end
