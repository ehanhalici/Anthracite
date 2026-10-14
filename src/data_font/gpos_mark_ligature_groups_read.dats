#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/gpos_value_types.sats"
staload "data_font/gpos_values.sats"
staload "data_font/gpos_anchor_cache_types.sats"
staload "data_font/gpos_anchor_cache.sats"
staload "data_font/gpos_mark_shared_types.sats"
staload "data_font/gpos_mark_shared.sats"
staload "data_font/gpos_mark_ligature_types.sats"
staload "data_font/gpos_mark_ligature_groups.sats"
fun append {n,i:nat | i < n} .<n-i,0>. (b: !Buf,info: GposMarkInfo,s: OtSpan,
  cache: GposLigatureGroups(n,i),total: int): GposLigatureGroupsRead = let
  val components=ot_u16(b,s,0)
  val stride=imul(info.classes,2)
in if not(ot_rows_fit(s,2,components,stride)) then let val ()=gpos_ligature_groups_dispose(cache)
    in LigatureGroupsRejected(ot_error(OtBounds(),s)) end else let
    val count=imul(components,info.classes) and floor=iadd(2,imul(components,stride))
    val next=iadd(total,count)
  in if not(ot_anchor_cache_capacity(next)) then let val ()=gpos_ligature_groups_dispose(cache)
      in LigatureGroupsRejected(ot_error(OtCapacity(),s)) end else let
      val group: GposLigatureGroup= @{span=s,components=components,start=total,floor=floor}
    in fill(b,info,gpos_ligature_groups_append(cache,group),next) end end end
and fill {n,i:nat | i <= n} .<n-i,1>. (b: !Buf,info: GposMarkInfo,
  cache: GposLigatureGroups(n,i),total: int): GposLigatureGroupsRead = let
  val count=gpos_ligature_groups_count(cache) and index=gpos_ligature_groups_filled(cache)
  val s=info.targetArray
in if index = count then LigatureGroupsAccepted(cache,total) else let
    val child=ot_optional_child(s,ot_u16(b,s,iadd(2,imul(index,2))),iadd(2,imul(count,2)))
  in case+ child.kind of
    | ChildMissing() => let val ()=gpos_ligature_groups_dispose(cache) in LigatureGroupsRejected(ot_error(OtBounds(),s)) end
    | ChildInvalid() => let val ()=gpos_ligature_groups_dispose(cache) in LigatureGroupsRejected(ot_error(OtBounds(),s)) end
    | ChildPresent() => if ilt(child.span.length,2) then let val ()=gpos_ligature_groups_dispose(cache)
        in LigatureGroupsRejected(ot_error(OtBounds(),child.span)) end
      else append(b,info,child.span,cache,total) end end
implement gpos_ligature_groups_read(b,info) =
  if not(ot_rows_fit(info.targetArray,2,info.targetCount,2)) then LigatureGroupsRejected(ot_error(OtBounds(),info.targetArray))
  else fill(b,info,gpos_ligature_groups_make(airlock_nat(info.targetCount)),0)
