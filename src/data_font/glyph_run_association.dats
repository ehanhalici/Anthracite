#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_run_storage.sats"
staload "data_font/glyph_run.sats"
staload "data_font/glyph_run_work.sats"
fun missing(): GlyphAssociationView = @{found=false,owner= ~1,component=0,components=0}
extern fun glyph_association_exhausted(): int = "mac#anth_die_int"
fun owner {n,r:nat} .<r>. (remaining: int(r),s: !GlyphStorage(n),meta: GlyphRunMeta,
  node: int,component: int): GlyphAssociationView =
  if remaining = 0 then let val failed=glyph_association_exhausted()
    in @{found=false,owner=failed,component=0,components=0} end
  else if ilt(node,0) orelse ige(node,meta.used) then missing() else let
    val core=glyph_storage_core(s,node)
  in case+ core.association of | Unassociated() => missing() | LigatureMark() => missing()
    | LigatureForward() => if igt(core.component,isub(MAX_REC_FUEL,component)) then missing()
      else owner(remaining-1,s,meta,core.ligature,iadd(component,core.component))
    | LigatureOwner() => if not(glyph_run_node(s,meta,node)) orelse ige(component,core.components) then missing()
      else @{found=true,owner=node,component=component,components=core.components} end
implement glyph_run_association(s,meta,node) =
  if not(glyph_run_node(s,meta,node)) then missing() else let val core=glyph_storage_core(s,node) in
    case+ core.association of | Unassociated() => missing() | LigatureOwner() => missing()
    | LigatureForward() => missing() | LigatureMark() =>
      owner(airlock_nat(iadd(meta.used,1)),s,meta,core.ligature,core.component) end
implement glyph_run_mark_association(run,node) = let val+ GlyphRun(phase,meta,s)=run in glyph_run_association(s,meta,node) end
