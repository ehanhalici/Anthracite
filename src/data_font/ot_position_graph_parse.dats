#include "data_font/ot_position_graph_internal.hats"
fun entry(b: !Buf,info: OtLayoutInfo,glyphs: int,index: int): OtPositionGraphEntryRead = let
  val child=ot_lookup_span(b,info,index)
in case+ child.kind of | ChildPresent() => ot_position_graph_entry(b,child.span,glyphs,info.lookupCount)
  | ChildMissing() => GraphEntryRejected(ot_error(OtBounds(),info.lookups))
  | ChildInvalid() => GraphEntryRejected(ot_error(OtBounds(),info.lookups)) end
fun rejected{n:nat}(xs: list_vt(OtPositionGraphEntry,n),e: OtPositionGraphEntry,error: OtError): OtPositionGraphRead = let
  val ()=ot_position_graph_entry_dispose(e) and ()=ot_position_graph_list_dispose(xs)
in PositionGraphRejected(error) end
fun read{n,k:nat} .<n>. (left: int(n),b: !Buf,info: OtLayoutInfo,font: int,glyphs: int,
  xs: list_vt(OtPositionGraphEntry,k),count: int(k),limits: OtContextLimits,remaining: llint): OtPositionGraphRead =
  if left = 0 then PositionGraphAccepted(OtPositionGraph(font,glyphs,limits,ot_position_graph_entries_make(xs,count))) else
  case+ entry(b,info,glyphs,left-1) of
    | ~GraphEntryRejected(e) => let val ()=ot_position_graph_list_dispose(xs) in PositionGraphRejected(e) end
    | ~GraphEntryAccepted(e) => let val cost=ot_position_graph_entry_bytes(e)
      val next=ot_position_graph_limits(limits,ot_position_graph_entry_limits(e))
    in if cost > remaining then rejected(xs,e,ot_error(OtCapacity(),info.lookups))
      else read(left-1,b,info,font,glyphs,list_vt_cons(e,xs),count+1,next,remaining-cost) end
implement ot_position_graph_parse(b,table,font,glyphs) = let val info=ot_layout_info(table)
in if ilt(font,0) orelse not(ot_glyph_domain_valid(glyphs)) then PositionGraphRejected(ot_error(OtGlyphDomain(),info.span))
  else read(airlock_nat(info.lookupCount),b,info,font,glyphs,list_vt_nil(),0,
    @{back=0,input=1,look=0},g0int2int_int_llint(MAX_REC_FUEL)) end
