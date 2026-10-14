#include "data_font/glyph_position_lookup_graph_internal.hats"
staload "data_font/glyph_position_lookup_workspace_types.sats"
staload "data_font/glyph_position_lookup_workspace.sats"
staload "data_font/glyph_position_stage_types.sats"
staload "data_font/glyph_position_stage_work.sats"
fun walk{n,k,f:nat} .<f>. (left: int(f),b: !Buf,g: !OtPositionGraph,ids: !Buf,selection: GlyphSelection,index: int,
  m: !GlyphMetadata,s: !GlyphStorage(n),meta: GlyphRunMeta,scale: GlyphScale,d: GlyphPositionDirection,w: !GlyphContextWindow,
  workspace: !GlyphPositionLookupWorkspace(k),remaining: &int >> int,applied: &int >> int,matches: &int >> int): GlyphPositionStatus =
  if left = 0 then PositionReady() else let
    val status=glyph_position_lookup_workspace_walk(b,g,m,s,meta,scale,selection,d,buf_get32(ids,index),w,workspace,remaining,matches)
    val ()=if glyph_position_ready(status) then applied := iadd(applied,1) else ()
  in if not(glyph_position_ready(status)) then status
    else walk(left-1,b,g,ids,selection,iadd(index,1),m,s,meta,scale,d,w,workspace,remaining,applied,matches) end
implement glyph_position_stage_walk(b,stage,m,s,meta,scale,d,w,workspace,remaining,applied,matches) = let
  val+ GlyphPositionStage(g,ids,selection,count)=stage
in walk(airlock_nat(count),b,g,ids,selection,0,m,s,meta,scale,d,w,workspace,remaining,applied,matches) end
