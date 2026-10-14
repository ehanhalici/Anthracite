#include "data_font/ot_reverse_lookup_internal.hats"
fun merged(a: OtContextLimits,b: OtContextLimits): OtContextLimits = @{back=imax(a.back,b.back),input=1,look=imax(a.look,b.look)}
fun read{n,k:nat} .<n>. (left: int(n),b: !Buf,h: OtLookupInfo(1),glyphs: int,xs: list_vt(OtReverseSlot,k),
  count: int(k),limits: &OtContextLimits >> OtContextLimits,remaining: llint): OtReverseTablesRead =
  if left = 0 then ReverseTablesAccepted(ot_reverse_tables_make(xs,count)) else
  case+ ot_reverse_slot_parse(b,h,glyphs,left-1) of
    | ~ReverseSlotRejected(e) => let val ()=ot_reverse_slot_list_dispose(xs) in ReverseTablesRejected(e) end
    | ~ReverseSlotAccepted(slot) => let val cost=ot_reverse_slot_bytes(slot)
      val ()=limits := merged(limits,ot_reverse_slot_limits(slot))
    in if cost > remaining then let val ()=ot_reverse_slot_dispose(slot) and ()=ot_reverse_slot_list_dispose(xs)
      in ReverseTablesRejected(ot_error(OtCapacity(),h.span)) end
      else read(left-1,b,h,glyphs,list_vt_cons(slot,xs),count+1,limits,remaining-cost) end
implement ot_reverse_tables_read(b,h,glyphs,limits) = read(airlock_nat(h.count),b,h,glyphs,list_vt_nil(),0,limits,g0int2int_int_llint(MAX_REC_FUEL))
