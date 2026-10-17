#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/position/gpos_cursive_types.sats"
staload "data_font/opentype/position/gpos_cursive.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/core/glyph_metadata.sats"
staload "data_font/glyph/position/glyph_position_types.sats"
staload "data_font/glyph/position/glyph_position.sats"
staload "data_font/glyph/position/glyph_position_cursive.sats"
staload "font/glyph/position/glyph_position_contracts.sats"
datatype CursiveTestRoot = FirstRoot | LastRoot
extern fun cursive_position_test_failed(): GposCursive = "mac#anth_die_box"
fun table(b: !Buf): GposCursive = case+ gpos_cursive_parse(b,position_test_span(b),128) of
  | ~CursiveRejected(e) => cursive_position_test_failed() | ~CursiveAccepted(t) => t
fun flags(root: CursiveTestRoot): OtLookupFlags = @{rtl=case+ root of | FirstRoot() => false | LastRoot() => true,
  ignoreBase=false,ignoreLigature=false,ignoreMarks=false,useMarkSet=false,attachment=0}
fun cursive(parent: int,y: int): GlyphPosition = @{xAdvance=0,yAdvance=0,xOffset=0,yOffset=y,
  attachment=AttachmentCursive(),parent=parent,anchorX=0,anchorY=0}
fun check(d: GlyphPositionDirection,root: CursiveTestRoot,xa: int,xc: int,xoa: int,xoc: int,ya: int,yc: int): int = let
  val b=position_test_fixture("0001 000E 0002 0000 0016 001C 0000 0001 0002 0005 0006 0001 0064 00C8 0002 012C 0190 0007",TestBaseClasses())
  val t=table(b) and m=position_test_metadata(b) var errors: int=0
  val p=position_test_run("0005 0006",errors)
  val ()=position_test_set(p,1,@{xAdvance=500,yAdvance=0,xOffset=0,yOffset=0,attachment=AttachmentNone(),parent= ~1,anchorX=0,anchorY=0})
  val p=position_test_take(glyph_position_cursive(b,t,m,p,flags(root),0,position_test_all(),d),2,1,errors)
  val p=position_test_frozen(glyph_position_finish(p,d),errors)
  val ()=errors := errors+position_test_values(p,0,xa,0,xoa,ya)+position_test_values(p,1,xc,0,xoc,yc)
  val ()=glyph_position_dispose(p) and ()=glyph_metadata_dispose(m) and ()=gpos_cursive_dispose(t) and ()=buf_free(b)
in errors end
fun reverse(): int = let
  val b=position_test_fixture("0001 000E 0002 0000 0016 001C 0000 0001 0002 0005 0006 0001 0064 00C8 0002 012C 0190 0007",TestBaseClasses())
  val t=table(b) and m=position_test_metadata(b) var errors: int=0
  val p=position_test_run("0005 0006 0009 000A 000B",errors)
  val ()=position_test_set(p,0,cursive(3,17)) and ()=position_test_set(p,3,cursive(4,23))
  val ()=position_test_set(p,4,@{xAdvance=0,yAdvance=0,xOffset=0,yOffset=31,attachment=AttachmentNone(),parent= ~1,anchorX=0,anchorY=0})
  val p=position_test_take(glyph_position_cursive(b,t,m,p,flags(LastRoot()),0,position_test_all(),PositionRTL()),5,1,errors)
  val p=position_test_frozen(glyph_position_finish(p,PositionRTL()),errors)
  val ()=errors := errors+position_test_values(p,0,~100,0,~100,200)
    +position_test_values(p,3,0,0,0,183)+position_test_values(p,4,0,0,0,160)
  val ()=glyph_position_dispose(p) and ()=glyph_metadata_dispose(m) and ()=gpos_cursive_dispose(t) and ()=buf_free(b)
in errors end
implement position_test_cursive_cases() = check(PositionLTR(),FirstRoot(),100,200,0,~300,0,~200)
  +check(PositionLTR(),LastRoot(),100,200,0,~300,200,0)
  +check(PositionRTL(),FirstRoot(),924,300,~100,0,0,~200)
  +check(PositionRTL(),LastRoot(),924,300,~100,0,200,0)+reverse()
