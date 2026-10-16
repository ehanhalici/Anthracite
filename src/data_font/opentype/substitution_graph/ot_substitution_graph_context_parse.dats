#include "data_font/opentype/substitution_graph/ot_substitution_graph_internal.hats"
fun slot(b: !Buf,h: OtLookupInfo(1),glyphs: int,lookups: int,mode: OtContextMode,index: int): OtSubstitutionContextRead =
  case+ ot_substitution_graph_child(b,h,index) of | ~ExtensionRejected(e) => SubContextSlotRejected(e)
  | ~ExtensionAccepted(child) => case+ ot_context_parse(b,child.span,glyphs,lookups,OtSubstitution(),mode) of
    | ~ContextRejected(e) => SubContextSlotRejected(e)
    | ~ContextAccepted(program) => let val limits=ot_context_limits(b,program)
      in SubContextSlotAccepted(SubstitutionContext(program,limits)) end
fun read{n,k:nat} .<n>. (left: int(n),b: !Buf,h: OtLookupInfo(1),glyphs: int,lookups: int,mode: OtContextMode,
  xs: list_vt(OtSubstitutionContext,k),count: int(k)): OtSubstitutionContextTablesRead =
  if left = 0 then SubContextTablesAccepted(ot_substitution_contexts_make(xs,count)) else
  case+ slot(b,h,glyphs,lookups,mode,left-1) of
    | ~SubContextSlotRejected(e) => let val ()=ot_substitution_context_list_dispose(xs) in SubContextTablesRejected(e) end
    | ~SubContextSlotAccepted(p) => read(left-1,b,h,glyphs,lookups,mode,list_vt_cons(p,xs),count+1)
implement ot_substitution_context_tables(b,h,glyphs,lookups,mode) =
  read(airlock_nat(h.count),b,h,glyphs,lookups,mode,list_vt_nil(),0)
