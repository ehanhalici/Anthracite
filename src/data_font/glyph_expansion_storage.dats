#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/glyph_expansion_types.sats"
staload "data_font/glyph_expansion_work.sats"
fun empty(): GlyphExpansion = @{node= ~1,view= @{matched=false,span= @{offset=0,length=0},count=0}}
implement glyph_expansion_make(count) = let
  val rows=arrayptr_make_elt<GlyphExpansion>(g1int2uint_int_size(count),empty())
in GlyphExpansionPlan(rows,count,0,0,0) end
implement glyph_expansion_append(plan,entry) = let val+ ~GlyphExpansionPlan(rows,count,filled,added,matches)=plan
  val ()=arrayptr_set_at<GlyphExpansion>(rows,g1int2uint_int_size(filled),entry)
  val extra=if entry.view.matched then isub(entry.view.count,1) else 0
in GlyphExpansionPlan(rows,count,filled+1,iadd(added,extra),iadd(matches,if entry.view.matched then 1 else 0)) end
implement glyph_expansion_get(plan,index) = let val+ GlyphExpansionPlan(rows,count,filled,added,matches)=plan in
  arrayptr_get_at<GlyphExpansion>(rows,g1int2uint_int_size(airlock_below(index,count))) end
implement glyph_expansion_dispose(plan) = let val+ ~GlyphExpansionPlan(rows,count,filled,added,matches)=plan in arrayptr_free(rows) end
