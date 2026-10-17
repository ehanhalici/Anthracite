#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_reader.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/layout/ot_layout_extension.sats"
staload "data_font/opentype/position/gpos_single_types.sats"
staload "data_font/opentype/position/gpos_single.sats"
staload "data_font/opentype/position/gpos_pair_types.sats"
staload "data_font/opentype/position/gpos_pairs.sats"
staload "data_font/opentype/position/gpos_cursive_types.sats"
staload "data_font/opentype/position/gpos_cursive.sats"
staload "data_font/opentype/position/gpos_mark_matrix_types.sats"
staload "data_font/opentype/position/gpos_mark_matrix.sats"
staload "data_font/opentype/position/gpos_mark_ligature_types.sats"
staload "data_font/opentype/position/gpos_mark_ligature.sats"
staload "data_font/opentype/position_lookup/ot_position_lookup_types.sats"
staload "data_font/opentype/position_lookup/ot_position_lookup_work.sats"
implement ot_position_payload_parse(b,s,glyphs,a) = case+ a of
  | PosSingle() => (case+ gpos_single_parse(b,s,glyphs) of | ~PositionSingleRejected(e) => PositionPayloadRejected(e)
    | ~PositionSingleAccepted(t) => PositionPayloadAccepted(PositionPayloadSingle(t)))
  | PosPair() => (case+ gpos_pair_parse(b,s,glyphs) of | ~PairRejected(e) => PositionPayloadRejected(e)
    | ~PairAccepted(t) => PositionPayloadAccepted(PositionPayloadPair(t)))
  | PosCursive() => (case+ gpos_cursive_parse(b,s,glyphs) of | ~CursiveRejected(e) => PositionPayloadRejected(e)
    | ~CursiveAccepted(t) => PositionPayloadAccepted(PositionPayloadCursive(t)))
  | PosMarkBase() => (case+ gpos_mark_matrix_parse(b,s,glyphs,MarkToBase()) of | ~MarkMatrixRejected(e) => PositionPayloadRejected(e)
    | ~MarkMatrixAccepted(t) => PositionPayloadAccepted(PositionPayloadBase(t)))
  | PosMarkLigature() => (case+ gpos_mark_ligature_parse(b,s,glyphs) of | ~MarkLigatureRejected(e) => PositionPayloadRejected(e)
    | ~MarkLigatureAccepted(t) => PositionPayloadAccepted(PositionPayloadLigature(t)))
  | PosMarkMark() => (case+ gpos_mark_matrix_parse(b,s,glyphs,MarkToMark()) of | ~MarkMatrixRejected(e) => PositionPayloadRejected(e)
    | ~MarkMatrixAccepted(t) => PositionPayloadAccepted(PositionPayloadMark(t)))
  | PosContext() => PositionPayloadRejected(ot_error(OtUnsupported(),s))
  | PosChained() => PositionPayloadRejected(ot_error(OtUnsupported(),s))
  | PosExtension() => PositionPayloadRejected(ot_error(OtUnsupported(),s))
implement ot_position_payload_resolve(b,s,glyphs,a) = case+ a of
  | PosExtension() => (case+ ot_extension_parse(b,s,OtPositioning()) of | ~ExtensionRejected(e) => PositionPayloadRejected(e)
    | ~ExtensionAccepted(t) => ot_position_payload_parse(b,t.span,glyphs,t.action))
  | PosSingle() => ot_position_payload_parse(b,s,glyphs,a) | PosPair() => ot_position_payload_parse(b,s,glyphs,a)
  | PosCursive() => ot_position_payload_parse(b,s,glyphs,a) | PosMarkBase() => ot_position_payload_parse(b,s,glyphs,a)
  | PosMarkLigature() => ot_position_payload_parse(b,s,glyphs,a) | PosMarkMark() => ot_position_payload_parse(b,s,glyphs,a)
  | PosContext() => ot_position_payload_parse(b,s,glyphs,a) | PosChained() => ot_position_payload_parse(b,s,glyphs,a)
implement ot_position_payload_dispose(p) = case+ p of | ~PositionPayloadVacant() => ()
  | ~PositionPayloadSingle(t) => gpos_single_dispose(t) | ~PositionPayloadPair(t) => gpos_pair_dispose(t)
  | ~PositionPayloadCursive(t) => gpos_cursive_dispose(t) | ~PositionPayloadBase(t) => gpos_mark_matrix_dispose(t)
  | ~PositionPayloadLigature(t) => gpos_mark_ligature_dispose(t) | ~PositionPayloadMark(t) => gpos_mark_matrix_dispose(t)
extern fun position_payload_empty_failed(): int = "mac#anth_die_int"
implement ot_position_payload_action(p) = case+ p of
  | PositionPayloadVacant() => let val failed=position_payload_empty_failed() in PosSingle() end
  | PositionPayloadSingle(t) => PosSingle() | PositionPayloadPair(t) => PosPair() | PositionPayloadCursive(t) => PosCursive()
  | PositionPayloadBase(t) => PosMarkBase() | PositionPayloadLigature(t) => PosMarkLigature() | PositionPayloadMark(t) => PosMarkMark()
