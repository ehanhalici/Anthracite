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
staload "data_font/opentype/position/gpos_mark_ligature_groups.sats"
staload "data_font/opentype/position/gpos_mark_ligature_work.sats"
fun complete {m,n,t,i:nat | i <= t}(info: GposMarkInfo,marks: OtAnchorCache(m,m),
  groups: GposLigatureGroups(n,n),cache: OtAnchorCache(t,i)): GposMarkLigatureRead =
  if ot_anchor_cache_filled(cache) = ot_anchor_cache_count(cache) then
    MarkLigatureAccepted(GposMarkLigature(info,marks,groups,cache))
  else let val ()=ot_anchor_cache_dispose(marks) and ()=ot_anchor_cache_dispose(cache)
    val ()=gpos_ligature_groups_dispose(groups)
  in MarkLigatureRejected(ot_error(OtReference(),info.targetArray)) end
fun fill {m,n,i:nat | i <= n}{t,j:nat | j <= t} .<n-i>. (index: int(i),b: !Buf,info: GposMarkInfo,
  marks: OtAnchorCache(m,m),groups: GposLigatureGroups(n,n),cache: OtAnchorCache(t,j)): GposMarkLigatureRead =
  if index = gpos_ligature_groups_count(groups) then complete(info,marks,groups,cache) else let
    val group=gpos_ligature_groups_get(groups,index)
  in case+ gpos_ligature_group_anchors(b,group,info.classes,cache) of
    | ~LigatureAnchorsRejected(e) => let val ()=ot_anchor_cache_dispose(marks)
      val ()=gpos_ligature_groups_dispose(groups) in MarkLigatureRejected(e) end
    | ~LigatureAnchorsPartial(next) => fill(index+1,b,info,marks,groups,next) end
implement gpos_ligature_anchors(b,info,marks,groups,count) = fill(0,b,info,marks,groups,ot_anchor_cache_make(count))
