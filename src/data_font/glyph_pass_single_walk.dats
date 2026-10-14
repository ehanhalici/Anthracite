#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_run_storage.sats"
staload "data_font/glyph_run_work.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/gsub_single_types.sats"
staload "data_font/gsub_single.sats"
staload "data_font/glyph_pass_work.sats"
extern fun pass_invariant(): int = "mac#anth_die_int"
fun replace{n:nat}(b: !Buf,t: !GsubSingle,s: !GlyphStorage(n),node: int,core: GlyphCore): int = let
  val result=gsub_single_query(b,t,core.glyph)
in if not(result.matched) then 0 else let
  val ()=glyph_storage_set_core(s,node,glyph_run_new_glyph(core,result.glyph))
in 1 end end
fun walk{n,k:nat} .<k>. (left: int(k),b: !Buf,t: !GsubSingle,s: !GlyphStorage(n),
  meta: GlyphRunMeta,selection: GlyphSelection,node: int,matches: int): int =
  if left = 0 then (if ieq(node,~1) then matches else pass_invariant())
  else if not(glyph_run_node(s,meta,node)) then pass_invariant() else let
    val core=glyph_storage_core(s,node)
    val links=glyph_storage_links(s,node)
    val matched=if glyph_pass_selected(selection,core.mask) then replace(b,t,s,node,core) else 0
  in walk(left-1,b,t,s,meta,selection,links.next,iadd(matches,matched)) end
implement glyph_pass_single_walk(b,t,s,meta,selection) =
  walk(airlock_nat(meta.live),b,t,s,meta,selection,meta.head,0)
