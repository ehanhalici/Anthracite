#include "data_font/opentype/substitution_graph/ot_substitution_graph_internal.hats"
fun entry(b: !Buf,info: OtLayoutInfo,glyphs: int,index: int): OtSubstitutionGraphEntryRead = let
  val child=ot_lookup_span(b,info,index)
in case+ child.kind of | ChildPresent() => ot_substitution_graph_entry(b,child.span,glyphs,info.lookupCount)
  | ChildMissing() => SubGraphEntryRejected(ot_error(OtBounds(),info.lookups))
  | ChildInvalid() => SubGraphEntryRejected(ot_error(OtBounds(),info.lookups)) end
fun rejected{n:nat}(xs: list_vt(OtSubstitutionGraphEntry,n),e: OtSubstitutionGraphEntry,error: OtError): OtSubstitutionGraphRead = let
  val ()=ot_substitution_graph_entry_dispose(e) and ()=ot_substitution_graph_list_dispose(xs)
in SubstitutionGraphRejected(error) end
fun read{n,k:nat} .<n>. (left: int(n),b: !Buf,info: OtLayoutInfo,font: int,glyphs: int,
  xs: list_vt(OtSubstitutionGraphEntry,k),count: int(k),limits: OtContextLimits,remaining: llint): OtSubstitutionGraphRead =
  if left = 0 then SubstitutionGraphAccepted(OtSubstitutionGraph(font,glyphs,limits,ot_substitution_graph_entries_make(xs,count))) else
  case+ entry(b,info,glyphs,left-1) of
    | ~SubGraphEntryRejected(e) => let val ()=ot_substitution_graph_list_dispose(xs) in SubstitutionGraphRejected(e) end
    | ~SubGraphEntryAccepted(e) => let val cost=ot_substitution_graph_entry_bytes(e)
      val next=ot_substitution_graph_limits(limits,ot_substitution_graph_entry_limits(e))
    in if cost > remaining then rejected(xs,e,ot_error(OtCapacity(),info.lookups))
      else read(left-1,b,info,font,glyphs,list_vt_cons(e,xs),count+1,next,remaining-cost) end
implement ot_substitution_graph_parse(b,table,font,glyphs) = let val info=ot_layout_info(table)
in if ilt(font,0) orelse not(ot_glyph_domain_valid(glyphs)) then SubstitutionGraphRejected(ot_error(OtGlyphDomain(),info.span))
  else read(airlock_nat(info.lookupCount),b,info,font,glyphs,list_vt_nil(),0,
    @{back=0,input=1,look=0},g0int2int_int_llint(MAX_REC_FUEL)) end
