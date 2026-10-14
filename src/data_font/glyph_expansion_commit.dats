#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_expansion_types.sats"
staload "data_font/glyph_expansion_work.sats"
fun commit{n,p,k:nat} .<k>. (left: int(k),b: !Buf,plan: !GlyphExpansionPlan(p,p),
  s: !GlyphStorage(n),meta: GlyphRunMeta,index: int): GlyphRunMeta =
  if left = 0 then meta else let val entry=glyph_expansion_get(plan,index)
    val next=if entry.view.matched then glyph_expansion_replace(s,meta,entry.node,b,entry.view) else meta
  in commit(left-1,b,plan,s,next,iadd(index,1)) end
implement glyph_expansion_commit(b,plan,s,meta) = let val+ GlyphExpansionPlan(rows,count,filled,added,matches)=plan in
  commit(count,b,plan,s,meta,0) end
