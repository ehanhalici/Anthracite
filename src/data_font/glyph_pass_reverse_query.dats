#include "data_font/glyph_pass_reverse_internal.hats"
implement glyph_reverse_window_status(s) = case+ s of
  | WindowReady() => GlyphPassApplied() | WindowSkipped() => GlyphPassApplied()
  | WindowDomain() => GlyphPassDomain() | WindowReference() => GlyphPassReference()
  | WindowCapacity() => GlyphPassCapacity()
fun slot_match{n:nat}(b: !Buf,slot: !OtReverseSlot,m: !GlyphMetadata,s: !GlyphStorage(n),
  meta: GlyphRunMeta,o: GlyphWindowSelection,node: int,w: !GlyphContextWindow,
  remaining: &int >> int): GlyphReverseMatch = case+ slot of
  | ReverseSlotVacant() => @{status=GlyphPassReference(),matched=false,glyph=0}
  | ReverseSlot(t) => let
    val span=glyph_window_gather_limits(b,m,s,meta,o,node,w,ot_reverse_slot_limits(slot),remaining)
    val r=glyph_window_reverse_match(b,t,w,span)
  in @{status=glyph_reverse_window_status(span.status),matched=r.matched,glyph=r.glyph} end
fun read{n,k,i:nat | i < k}(b: !Buf,rows: !OtReverseTables(k,k),index: int(i),m: !GlyphMetadata,
  s: !GlyphStorage(n),meta: GlyphRunMeta,o: GlyphWindowSelection,node: int,w: !GlyphContextWindow,
  remaining: &int >> int): GlyphReverseMatch = let
  var slot: OtReverseSlot=ReverseSlotVacant()
  val ()=ot_reverse_tables_exchange(rows,index,slot)
  val r=slot_match(b,slot,m,s,meta,o,node,w,remaining)
  val ()=ot_reverse_tables_exchange(rows,index,slot)
  val ()=ot_reverse_slot_dispose(slot)
in r end
fun query{n,k,i:nat | i <= k} .<k-i>. (b: !Buf,rows: !OtReverseTables(k,k),index: int(i),
  m: !GlyphMetadata,s: !GlyphStorage(n),meta: GlyphRunMeta,o: GlyphWindowSelection,node: int,
  w: !GlyphContextWindow,remaining: &int >> int): GlyphReverseMatch = let
  val+ OtReverseTables(pf,gc | address,count,filled)=rows
in if index = count then @{status=GlyphPassApplied(),matched=false,glyph=0}
  else if ile(remaining,0) then @{status=GlyphPassCapacity(),matched=false,glyph=0} else let
    val ()=remaining := isub(remaining,1)
    val r=read(b,rows,index,m,s,meta,o,node,w,remaining)
  in case+ r.status of | GlyphPassDomain() => r | GlyphPassReference() => r | GlyphPassCapacity() => r
    | GlyphPassApplied() => if r.matched then r else query(b,rows,index+1,m,s,meta,o,node,w,remaining) end end
implement glyph_reverse_query(b,t,m,s,meta,selection,node,w,remaining) = let
  val+ OtReverseLookup(h,glyphs,limits,rows)=t
in query(b,rows,0,m,s,meta,@{flags=h.flags,set=h.markSet,selection=selection},node,w,remaining) end
