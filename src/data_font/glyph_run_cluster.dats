#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_run_storage.sats"
staload "data_font/glyph_run_work.sats"
extern fun cluster_exhausted(): int = "mac#anth_die_int"
extern fun cluster_failed(): void = "mac#anth_die_void"
fun minimum{n,k:nat} .<k>. (left: int(k),s: !GlyphStorage(n),node: int,last: int,value: int): int =
  if left = 0 then cluster_exhausted() else let
    val core=glyph_storage_core(s,node) and links=glyph_storage_links(s,node)
    val next=imin(value,core.cluster)
  in if ieq(node,last) then next else minimum(left-1,s,links.next,last,next) end
fun assign{n,k:nat} .<k>. (left: int(k),s: !GlyphStorage(n),node: int,last: int,value: int): void =
  if left = 0 then cluster_failed() else let
    val core=glyph_storage_core(s,node) and links=glyph_storage_links(s,node)
    val ()=glyph_storage_set_core(s,node,glyph_run_new_cluster(core,value))
  in if ieq(node,last) then () else assign(left-1,s,links.next,last,value) end
implement glyph_run_cluster_merge(s,meta,nodes,count) = let
  val first=buf_get32(nodes,0) and last=buf_get32(nodes,isub(count,1))
  val core=glyph_storage_core(s,first)
  val value=minimum(airlock_nat(meta.live),s,first,last,core.cluster)
in assign(airlock_nat(meta.live),s,first,last,value) end
