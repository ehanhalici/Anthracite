#include "data_font/glyph_position_schedule_internal.hats"
fun walk{n,k,f:nat} .<f>. (left: int(f),b: !Buf,g: !OtPositionGraph,schedule: !OtShapeSchedule(2),index: int,
  m: !GlyphMetadata,s: !GlyphStorage(n),meta: GlyphRunMeta,scale: GlyphScale,d: GlyphPositionDirection,w: !GlyphContextWindow,
  workspace: !GlyphPositionLookupWorkspace(k),remaining: &int >> int,applied: &int >> int,matches: &int >> int): GlyphPositionStatus =
  if left = 0 then PositionReady() else let val row=ot_shape_schedule_at(schedule,index)
    val status=glyph_position_lookup_workspace_walk(b,g,m,s,meta,scale,row.selection,d,row.lookup,w,workspace,remaining,matches)
    val ()=if glyph_position_ready(status) then applied := iadd(applied,1) else ()
  in if not(glyph_position_ready(status)) then status
    else walk(left-1,b,g,schedule,iadd(index,1),m,s,meta,scale,d,w,workspace,remaining,applied,matches) end
implement glyph_position_schedule_walk(b,g,schedule,m,s,meta,scale,d,w,workspace,remaining,applied,matches) =
  let val info=ot_shape_schedule_info(schedule)
  in walk(airlock_nat(info.count),b,g,schedule,0,m,s,meta,scale,d,w,workspace,remaining,applied,matches) end

