#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/position/gpos_mark_matrix_types.sats"
staload "data_font/opentype/position/gpos_mark_matrix.sats"
staload "data_font/opentype/position/gpos_mark_ligature_types.sats"
staload "data_font/opentype/position/gpos_mark_ligature.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/core/glyph_metadata.sats"
staload "data_font/glyph/position/glyph_position_types.sats"
staload "data_font/glyph/position/glyph_position.sats"
staload "data_font/glyph/position/glyph_position_mark.sats"
staload "font/glyph/position/glyph_position_contracts.sats"
staload "font/opentype/tables/opentype_fixture.sats"
extern fun matrix_position_test_failed{kind:int}(): GposMarkMatrix(kind) = "mac#anth_die_box"
extern fun ligature_position_test_failed(): GposMarkLigature = "mac#anth_die_box"
fun words(): string = "0001 000C 0014 0002 001C 0032 0001 0002 0007 0008 0001 0002 0005 0006 0002 0000 000A 0001 0010 0001 000A 0014 0001 001E 0028 0002 000A 0010 0000 0016 0001 0064 00C8 0001 012C 0190 0001 01F4 0258"
fun ligature_table(b: !Buf): GposMarkLigature = case+ gpos_mark_ligature_parse(b,position_test_span(b),128) of
  | ~MarkLigatureRejected(e) => ligature_position_test_failed() | ~MarkLigatureAccepted(t) => t
fun table{kind:int}(b: !Buf,d: GposMarkMatrixDomain(kind)): GposMarkMatrix(kind) =
  case+ gpos_mark_matrix_parse(b,position_test_span(b),128,d) of
  | ~MarkMatrixRejected(e) => matrix_position_test_failed() | ~MarkMatrixAccepted(t) => t
fun base(d: GlyphPositionDirection,want: int): int = let
  val b=position_test_fixture(words(),TestBaseClasses()) val t=table(b,MarkToBase()) and m=position_test_metadata(b)
  var errors: int=0
  val p=position_test_run("0005 0007 0008",errors)
  val p=position_test_take(glyph_position_mark_matrix(b,t,m,p,position_test_flags(),0,position_test_all()),3,2,errors)
  val ()=errors := errors+position_test_values(p,1,0,0,90,180)+position_test_values(p,2,0,0,270,360)
  val p=position_test_frozen(glyph_position_finish(p,d),errors)
  val ()=errors := errors+position_test_values(p,1,0,0,want,180)+position_test_values(p,2,0,0,want+180,360)
  val ()=glyph_position_dispose(p) and ()=glyph_metadata_dispose(m) and ()=gpos_mark_matrix_dispose(t) and ()=buf_free(b)
in errors end
fun mark(): int = let
  val b=position_test_fixture(words(),TestMarkClasses()) val ()=ot_fixture_put16(b,26,7)
  val t=table(b,MarkToMark()) and m=position_test_metadata(b)
  var errors: int=0
  val p=position_test_run("0005 0007 0008",errors)
  val p=position_test_take(glyph_position_mark_matrix(b,t,m,p,position_test_flags(),0,position_test_all()),3,2,errors)
  val ()=errors := errors+position_test_values(p,1,0,0,90,180)+position_test_values(p,2,0,0,470,740)
  val p=position_test_frozen(glyph_position_finish(p,PositionLTR()),errors)
  val ()=errors := errors+position_test_values(p,2,0,0,~464,740)
  val ()=glyph_position_dispose(p) and ()=glyph_metadata_dispose(m) and ()=gpos_mark_matrix_dispose(t) and ()=buf_free(b)
in errors end
fun ligature(): int = let
  val b=position_test_fixture("0001 000C 0014 0002 001C 0032 0001 0002 0007 0008 0001 0002 0005 0006 0002 0000 000A 0001 0010 0001 000A 0014 0001 001E 0028 0002 0006 0022 0002 000A 0010 0000 0016 0001 0064 00C8 0001 012C 0190 0001 01F4 0258 0001 0006 0000 0001 02BC 0320",TestBaseClasses())
  val t=ligature_table(b)
  val m=position_test_metadata(b) var errors: int=0
  val p=position_test_run("0005 0008",errors)
  val p=position_test_take(glyph_position_mark_ligature(b,t,m,p,position_test_flags(),0,position_test_all()),2,1,errors)
  val ()=errors := errors+position_test_values(p,1,0,0,470,560)
  val ()=glyph_position_dispose(p) and ()=glyph_metadata_dispose(m) and ()=gpos_mark_ligature_dispose(t) and ()=buf_free(b)
in errors end
implement position_test_mark_cases() = base(PositionLTR(),~934)+base(PositionRTL(),90)+mark()+ligature()
