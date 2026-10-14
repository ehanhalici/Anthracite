#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/gpos_mark_matrix_types.sats"
staload "data_font/ot_position_lookup_types.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/glyph_metadata.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/glyph_position_types.sats"
staload "data_font/glyph_position.sats"
staload "data_font/glyph_position_work.sats"
staload "data_font/glyph_position_stage_types.sats"
staload "data_font/glyph_position_stage.sats"
staload "glyph_position_contracts.sats"
staload "glyph_position_font_contracts.sats"
fun fixture(): Buf = position_test_fixture("0001 0000 000A 001E 002E 0001 6172 6162 0008 0004 0000 0000 FFFF 0001 0000 0001 6D61 726B 0008 0000 0002 0000 0001 0002 0006 001E 0001 0000 0001 0008 0001 000A 0005 0001 0001 0001 0001 0005 0001 0000 0001 0008 0001 0008 0004 0001 0001 0001 0005",TestBaseClasses())
fun basic(): int = let val b=fixture() and baseline=mem_live() val m=position_test_metadata(b)
  val stage=position_test_stage_build(b,position_test_span(b),m) var errors: int=0 val p=position_test_run("0005 0005",errors)
  val+ ~PositionStageResult(p,status,applied,matches)=glyph_position_stage_apply(b,stage,m,p,PositionLTR())
  val ()=errors := iadd(errors,if glyph_position_ready(status) andalso ieq(applied,2) andalso ieq(matches,4) then 0 else 1)
  val ()=errors := errors+position_test_values(p,0,1026,0,1,0)+position_test_values(p,1,2,0,1,0)
  val ()=glyph_position_dispose(p) and ()=glyph_position_stage_dispose(stage) and ()=glyph_metadata_dispose(m) and ()=buf_free(b)
in errors end
fun rollback(): int = let val b=fixture() val m=position_test_metadata(b)
  val stage=position_test_stage_build(b,position_test_span(b),m) var errors: int=0 val p=position_test_run("0005 0005",errors)
  val ()=position_test_set(p,0,@{xAdvance=2147483646,yAdvance=0,xOffset=0,yOffset=0,attachment=AttachmentNone(),parent= ~1,anchorX=0,anchorY=0})
  val+ ~PositionStageResult(p,status,applied,matches)=glyph_position_stage_apply(b,stage,m,p,PositionLTR())
  val overflow=case+ status of | PositionOverflow() => true | PositionReady() => false | PositionDomain() => false
    | PositionReference() => false | PositionCapacity() => false | PositionVariation() => false
  val ()=errors := iadd(errors,if overflow andalso ieq(applied,0) andalso ieq(matches,0) then 0 else 1)
  val ()=errors := errors+position_test_values(p,0,2147483646,0,0,0)+position_test_values(p,1,0,0,0,0)
  val ()=glyph_position_dispose(p) and ()=glyph_position_stage_dispose(stage) and ()=glyph_metadata_dispose(m) and ()=buf_free(b)
in errors end
implement position_test_stage_cases() = basic()+rollback()
