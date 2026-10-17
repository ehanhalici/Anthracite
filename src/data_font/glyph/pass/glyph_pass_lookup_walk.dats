#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/run/glyph_run_storage.sats"
staload "data_font/glyph/run/glyph_run_work.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/glyph/pass/glyph_pass_work.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/core/glyph_metadata.sats"
staload "data_font/opentype/single_lookup/ot_single_lookup_types.sats"
staload "data_font/opentype/single_lookup/ot_single_lookup.sats"
staload "data_font/glyph/pass/glyph_pass_lookup_work.sats"
extern fun lookup_invariant(): int = "mac#anth_die_int"
fun replace{n:nat}(b: !Buf,t: !OtSingleLookup,s: !GlyphStorage(n),node: int,core: GlyphCore): int = let
  val result=ot_single_lookup_query(b,t,core.glyph)
in if not(result.matched) then 0 else let
  val ()=glyph_storage_set_core(s,node,glyph_run_new_glyph(core,result.glyph))
in 1 end end
fun eligible(b: !Buf,m: !GlyphMetadata,h: OtSingleHeader,selection: GlyphSelection,core: GlyphCore): bool =
  glyph_pass_selected(selection,core.mask) andalso glyph_metadata_allows_core(b,m,h.flags,h.markSet,core)
fun walk{n,k:nat} .<k>. (left: int(k),b: !Buf,t: !OtSingleLookup,m: !GlyphMetadata,s: !GlyphStorage(n),
  meta: GlyphRunMeta,h: OtSingleHeader,selection: GlyphSelection,node: int,matches: int): int =
  if left = 0 then (if ieq(node,~1) then matches else lookup_invariant())
  else if not(glyph_run_node(s,meta,node)) then lookup_invariant() else let
    val core=glyph_storage_core(s,node) and links=glyph_storage_links(s,node)
    val matched=if eligible(b,m,h,selection,core) then replace(b,t,s,node,core) else 0
  in walk(left-1,b,t,m,s,meta,h,selection,links.next,iadd(matches,matched)) end
implement glyph_pass_lookup_walk(b,t,m,s,meta,selection) =
  walk(airlock_nat(meta.live),b,t,m,s,meta,ot_single_lookup_header(t),selection,meta.head,0)
