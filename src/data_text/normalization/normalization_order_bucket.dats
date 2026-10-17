#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/normalization/normalization_order.sats"

fun frequencies {n:nat} .<n>. (n: int(n), classes: !Buf, counters: !Buf, i: int): void =
  if n = 0 then () else let
    val ccc = buf_get(classes,i)
    val () = buf_set32(counters,ccc,iadd(buf_get32(counters,ccc),1))
  in frequencies(n-1,classes,counters,iadd(i,1)) end

fun prefixes {n:nat} .<n>. (n: int(n), counters: !Buf, i: int, total: int): void =
  if n = 0 then () else let
    val count = buf_get32(counters,i)
    val () = buf_set32(counters,i,total)
  in prefixes(n-1,counters,iadd(i,1),iadd(total,count)) end

fun scatter {n:nat} .<n>. (n: int(n), classes: !Buf, permutation: !Buf, counters: !Buf, start: int, i: int): void =
  if n = 0 then () else let
    val ccc = buf_get(classes,iadd(start,i))
    val target = buf_get32(counters,ccc)
    val () = buf_set32(permutation,target,i)
    val () = buf_set32(counters,ccc,iadd(target,1))
  in scatter(n-1,classes,permutation,counters,start,iadd(i,1)) end

implement normalization_order_segment(values,starts,ends,classes,permutation,counters,start,size) = let
  val () = buf_zero(counters)
  val () = frequencies(airlock_nat(size),classes,counters,start)
  val () = prefixes(256,counters,0,0)
  val () = scatter(airlock_nat(size),classes,permutation,counters,start,0)
in normalization_order_permute(values,starts,ends,classes,permutation,start,size) end
