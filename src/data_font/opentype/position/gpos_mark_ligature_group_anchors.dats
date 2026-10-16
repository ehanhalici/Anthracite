#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_reader.sats"
staload "data_font/opentype/position/gpos_value_types.sats"
staload "data_font/opentype/position/gpos_values.sats"
staload "data_font/opentype/position/gpos_anchor_cache_types.sats"
staload "data_font/opentype/position/gpos_anchor_cache.sats"
staload "data_font/opentype/position/gpos_mark_shared_types.sats"
staload "data_font/opentype/position/gpos_mark_shared.sats"
staload "data_font/opentype/position/gpos_mark_ligature_types.sats"
staload "data_font/opentype/position/gpos_mark_ligature_work.sats"
fun fill {n,i:nat | i <= n}{r:nat} .<r>. (remaining: int(r),b: !Buf,group: GposLigatureGroup,
  cache: OtAnchorCache(n,i)): GposLigatureAnchorPartial(n) = let
  val filled=ot_anchor_cache_filled(cache) and capacity=ot_anchor_cache_count(cache)
  val field=iadd(2,imul(isub(filled,group.start),2))
in if remaining = 0 then LigatureAnchorsPartial(cache)
  else if filled = capacity then let val ()=ot_anchor_cache_dispose(cache)
    in LigatureAnchorsRejected(ot_error(OtReference(),group.span)) end else
    case+ ot_anchor_slot_parse(b,group.span,ot_u16(b,group.span,field),group.floor,AnchorOptional()) of
    | ~AnchorSlotRejected(e) => let val ()=ot_anchor_cache_dispose(cache) in LigatureAnchorsRejected(e) end
    | ~AnchorSlotAccepted(v) => fill(remaining-1,b,group,ot_anchor_cache_append(cache,v)) end
implement gpos_ligature_group_anchors(b,group,classes,cache) =
  fill(airlock_nat(imul(group.components,classes)),b,group,cache)
