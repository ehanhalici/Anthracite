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
fun bindable(core: GlyphCore): bool = case+ core.association of
  | Unassociated() => true | LigatureMark() => true | LigatureOwner() => false | LigatureForward() => false
fun bind {n:nat}(s: !GlyphStorage(n),node: int,owner: int,component: int): bool = let
  val core=glyph_storage_core(s,node) and target=glyph_storage_core(s,owner)
in if not(bindable(core)) then false else case+ target.association of
  | Unassociated() => false | LigatureMark() => false | LigatureForward() => false
  | LigatureOwner() => if ilt(component,0) orelse ige(component,target.components) then false else let
    val updated: GlyphCore= @{glyph=core.glyph,scalar=core.scalar,sourceStart=core.sourceStart,sourceEnd=core.sourceEnd,
      cluster=core.cluster,mask=core.mask,association=LigatureMark(),ligature=owner,component=component,components=1,multiplied=core.multiplied,unicodeKind=core.unicodeKind,ignorable=core.ignorable}
    val ()=glyph_storage_set_core(s,node,updated)
  in true end end
implement glyph_run_bind_mark(run,node,owner,component) = let val+ ~GlyphRun(phase,meta,s)=run in
  if ieq(node,owner) orelse not(glyph_run_node(s,meta,node)) orelse not(glyph_run_node(s,meta,owner))
    then GlyphRunEdited(GlyphRun(phase,meta,s),GlyphNode(),~1)
  else if bind(s,node,owner,component) then GlyphRunEdited(GlyphRun(phase,meta,s),GlyphUpdated(),node)
    else GlyphRunEdited(GlyphRun(phase,meta,s),GlyphAssociationError(),~1) end
