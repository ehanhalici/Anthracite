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
staload "data_font/glyph_pass_types.sats"
staload "data_font/glyph_pass_work.sats"
staload "data_font/gsub_ligature_types.sats"
staload "data_font/glyph_pass_ligature_work.sats"
staload "data_font/ot_ligation_lookup_types.sats"
fun selected{n:nat}(b: !Buf,m: !GlyphMetadata,s: !GlyphStorage(n),node: int,f: OtLookupFlags,set: int,selection: GlyphSelection): bool = let
  val core=glyph_storage_core(s,node)
in glyph_pass_selected(selection,core.mask) andalso glyph_metadata_allows_core(b,m,f,set,core) end
fun step{n,j:nat}(b: !Buf,t: !OtLigationTables(j,j),m: !GlyphMetadata,s: !GlyphStorage(n),meta: &GlyphRunMeta >> _,
  f: OtLookupFlags,set: int,selection: GlyphSelection,node: int,glyphs: !Buf,nodes: !Buf,weights: !Buf,remaining: &int >> _): GlyphLigatureStep =
  if selected(b,m,s,node,f,set,selection) then glyph_ligature_step(b,t,m,s,meta,f,set,selection,node,glyphs,nodes,weights,remaining)
  else let val links=glyph_storage_links(s,node) in @{next=links.next,matched=false,status=GlyphPassApplied()} end
extern fun walk_invariant(): int = "mac#anth_die_int"
fun walk{n,j,k:nat} .<k>. (left: int(k),b: !Buf,t: !OtLigationTables(j,j),m: !GlyphMetadata,s: !GlyphStorage(n),meta: &GlyphRunMeta >> _,
  f: OtLookupFlags,set: int,selection: GlyphSelection,node: int,glyphs: !Buf,nodes: !Buf,weights: !Buf,
  remaining: &int >> _,visited: &int >> _,matches: &int >> _): GlyphPassStatus =
  if ieq(node,~1) then GlyphPassApplied() else if left = 0 then let val failed=walk_invariant() in GlyphPassReference() end
  else if not(glyph_run_node(s,meta,node)) then let val failed=walk_invariant() in GlyphPassReference() end
  else if ile(remaining,0) then GlyphPassCapacity() else let
    val ()=remaining := isub(remaining,1)
    val result=step(b,t,m,s,meta,f,set,selection,node,glyphs,nodes,weights,remaining)
    val ()=visited := iadd(visited,1) and ()=matches := iadd(matches,if result.matched then 1 else 0)
  in case+ result.status of | GlyphPassApplied() => walk(left-1,b,t,m,s,meta,f,set,selection,result.next,glyphs,nodes,weights,remaining,visited,matches)
    | GlyphPassDomain() => result.status | GlyphPassReference() => result.status | GlyphPassCapacity() => result.status end
implement glyph_ligature_walk(b,t,m,s,meta,f,set,selection,glyphs,nodes,weights,visited,matches) = let var remaining: int=MAX_REC_FUEL
in walk(airlock_nat(meta.live),b,t,m,s,meta,f,set,selection,meta.head,glyphs,nodes,weights,remaining,visited,matches) end
