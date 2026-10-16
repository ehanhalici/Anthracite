#include "data_font/glyph/position/glyph_position_schedule_internal.hats"
fun global(selection: GlyphSelection): bool = case+ selection.kind of
  | GlyphAll() => true | GlyphMasked() => false
fun rows{n:nat} .<n>. (left: int(n),s: !OtShapeSchedule(2),index: int,total: int): bool =
  if left = 0 then true else let val row=ot_shape_schedule_at(s,index)
  in if not(global(row.selection)) orelse ilt(row.lookup,0) orelse ige(row.lookup,total) then false
    else rows(left-1,s,iadd(index,1),total) end
implement glyph_position_schedule_check(g,s,m,meta) = let
  val+ OtPositionGraph(font,glyphs,limits,entries)=g
  val+ OtPositionGraphEntries(pf,gc | data,total,loaded)=entries val info=ot_shape_schedule_info(s)
in if ine(info.font,font) orelse ine(info.glyphs,glyphs) then PositionDomain()
  else if not(rows(airlock_nat(info.count),s,0,total)) then PositionReference()
  else glyph_position_lookup_graph_validate(g,m,meta) end
