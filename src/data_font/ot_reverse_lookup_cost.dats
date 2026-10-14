#include "data_font/ot_reverse_lookup_internal.hats"
implement ot_reverse_slot_limits(slot) = case+ slot of | ReverseSlotVacant() => @{back=0,input=1,look=0}
  | ReverseSlot(t) => let val+ GsubReverse(info,c)=t in @{back=info.back,input=1,look=info.look} end
implement ot_reverse_slot_bytes(slot) = case+ slot of | ReverseSlotVacant() => 0LL
  | ReverseSlot(t) => let val+ GsubReverse(info,c)=t val+ OtCoverageCache(rows,n,i)=c
  in g0int2int_int_llint(n)*g0int2int_int_llint(g0uint2int_size_int(sizeof<OtCoverageInfo>))+1024LL end
