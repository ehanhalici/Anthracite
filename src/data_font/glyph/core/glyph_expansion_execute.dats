#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/run/glyph_run.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/glyph/core/glyph_expansion_types.sats"
staload "data_font/glyph/core/glyph_expansion_work.sats"
fun accepted(status: GlyphEditStatus): bool = case+ status of
  | GlyphUpdated() => true | GlyphUnchanged() => true | GlyphCapacity() => false | GlyphNode() => false
  | GlyphDomain() => false | GlyphSource() => false | GlyphOrder() => false
  | GlyphAssociationError() => false | GlyphOverflow() => false
fun execute{n:nat}(b: !Buf,plan: GlyphExpansionPlan(n,n),run: GlyphRun(1)): GlyphPassResult(1) = let
  val+ GlyphExpansionPlan(rows,count,filled,added,matches)=plan
  val+ ~GlyphRun(phase,meta,s)=run
  val next=glyph_expansion_commit(b,plan,s,meta)
  val ()=glyph_expansion_dispose(plan)
in GlyphPassResult(GlyphRun(phase,next,s),GlyphPassApplied(),count,matches) end
implement glyph_expansion_execute(b,plan,run) = let
  val+ GlyphExpansionPlan(rows,count,filled,added,matches)=plan
  val meta=glyph_run_meta(run)
  val+ ~GlyphRunEdited(reserved,status,node)=glyph_run_reserve(run,iadd(meta.used,added))
in if accepted(status) then execute(b,plan,reserved) else let
  val ()=glyph_expansion_dispose(plan)
in GlyphPassResult(reserved,GlyphPassCapacity(),0,0) end end
