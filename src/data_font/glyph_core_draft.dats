#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_run_storage.sats"
staload "data_font/glyph_core_draft_types.sats"
staload "data_font/glyph_core_draft.sats"
fun copy{n,m,f:nat} .<f>. (left: int(f),source: !arrayptr(GlyphCore,n),target: !arrayptr(GlyphCore,m),
  count: int(n),size: int(m),index: int): void =
  if left = 0 then () else let
    val value=arrayptr_get_at<GlyphCore>(source,i2sz(airlock_below(index,count)))
    val ()=arrayptr_set_at<GlyphCore>(target,i2sz(airlock_below(index,size)),value)
  in copy(left-1,source,target,count,size,iadd(index,1)) end
implement glyph_core_draft_make(source,used) = let
  val+ ~GlyphStorage(n,core,links,positions)=source
  val scratch=arrayptr_make_elt<GlyphCore>(i2sz(n),glyph_core_empty())
  val ()=copy(airlock_nat(used),core,scratch,n,n,0)
in GlyphCoreDraft(core,GlyphStorage(n,scratch,links,positions)) end
implement glyph_core_draft_commit(draft) = let val+ ~GlyphCoreDraft(old,scratch)=draft
  val ()=arrayptr_free(old)
in scratch end
implement glyph_core_draft_rollback(draft) = let val+ ~GlyphCoreDraft(old,scratch)=draft
  val+ ~GlyphStorage(n,core,links,positions)=scratch val ()=arrayptr_free(core)
in GlyphStorage(n,old,links,positions) end
