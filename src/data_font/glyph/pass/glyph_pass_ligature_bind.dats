#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/run/glyph_run_storage.sats"
staload "data_font/glyph/run/glyph_run_work.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/opentype/substitution/gsub_ligature_types.sats"
staload "data_font/glyph/pass/glyph_pass_ligature_work.sats"
extern fun bind_invariant(): void = "mac#anth_die_void"
fun bound{n:nat}(s: !GlyphStorage(n),meta: GlyphRunMeta,node: int,owner: int,offset: int,weight: int): void = let
  val core=glyph_storage_core(s,node)
  val a=glyph_run_association(s,meta,node)
  val component=if a.found then imin(iadd(a.component,1),weight) else weight
  val updated: GlyphCore= @{glyph=core.glyph,scalar=core.scalar,sourceStart=core.sourceStart,sourceEnd=core.sourceEnd,
    cluster=core.cluster,mask=core.mask,association=LigatureMark(),ligature=owner,
    component=isub(iadd(offset,component),1),components=1,multiplied=core.multiplied,unicodeKind=core.unicodeKind,ignorable=core.ignorable}
in glyph_storage_set_core(s,node,updated) end
fun walk{n,k:nat} .<k>. (left: int(k),s: !GlyphStorage(n),meta: GlyphRunMeta,nodes: !Buf,weights: !Buf,count: int,
  owner: int,node: int,index: int,offset: int,weight: int): void =
  if ieq(index,count) then () else if left = 0 then bind_invariant() else let
    val links=glyph_storage_links(s,node)
  in if ieq(node,buf_get32(nodes,index)) then walk(left-1,s,meta,nodes,weights,count,owner,links.next,
      iadd(index,1),iadd(offset,weight),buf_get32(weights,index))
    else let val ()=bound(s,meta,node,owner,offset,weight)
      in walk(left-1,s,meta,nodes,weights,count,owner,links.next,index,offset,weight) end end
implement glyph_ligature_bind(s,meta,nodes,weights,count) = let
  val owner=buf_get32(nodes,0) and weight=buf_get32(weights,0)
  val links=glyph_storage_links(s,owner)
in walk(airlock_nat(meta.live),s,meta,nodes,weights,count,owner,links.next,1,0,weight) end
