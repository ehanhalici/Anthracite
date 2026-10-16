#include "data_font/glyph/substitution/glyph_substitution_engine_internal.hats"
extern fun substitution_walk_failed(): int = "mac#anth_die_int"
fun invariant(): GlyphSubstitutionCounts = let val failed=substitution_walk_failed()
in @{status=GlyphPassReference(),visited=failed,matches=0} end
fun walk{n:nat} .<n>. (left: int(n),b: !Buf,g: !OtSubstitutionGraph,m: !GlyphMetadata,
  run: &GlyphRun(1) >> GlyphRun(1),lookup: int,o: GlyphSubstitutionOptions,w: &GlyphSubstitutionWorkspace >> GlyphSubstitutionWorkspace,
  d: GlyphSubstitutionTraversal,node: int,generation: &int >> int,remaining: &int >> int,
  visited: int,matches: int): GlyphSubstitutionCounts =
  if ieq(node,~1) then @{status=GlyphPassApplied(),visited=visited,matches=matches}
  else if left = 0 then invariant() else let
    val before=glyph_run_query(run,node)
    val event=glyph_substitution_nested(b,g,m,run,lookup,node,o,w,generation,remaining)
  in case+ event.kind of
    | SubFault() => @{status=event.status,visited=visited,matches=matches}
    | SubContinue() => invariant()
    | SubReturned() => let val next=case+ d of | SubForward() => event.next | SubReverse() => before.links.previous
      in walk(left-1,b,g,m,run,lookup,o,w,d,next,generation,remaining,iadd(visited,1),iadd(matches,if event.matched then 1 else 0)) end end
implement glyph_substitution_walk(b,g,m,run,lookup,o,w,remaining) = let
  val meta=glyph_run_meta(run) val d=glyph_substitution_traversal(g,lookup)
  val first=case+ d of | SubForward() => meta.head | SubReverse() => meta.tail
  var generation: int=0
in walk(airlock_nat(meta.live),b,g,m,run,lookup,o,w,d,first,generation,remaining,0,0) end
