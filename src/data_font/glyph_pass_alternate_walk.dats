#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_run_storage.sats"
staload "data_font/glyph_run_work.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/ot_sequence_lookup_types.sats"
staload "data_font/ot_sequence_lookup.sats"
staload "data_font/glyph_pass_sequence_work.sats"
extern fun alternate_invariant(): int = "mac#anth_die_int"
fun replace{n:nat}(b: !Buf,t: !OtSequenceLookup(3),s: !GlyphStorage(n),node: int,core: GlyphCore,choice: int): int = let
  val result=ot_alternate_lookup_query(b,t,core.glyph,choice)
in if not(result.matched) then 0 else let
  val ()=glyph_storage_set_core(s,node,glyph_run_new_glyph(core,result.glyph))
in 1 end end
fun walk{n,k:nat} .<k>. (left: int(k),b: !Buf,t: !OtSequenceLookup(3),m: !GlyphMetadata,s: !GlyphStorage(n),
  meta: GlyphRunMeta,h: OtLookupInfo(1),selection: GlyphSelection,choice: int,node: int,matches: int): int =
  if left = 0 then (if ieq(node,~1) then matches else alternate_invariant())
  else if not(glyph_run_node(s,meta,node)) then alternate_invariant() else let
    val core=glyph_storage_core(s,node) and links=glyph_storage_links(s,node)
    val matched=if glyph_pass_sequence_eligible(b,m,h,selection,core) then replace(b,t,s,node,core,choice) else 0
  in walk(left-1,b,t,m,s,meta,h,selection,choice,links.next,iadd(matches,matched)) end
implement glyph_pass_alternate_walk(b,t,m,s,meta,selection,choice) =
  if ile(choice,0) then 0 else walk(airlock_nat(meta.live),b,t,m,s,meta,ot_sequence_lookup_header(t),selection,choice,meta.head,0)
