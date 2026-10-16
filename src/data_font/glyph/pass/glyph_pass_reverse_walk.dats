#include "data_font/glyph/pass/glyph_pass_reverse_internal.hats"
extern fun reverse_invariant_die(): int = "mac#anth_die_int"
fun reverse_invariant(): GlyphReverseCount = let val failed=reverse_invariant_die()
in @{status=GlyphPassReference(),visited=failed,matches=0} end
fun apply{n:nat}(s: !GlyphStorage(n),node: int,r: GlyphReverseMatch): int =
  if not(r.matched) then 0 else let
    val core=glyph_storage_core(s,node)
    val ()=glyph_storage_set_core(s,node,glyph_run_new_glyph(core,r.glyph))
  in 1 end
fun walk{n,f:nat} .<f>. (left: int(f),b: !Buf,t: !OtReverseLookup,m: !GlyphMetadata,
  s: !GlyphStorage(n),meta: GlyphRunMeta,selection: GlyphSelection,w: !GlyphContextWindow,
  remaining: &int >> int,node: int,visited: int,matches: int): GlyphReverseCount =
  if left = 0 then (if ieq(node,~1) then @{status=GlyphPassApplied(),visited=visited,matches=matches}
    else reverse_invariant()) else if not(glyph_run_node(s,meta,node)) then reverse_invariant() else let
    val links=glyph_storage_links(s,node)
    val r=glyph_reverse_query(b,t,m,s,meta,selection,node,w,remaining)
  in case+ r.status of | GlyphPassDomain() => @{status=r.status,visited=visited,matches=matches}
    | GlyphPassReference() => @{status=r.status,visited=visited,matches=matches}
    | GlyphPassCapacity() => @{status=r.status,visited=visited,matches=matches}
    | GlyphPassApplied() => let val changed=apply(s,node,r)
      in walk(left-1,b,t,m,s,meta,selection,w,remaining,links.previous,iadd(visited,1),iadd(matches,changed)) end end
implement glyph_reverse_walk(b,t,m,s,meta,selection,w,remaining) =
  walk(airlock_nat(meta.live),b,t,m,s,meta,selection,w,remaining,meta.tail,0,0)
