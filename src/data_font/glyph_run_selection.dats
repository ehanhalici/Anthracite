#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_run_storage.sats"
staload "data_font/glyph_run.sats"
staload "data_font/glyph_run_work.sats"
extern fun glyph_selection_exhausted(): GlyphEditStatus = "mac#anth_die_box"
fun walk {n,r:nat} .<r>. (remaining: int(r),s: !GlyphStorage(n),nodes: !Buf,count: int,
  cursor: int,index: int,components: int): GlyphEditStatus =
  if ieq(index,count) then GlyphUpdated() else if ilt(cursor,0) then GlyphOrder()
  else if remaining = 0 then glyph_selection_exhausted() else let
    val target=buf_get32(nodes,index)
    val links=glyph_storage_links(s,cursor)
  in if ine(cursor,target) then walk(remaining-1,s,nodes,count,links.next,index,components) else let
    val core=glyph_storage_core(s,cursor)
    val weight=case+ core.association of | Unassociated() => 1 | LigatureMark() => 1
      | LigatureOwner() => core.components | LigatureForward() => 1
  in if igt(weight,isub(MAX_REC_FUEL,components)) then GlyphOverflow()
    else walk(remaining-1,s,nodes,count,links.next,iadd(index,1),iadd(components,weight)) end end
implement glyph_run_selection(s,meta,nodes,count) =
  if ilt(count,1) orelse igt(count,meta.live) orelse igt(count,idiv(buf_cap(nodes),4)) then GlyphNode()
  else if not(glyph_run_node(s,meta,buf_get32(nodes,0))) then GlyphNode()
  else walk(airlock_nat(iadd(meta.used,1)),s,nodes,count,buf_get32(nodes,0),0,0)
