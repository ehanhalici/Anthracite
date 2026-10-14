#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/sfnt.sats"
staload "data_font/opentype_types.sats"
staload "data_font/gpos_mark_matrix_types.sats"
staload "data_font/gpos_mark_matrix.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_run.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/glyph_metadata.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/glyph_position_types.sats"
staload "data_font/glyph_position.sats"
staload "data_font/glyph_position_mark.sats"
staload "data_font/ot_position_lookup_types.sats"
staload "data_font/ot_position_lookup.sats"
staload "data_font/glyph_position_lookup.sats"
staload "data_font/glyph_position_stage_types.sats"
staload "data_font/glyph_position_stage.sats"
staload "data_font/glyph_position_work.sats"
staload "data_text/utf8.sats"
staload "data_text/unicode_db.sats"
staload "data_text/unicode_property.sats"
staload "glyph_nominal_contracts.sats"
staload "glyph_position_contracts.sats"
staload "glyph_position_font_contracts.sats"
staload "opentype_fixture.sats"
fun signed(raw: int): int = if ige(raw,32768) then isub(raw,65536) else raw
fun check(p: !GlyphPositioned(1),words: string): int = let
  val oracle=ot_fixture_words(words)
  val e=position_test_values(p,0,ot_fixture_read16(oracle,0),0,0,0)
    +position_test_values(p,3,0,0,ot_fixture_read16(oracle,2),signed(ot_fixture_read16(oracle,4)))
    +position_test_values(p,1,0,0,ot_fixture_read16(oracle,6),signed(ot_fixture_read16(oracle,8)))
    +position_test_values(p,2,ot_fixture_read16(oracle,10),0,0,0)
    +position_test_values(p,4,0,0,ot_fixture_read16(oracle,12),signed(ot_fixture_read16(oracle,14)))
  val ()=buf_free(oracle)
in e end
fun positions(b: !Buf,info: SfntInfo,m: !GlyphMetadata,p: GlyphPositioned(0),errors: &int >> _): GlyphPositioned(0) = let
  val dot=position_font_lookup(b,info,3)
  val p=position_test_take(glyph_position_lookup(b,dot,m,p,position_test_all(),PositionRTL()),5,2,errors)
  val ()=ot_position_lookup_dispose(dot)
  val vowel=position_font_lookup(b,info,13)
  val p=position_test_take(glyph_position_lookup(b,vowel,m,p,position_test_all(),PositionRTL()),5,1,errors)
  val ()=ot_position_lookup_dispose(vowel)
in p end
fun staged(b: !Buf,info: SfntInfo,m: !GlyphMetadata,p: GlyphPositioned(0),errors: &int >> _): GlyphPositioned(0) = let
  val stage=position_font_stage(b,info,m)
  val+ ~PositionStageResult(p,status,applied,matches)=glyph_position_stage_apply(b,stage,m,p,PositionRTL())
  val ()=if glyph_position_ready(status) andalso ieq(applied,24) andalso ieq(matches,3) then () else errors := iadd(errors,1)
  val ()=glyph_position_stage_dispose(stage)
in p end
datatype PositionTestPath = PositionPrimitives | PositionStage | PositionSchedule
fun adjust(path: PositionTestPath,b: !Buf,info: SfntInfo,m: !GlyphMetadata,p: GlyphPositioned(0),
  errors: &int >> int): GlyphPositioned(0) = case+ path of
  | PositionPrimitives() => positions(b,info,m,p,errors) | PositionStage() => staged(b,info,m,p,errors)
  | PositionSchedule() => position_font_scheduled(b,info,m,p,errors)
fun example(path: PositionTestPath,face: !SfntFace,db: !UnicodeDb,joining: !PropertyMap(3),text: !ScalarText,
  m: !GlyphMetadata,ppem: int,oracle: string): int = let
  val+ SfntFace(b,info)=face var errors: int=0
  val run=nominal_test_arabic_run(face,db,text,joining,errors)
  val p=adjust(path,b,info,m,position_font_initialized(face,glyph_run_position(run),ppem),errors)
  val p=position_test_frozen(glyph_position_finish(p,PositionRTL()),errors)
  val errors=iadd(errors,check(p,oracle)) val ()=glyph_position_dispose(p)
in errors end
implement position_font_apply(face,db,joining,ppem,oracle) = let
  val+ SfntFace(b,info)=face val m=nominal_test_metadata(b,info)
  val source=nominal_test_bytes("بَب") val text=nominal_test_decode(source)
  val errors=example(PositionPrimitives(),face,db,joining,text,m,ppem,oracle)
    +example(PositionStage(),face,db,joining,text,m,ppem,oracle)
    +example(PositionSchedule(),face,db,joining,text,m,ppem,oracle)
  val ()=glyph_metadata_dispose(m) and ()=scalar_dispose(text) and ()=buf_free(source)
in errors end
