#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/position/gpos_value_types.sats"
staload "data_font/opentype/position/gpos_value_cache_types.sats"
staload "data_font/opentype/position/gpos_value_cache.sats"
staload "data_font/opentype/position/gpos_anchor_cache_types.sats"
staload "data_font/opentype/position/gpos_anchor_cache.sats"
staload "data_font/opentype/position/gpos_single_types.sats"
staload "data_font/opentype/position/gpos_pair_types.sats"
staload "data_font/opentype/position/gpos_cursive_types.sats"
staload "data_font/opentype/position/gpos_mark_matrix_types.sats"
staload "data_font/opentype/position/gpos_mark_ligature_types.sats"
staload "data_font/opentype/position_lookup/ot_position_lookup_types.sats"
staload "data_font/opentype/position_lookup/ot_position_lookup_work.sats"
fun values{n:nat}(c: !OtValueCache(n,n)): llint =
  g0int2int_int_llint(ot_value_cache_count(c))*g0int2int_int_llint(g0uint2int_size_int(sizeof<OtValueInfo>))
fun anchors{n:nat}(c: !OtAnchorCache(n,n)): llint =
  g0int2int_int_llint(ot_anchor_cache_count(c))*g0int2int_int_llint(g0uint2int_size_int(sizeof<OtAnchorSlot>))
fun pairs(t: !GposPairs): llint = case+ t of
  | PairGlyphs(info,sets,c) => let val+ GposPairSets(rows,n,i)=sets in values(c)+g0int2int_int_llint(n)*g0int2int_int_llint(g0uint2int_size_int(sizeof<GposPairSet>)) end
  | PairClasses(info,c) => values(c) | PairNoOpClasses(info) => 0LL
fun matrix{kind:int}(t: !GposMarkMatrix(kind)): llint = let val+ GposMarkMatrix(d,info,a,c)=t in anchors(a)+anchors(c) end
implement ot_position_payload_bytes(p) = case+ p of | PositionPayloadVacant() => 0LL
  | PositionPayloadSingle(t) => let val+ GposSingle(info,c)=t in values(c) end
  | PositionPayloadPair(t) => pairs(t)
  | PositionPayloadCursive(t) => let val+ GposCursive(cov,glyphs,c)=t in anchors(c) end
  | PositionPayloadBase(t) => matrix(t) | PositionPayloadMark(t) => matrix(t)
  | PositionPayloadLigature(t) => let val+ GposMarkLigature(info,a,groups,c)=t
    val+ GposLigatureGroups(rows,n,i)=groups
  in anchors(a)+anchors(c)+g0int2int_int_llint(n)*g0int2int_int_llint(g0uint2int_size_int(sizeof<GposLigatureGroup>)) end
implement ot_position_payload_charge(p,remaining) = let val cost=ot_position_payload_bytes(p)+1024LL
in if cost > g0int2int_int_llint(remaining) then false else let
  val ()=remaining := remaining-airlock_i32(cost)
in true end end
