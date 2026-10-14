#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/ot_position_lookup_types.sats"
staload "data_font/ot_position_lookup.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/glyph_metadata.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/glyph_position_types.sats"
staload "data_font/glyph_position_work.sats"
staload "data_font/glyph_position_filter.sats"
staload "data_font/glyph_position_pair_work.sats"
staload "data_font/glyph_position_mark_work.sats"
staload "data_font/glyph_position_lookup_work.sats"
fun requires_classes(a: OtLookupKind(2)): bool = case+ a of
  | PosMarkBase() => true | PosMarkLigature() => true | PosMarkMark() => true
  | PosSingle() => false | PosPair() => false | PosCursive() => false
  | PosContext() => false | PosChained() => false | PosExtension() => false
implement glyph_position_lookup_check(t,m,meta) = let
  val h=ot_position_lookup_info(t) and info=glyph_metadata_info(m)
  val status=glyph_position_filter_check(m,meta,ot_position_lookup_glyphs(t),h.flags,h.markSet)
in if not(glyph_position_ready(status)) then status
  else if requires_classes(ot_position_lookup_action(t)) andalso not(info.classes) then PositionReference()
  else if igt(meta.live,idiv(MAX_REC_FUEL,iadd(h.count,1))) then PositionCapacity() else PositionReady() end
