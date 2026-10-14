#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_run_storage.sats"
staload "data_font/glyph_run_work.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/glyph_metadata.sats"
staload "data_font/glyph_neighbor_types.sats"
staload "data_font/glyph_neighbor_work.sats"
extern fun neighbor_failed(): int = "mac#anth_die_int"
fun neighbor_invariant(): GlyphNeighbor = let val failed=neighbor_failed() in
  @{status=NeighborNode(),node=failed,core=glyph_core_empty()} end
fun adjacent{n:nat}(s: !GlyphStorage(n),node: int,travel: GlyphTravel): int = let
  val links=glyph_storage_links(s,node)
in case+ travel of | GlyphForward() => links.next | GlyphBackward() => links.previous end
fun search{n,k:nat} .<k>. (left: int(k),b: !Buf,m: !GlyphMetadata,s: !GlyphStorage(n),meta: GlyphRunMeta,
  f: OtLookupFlags,set: int,node: int,travel: GlyphTravel): GlyphNeighbor =
  if ieq(node,~1) then glyph_neighbor_empty(NeighborEnd())
  else if left = 0 then neighbor_invariant()
  else if not(glyph_run_node(s,meta,node)) then neighbor_invariant() else let
    val core=glyph_storage_core(s,node)
  in if glyph_metadata_allows_core(b,m,f,set,core) then @{status=NeighborFound(),node=node,core=core}
    else search(left-1,b,m,s,meta,f,set,adjacent(s,node,travel),travel) end
implement glyph_neighbor_search(b,m,s,meta,f,set,node,travel) =
  if not(glyph_run_node(s,meta,node)) then glyph_neighbor_empty(NeighborNode())
  else search(airlock_nat(meta.live),b,m,s,meta,f,set,adjacent(s,node,travel),travel)
