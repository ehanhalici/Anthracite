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
staload "data_font/opentype/position/gpos_mark_ligature.sats"
staload "data_font/opentype/position/gpos_mark_ligature_groups.sats"
staload "data_font/opentype/tables/opentype_coverage.sats"
fun missing(): GposMarkLigatureView =
  @{matched=false,mark=ot_anchor_missing(),target=ot_anchor_missing(),markClass=0,components=0}
fun slots {m,n,t:nat}(b: !Buf,info: GposMarkInfo,marks: !OtAnchorCache(m,m),groups: !GposLigatureGroups(n,n),
  targets: !OtAnchorCache(t,t),mark: int,target: int,component: int): GposMarkLigatureView = let
  val group=gpos_ligature_groups_get(groups,target)
in if ilt(component,0) orelse ige(component,group.components) then missing() else let
    val class=ot_u16(b,info.markArray,iadd(2,imul(mark,4)))
    val a=ot_anchor_cache_get(marks,mark)
    val c=ot_anchor_cache_get(targets,iadd(group.start,iadd(imul(component,info.classes),class)))
    val found=case+ c.kind of | AnchorMissing() => false | AnchorPresent() => true
  in @{matched=found,mark=a,target=c,markClass=class,components=group.components} end end
implement gpos_mark_ligature_query(b,table,mark,target,component) = let
  val+ GposMarkLigature(info,marks,groups,targets)=table
  val m=ot_coverage_index(b,info.marks,mark) and t=ot_coverage_index(b,info.targets,target)
in if not(m.found) orelse not(t.found) then missing()
  else slots(b,info,marks,groups,targets,m.index,t.index,component) end
implement gpos_mark_ligature_dispose(table) = let val+ ~GposMarkLigature(info,marks,groups,targets)=table
  val ()=ot_anchor_cache_dispose(marks) and ()=ot_anchor_cache_dispose(targets)
in gpos_ligature_groups_dispose(groups) end
implement gpos_mark_ligature_glyphs(table) = let val+ GposMarkLigature(info,marks,groups,targets)=table in info.glyphs end
implement gpos_mark_ligature_components(b,table,target) = let
  val+ GposMarkLigature(info,marks,groups,targets)=table
  val t=ot_coverage_index(b,info.targets,target)
in if not(t.found) then 0 else let val g=gpos_ligature_groups_get(groups,t.index) in g.components end end
