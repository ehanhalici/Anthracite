#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/opentype/definition/gdef_types.sats"
staload "data_font/glyph/run/glyph_run_storage.sats"
staload "data_font/glyph/run/glyph_run.sats"
staload "data_font/glyph/run/glyph_run_work.sats"
typedef MergeSummary = @{start=int,limit=int,cluster=int,components=int,tail=int,ignorable=bool}
fun component_weight(core: GlyphCore): int = case+ core.association of
  | Unassociated() => 1 | LigatureMark() => 1 | LigatureOwner() => core.components | LigatureForward() => 1
fun forward(core: GlyphCore,owner: int,component: int): GlyphCore = @{glyph=core.glyph,scalar=core.scalar,
  sourceStart=core.sourceStart,sourceEnd=core.sourceEnd,cluster=core.cluster,mask=core.mask,
  association=LigatureForward(),ligature=owner,component=component,components=core.components,multiplied=core.multiplied,unicodeKind=core.unicodeKind,ignorable=core.ignorable}
fun remove {n:nat}(s: !GlyphStorage(n),node: int,owner: int,component: int): void = let
  val links=glyph_storage_links(s,node) and core=glyph_storage_core(s,node)
  val ()=glyph_run_next(s,links.previous,links.next) and ()=glyph_run_previous(s,links.next,links.previous)
  val ()=glyph_storage_set_links(s,node,@{life=GlyphRemoved(),previous=links.previous,next=links.next})
in glyph_storage_set_core(s,node,forward(core,owner,component)) end
fun merge {n,r:nat} .<r>. (remaining: int(r),s: !GlyphStorage(n),nodes: !Buf,index: int,
  weights: !Buf,owner: int,summary: MergeSummary): MergeSummary =
  if remaining = 0 then summary else let
    val node=buf_get32(nodes,index) val core=glyph_storage_core(s,node)
    val links=glyph_storage_links(s,node)
    val tail=if ieq(summary.tail,node) then links.previous else summary.tail
    val ()=remove(s,node,owner,summary.components)
  in merge(remaining-1,s,nodes,iadd(index,1),weights,owner,@{start=imin(summary.start,core.sourceStart),
    limit=imax(summary.limit,core.sourceEnd),cluster=imin(summary.cluster,core.cluster),
    components=iadd(summary.components,buf_get32(weights,index)),tail=tail,ignorable=summary.ignorable andalso core.ignorable}) end
fun owner_core(old: GlyphCore,glyph: int,owner: int,summary: MergeSummary,kind: GlyphMergeKind): GlyphCore = let
  val core: GlyphCore= @{glyph=glyph,scalar=old.scalar,sourceStart=summary.start,sourceEnd=summary.limit,cluster=summary.cluster,
    mask=old.mask,association=old.association,ligature=old.ligature,component=old.component,components=old.components,multiplied=old.multiplied,unicodeKind=old.unicodeKind,ignorable=summary.ignorable}
in case+ kind of | MergeAssociation() => core | MergeLigature() =>
  @{glyph=glyph,scalar=old.scalar,sourceStart=summary.start,sourceEnd=summary.limit,cluster=summary.cluster,
    mask=old.mask,association=LigatureOwner(),ligature=owner,component=0,components=summary.components,multiplied=old.multiplied,
    unicodeKind=GlyphLigature(),ignorable=false} end
implement glyph_run_merge_counted(s,meta,nodes,weights,count,glyph,kind) = let
  val owner=buf_get32(nodes,0) val old=glyph_storage_core(s,owner)
  val summary=merge(airlock_nat(isub(count,1)),s,nodes,1,weights,owner,@{start=old.sourceStart,limit=old.sourceEnd,
    cluster=old.cluster,components=buf_get32(weights,0),tail=meta.tail,ignorable=old.ignorable})
  val core=owner_core(old,glyph,owner,summary,kind)
  val ()=glyph_storage_set_core(s,owner,core)
  val added: int=case+ kind of | MergeAssociation() => 0 | MergeLigature() => 1
in @{used=meta.used,live=isub(meta.live,isub(count,1)),head=meta.head,tail=summary.tail,font=meta.font,
  glyphs=meta.glyphs,sourceLength=meta.sourceLength,nextLigature=iadd(meta.nextLigature,added),properties=meta.properties} end
fun weights{n,k:nat} .<k>. (left: int(k),s: !GlyphStorage(n),nodes: !Buf,values: !Buf,i: int): void =
  if left = 0 then () else let val core=glyph_storage_core(s,buf_get32(nodes,i))
    val ()=buf_set32(values,i,component_weight(core))
  in weights(left-1,s,nodes,values,iadd(i,1)) end
implement glyph_run_merge(s,meta,nodes,count,glyph) = let
  val values=buf_make(imul(count,4))
  val ()=weights(airlock_nat(count),s,nodes,values,0)
  val updated=glyph_run_merge_counted(s,meta,nodes,values,count,glyph,MergeLigature())
  val ()=buf_free(values)
in updated end
