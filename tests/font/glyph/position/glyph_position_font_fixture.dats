#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/sfnt/sfnt.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_reader.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/layout/ot_layout_header.sats"
staload "data_font/opentype/layout/ot_layout_lookups.sats"
staload "data_font/opentype/layout/ot_layout_lookup_header.sats"
staload "data_font/opentype/position/gpos_mark_matrix_types.sats"
staload "data_font/opentype/position/gpos_mark_matrix.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/run/glyph_run.sats"
staload "data_font/glyph/position/glyph_position_types.sats"
staload "data_font/glyph/position/glyph_position.sats"
staload "data_font/opentype/position_lookup/ot_position_lookup_types.sats"
staload "data_font/opentype/position_lookup/ot_position_lookup.sats"
staload "font/glyph/position/glyph_position_font_contracts.sats"
extern fun position_font_table_failed(): PositionFontTable = "mac#anth_die_box"
extern fun position_font_init_failed(): GlyphPositioned(0) = "mac#anth_die_box"
extern fun position_font_lookup_failed(): OtPositionLookup = "mac#anth_die_box"
fun payload(b: !Buf,info: SfntInfo,h: OtLookupInfo(2)): PositionFontTable = let
  val child=ot_optional_child(h.span,ot_u16(b,h.span,6),ot_lookup_header_floor(h))
in if ine(h.count,1) orelse ine(ot_u16(b,h.span,0),4) then position_font_table_failed() else case+ child.kind of
  | ChildMissing() => position_font_table_failed() | ChildInvalid() => position_font_table_failed()
  | ChildPresent() => (case+ gpos_mark_matrix_parse(b,child.span,info.glyphs,MarkToBase()) of
    | ~MarkMatrixRejected(e) => position_font_table_failed() | ~MarkMatrixAccepted(t) => PositionFontTable(t,h.flags,h.markSet)) end
fun lookup(b: !Buf,info: SfntInfo,h: OtLayoutInfo,index: int): PositionFontTable = let val child=ot_lookup_span(b,h,index) in
  case+ child.kind of | ChildMissing() => position_font_table_failed() | ChildInvalid() => position_font_table_failed()
  | ChildPresent() => (case+ ot_lookup_header_parse(b,child.span,OtPositioning()) of
    | ~LookupHeaderRejected(e) => position_font_table_failed() | ~LookupHeaderAccepted(h) => payload(b,info,h)) end
implement position_font_table(b,info,index) = case+ sfnt_table(b,info.tables,TableGpos()) of
  | NoSfntTable() => position_font_table_failed()
  | HasSfntTable(s) => (case+ ot_layout_header_parse(b,s) of
    | ~HeaderRejected(e) => position_font_table_failed() | ~HeaderAccepted(h) => lookup(b,info,h,index))
implement position_font_initialized(face,run,ppem) = case+ glyph_position_initialize(face,run,ppem,ppem) of
  | ~PositionInitialized(p) => p
  | ~PositionRejected(run,s) => let val ()=glyph_run_dispose(run) in position_font_init_failed() end
fun cached(b: !Buf,info: SfntInfo,h: OtLayoutInfo,index: int): OtPositionLookup = let val child=ot_lookup_span(b,h,index) in
  case+ child.kind of | ChildMissing() => position_font_lookup_failed() | ChildInvalid() => position_font_lookup_failed()
  | ChildPresent() => (case+ ot_position_lookup_parse(b,child.span,info.glyphs) of
    | ~PositionLookupRejected(e) => position_font_lookup_failed() | ~PositionLookupAccepted(t) => t) end
implement position_font_lookup(b,info,index) = case+ sfnt_table(b,info.tables,TableGpos()) of
  | NoSfntTable() => position_font_lookup_failed()
  | HasSfntTable(s) => (case+ ot_layout_header_parse(b,s) of
    | ~HeaderRejected(e) => position_font_lookup_failed() | ~HeaderAccepted(h) => cached(b,info,h,index))
