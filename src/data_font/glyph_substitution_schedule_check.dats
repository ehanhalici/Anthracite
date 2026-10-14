#include "data_font/glyph_substitution_schedule_internal.hats"
fun ids{n:nat} .<n>. (left: int(n),s: !OtShapeSchedule(1),index: int,total: int): bool =
  if left = 0 then true else let val row=ot_shape_schedule_at(s,index)
  in if ilt(row.lookup,0) orelse ige(row.lookup,total) then false
    else ids(left-1,s,iadd(index,1),total) end
implement glyph_substitution_schedule_check(g,s,m,run) = let
  val+ OtSubstitutionGraph(font,glyphs,limits,entries)=g
  val+ OtSubstitutionGraphEntries(pf,gc | rows,total,loaded)=entries
  val info=ot_shape_schedule_info(s)
in if ine(info.font,font) orelse ine(info.glyphs,glyphs) then GlyphPassDomain()
  else if not(ids(airlock_nat(info.count),s,0,total)) then GlyphPassReference()
  else glyph_substitution_validate_graph(g,m,run) end
