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
staload "data_font/glyph/core/glyph_metadata.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/opentype/substitution/gsub_ligature_types.sats"
staload "data_font/glyph/pass/glyph_pass_ligature_work.sats"
fun owner_id(core: GlyphCore,node: int): int = case+ core.association of
  | LigatureOwner() => node | Unassociated() => ~1 | LigatureMark() => ~1 | LigatureForward() => ~1
extern fun affinity_invariant(): int = "mac#anth_die_int"
fun skipped{n,k:nat} .<k>. (left: int(k),b: !Buf,m: !GlyphMetadata,s: !GlyphStorage(n),meta: GlyphRunMeta,
  f: OtLookupFlags,set: int,node: int,owner: int,remaining: &int >> _): GlyphLigatureAffinity =
  if ilt(node,0) then LigatureIncompatible() else if ile(remaining,0) then LigatureAffinityCapacity()
  else if left = 0 then let val failed=affinity_invariant() in LigatureIncompatible() end else let
    val ()=remaining := isub(remaining,1)
    val core=glyph_storage_core(s,node) and links=glyph_storage_links(s,node)
  in if ieq(node,owner) then (if glyph_metadata_allows_core(b,m,f,set,core) then LigatureIncompatible() else LigatureCompatible())
    else let val a=glyph_run_association(s,meta,node) in
      if a.found andalso ieq(a.owner,owner) then skipped(left-1,b,m,s,meta,f,set,links.previous,owner,remaining)
      else LigatureIncompatible() end end
implement glyph_ligature_affinity(b,m,s,meta,f,set,first,candidate,remaining) = let
  val a=glyph_run_association(s,meta,first) and c=glyph_run_association(s,meta,candidate)
in if a.found then (if c.found andalso ieq(a.owner,c.owner) andalso ieq(a.component,c.component) then LigatureCompatible()
  else let val links=glyph_storage_links(s,first)
  in skipped(airlock_nat(meta.live),b,m,s,meta,f,set,links.previous,a.owner,remaining) end)
  else if not(c.found) orelse ieq(c.owner,owner_id(glyph_storage_core(s,first),first)) then LigatureCompatible() else LigatureIncompatible() end
