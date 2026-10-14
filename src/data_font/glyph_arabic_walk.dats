#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/unicode_property.sats"
staload "data_text/arabic_join_types.sats"
staload "data_text/arabic_join.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_run_storage.sats"
staload "data_font/glyph_run_work.sats"
staload "data_font/glyph_arabic_work.sats"
extern fun arabic_invariant(): void = "mac#anth_die_void"
fun previous(advance: ArabicAdvance,old: int,node: int): int = case+ advance of
  | RetainPrevious() => old | ReplacePrevious() => node
fun walk{n,k:nat} .<k>. (left: int(k),map: !PropertyMap(3),plan: !ArabicMaskPlan,s: !GlyphStorage(n),
  meta: GlyphRunMeta,context: ArabicContext,node: int,prior: int,state: ArabicJoinState): void =
  if left = 0 then (if ine(node,~1) then arabic_invariant() else
    glyph_arabic_promote(s,prior,arabic_join_end(state,context.after),plan))
  else if not(glyph_run_node(s,meta,node)) then arabic_invariant() else let
    val core=glyph_storage_core(s,node) and links=glyph_storage_links(s,node)
    val step=arabic_join_step(state,arabic_joining(map,core.scalar))
    val ()=glyph_arabic_form(s,node,step.current,plan)
    val ()=glyph_arabic_promote(s,prior,step.previous,plan)
  in walk(left-1,map,plan,s,meta,context,links.next,previous(step.advance,prior,node),step.state) end
implement glyph_arabic_walk(map,plan,context,s,meta) =
  walk(airlock_nat(meta.live),map,plan,s,meta,context,meta.head,~1,arabic_join_start(context.before))
