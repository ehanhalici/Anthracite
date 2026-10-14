#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_run_storage.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/glyph_metadata.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/glyph_pass_work.sats"
staload "data_font/gsub_ligature_types.sats"
staload "data_font/glyph_pass_ligature_work.sats"
fun eligible{n:nat}(b: !Buf,m: !GlyphMetadata,s: !GlyphStorage(n),meta: GlyphRunMeta,f: OtLookupFlags,set: int,
  selection: GlyphSelection,first: int,node: int,remaining: &int >> _): GlyphLigatureAffinity = let val core=glyph_storage_core(s,node)
in if glyph_pass_selected(selection,core.mask) then glyph_ligature_affinity(b,m,s,meta,f,set,first,node,remaining) else LigatureIncompatible() end
extern fun input_invariant(): int = "mac#anth_die_int"
fun walk{n,k:nat} .<k>. (left: int(k),b: !Buf,m: !GlyphMetadata,s: !GlyphStorage(n),meta: GlyphRunMeta,f: OtLookupFlags,set: int,
  selection: GlyphSelection,first: int,node: int,maximum: int,glyphs: !Buf,nodes: !Buf,count: int,remaining: &int >> _): GlyphLigatureInput =
  if ieq(node,~1) orelse ige(count,maximum) then @{count=count,status=GlyphPassApplied()}
  else if left = 0 then let val failed=input_invariant() in @{count=failed,status=GlyphPassReference()} end
  else if remaining = 0 then @{count=count,status=GlyphPassCapacity()} else let
    val ()=remaining := isub(remaining,1)
    val core=glyph_storage_core(s,node) and links=glyph_storage_links(s,node)
  in if not(glyph_metadata_allows_core(b,m,f,set,core)) then
    walk(left-1,b,m,s,meta,f,set,selection,first,links.next,maximum,glyphs,nodes,count,remaining)
  else case+ eligible(b,m,s,meta,f,set,selection,first,node,remaining) of
    | LigatureIncompatible() => @{count=count,status=GlyphPassApplied()}
    | LigatureAffinityCapacity() => @{count=count,status=GlyphPassCapacity()}
    | LigatureCompatible() => let val ()=buf_set32(glyphs,count,core.glyph) and ()=buf_set32(nodes,count,node)
      in walk(left-1,b,m,s,meta,f,set,selection,first,links.next,maximum,glyphs,nodes,iadd(count,1),remaining) end end
implement glyph_ligature_input(b,m,s,meta,f,set,selection,node,maximum,glyphs,nodes,remaining) = let
  val core=glyph_storage_core(s,node) and links=glyph_storage_links(s,node)
  val ()=buf_set32(glyphs,0,core.glyph) and ()=buf_set32(nodes,0,node)
in walk(airlock_nat(meta.live),b,m,s,meta,f,set,selection,node,links.next,maximum,glyphs,nodes,1,remaining) end
