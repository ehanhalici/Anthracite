#include "data_font/opentype/position_lookup/ot_position_graph_internal.hats"
fun slot(b: !Buf,h: OtLookupInfo(2),glyphs: int,lookups: int,mode: OtContextMode,index: int): OtPositionContextRead =
  case+ ot_position_graph_child(b,h,index) of | ~ExtensionRejected(e) => ContextSlotRejected(e)
  | ~ExtensionAccepted(child) => case+ ot_context_parse(b,child.span,glyphs,lookups,OtPositioning(),mode) of
    | ~ContextRejected(e) => ContextSlotRejected(e)
    | ~ContextAccepted(program) => let val limits=ot_context_limits(b,program)
      in ContextSlotAccepted(PositionContext(program,limits)) end
fun read{n,k:nat} .<n>. (left: int(n),b: !Buf,h: OtLookupInfo(2),glyphs: int,lookups: int,mode: OtContextMode,
  xs: list_vt(OtPositionContext,k),count: int(k)): OtPositionContextTablesRead =
  if left = 0 then ContextTablesAccepted(ot_position_contexts_make(xs,count)) else
  case+ slot(b,h,glyphs,lookups,mode,left-1) of
    | ~ContextSlotRejected(e) => let val ()=ot_position_context_list_dispose(xs) in ContextTablesRejected(e) end
    | ~ContextSlotAccepted(p) => read(left-1,b,h,glyphs,lookups,mode,list_vt_cons(p,xs),count+1)
implement ot_position_context_tables(b,h,glyphs,lookups,mode) =
  read(airlock_nat(h.count),b,h,glyphs,lookups,mode,list_vt_nil(),0)
