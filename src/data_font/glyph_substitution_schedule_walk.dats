#include "data_font/glyph_substitution_schedule_internal.hats"
fun walk{n:nat} .<n>. (left: int(n),b: !Buf,g: !OtSubstitutionGraph,s: !OtShapeSchedule(1),m: !GlyphMetadata,
  run: &GlyphRun(1) >> GlyphRun(1),w: &GlyphSubstitutionWorkspace >> GlyphSubstitutionWorkspace,
  index: int,matches: int,remaining: &int >> int): GlyphSubstitutionCounts =
  if left = 0 then @{status=GlyphPassApplied(),visited=index,matches=matches} else let
    val row=ot_shape_schedule_at(s,index)
    val result=glyph_substitution_walk(b,g,m,run,row.lookup,@{selection=row.selection,alternate=1},w,remaining)
  in case+ result.status of
    | GlyphPassApplied() => walk(left-1,b,g,s,m,run,w,iadd(index,1),iadd(matches,result.matches),remaining)
    | GlyphPassDomain() => @{status=result.status,visited=0,matches=0}
    | GlyphPassReference() => @{status=result.status,visited=0,matches=0}
    | GlyphPassCapacity() => @{status=result.status,visited=0,matches=0} end
implement glyph_substitution_schedule_walk(b,g,s,m,run,w,remaining) = let val info=ot_shape_schedule_info(s)
in walk(airlock_nat(info.count),b,g,s,m,run,w,0,0,remaining) end

