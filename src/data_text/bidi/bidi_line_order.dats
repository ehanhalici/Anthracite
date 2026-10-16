#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/bidi/bidi_types.sats"
staload "data_text/bidi/bidi_line.sats"
typedef OrderLevels = @{minimum=int, maximum=int}
extern fun order_exhausted(): int = "mac#anth_die_int"

fun collect {n:nat} .<n>. (n: int(n), work: !BidiWork, output: !Buf, i: int, count: int): int =
  if n = 0 then count else let
    val removed = bidi_class_is_removed(bidi_original(work,i))
    val () = if removed then () else buf_set32(output,count,i)
    val next = if removed then count else iadd(count,1)
  in collect(n-1,work,output,iadd(i,1),next) end

fun limits {n:nat} .<n>. (n: int(n), work: !BidiWork, output: !Buf, i: int, state: OrderLevels): OrderLevels =
  if n = 0 then state else let
    val level = bidi_level(work,buf_get32(output,i))
    val minimum = if ieq(imod(level,2),1) then imin(state.minimum,level) else state.minimum
    val next = @{minimum=minimum,maximum=imax(state.maximum,level)}
  in limits(n-1,work,output,iadd(i,1),next) end

fun reverse {n:nat} .<n>. (n: int(n), output: !Buf, left: int, right: int): void =
  if n = 0 then () else let
    val old = buf_get32(output,left)
    val () = buf_set32(output,left,buf_get32(output,right))
    val () = buf_set32(output,right,old)
  in reverse(n-1,output,iadd(left,1),isub(right,1)) end

fun span_end {n:nat} .<n>. (n: int(n), work: !BidiWork, output: !Buf, i: int, total: int, level: int): int =
  if ige(i,total) then i else if n = 0 then order_exhausted()
  else if ilt(bidi_level(work,buf_get32(output,i)),level) then i
  else span_end(n-1,work,output,iadd(i,1),total,level)

fun reverse_group(work: !BidiWork, output: !Buf, i: int, total: int, level: int): int = let
  val finish = span_end(airlock_nat(iadd(total,1)),work,output,i,total,level)
  val half = idiv(isub(finish,i),2)
  val () = reverse(airlock_nat(half),output,i,isub(finish,1))
in finish end

fun reorder_level {n:nat} .<n>. (
  n: int(n), work: !BidiWork, output: !Buf, i: int, total: int, level: int
): void = if ige(i,total) then () else if n = 0 then let val stop = order_exhausted() in () end else let
  val current = bidi_level(work,buf_get32(output,i))
  val next = if ilt(current,level) then iadd(i,1) else reverse_group(work,output,i,total,level)
in reorder_level(n-1,work,output,next,total,level) end

fun reorder {n:nat} .<n>. (
  n: int(n), work: !BidiWork, output: !Buf, total: int, level: int
): void = if n = 0 then () else let
  val () = reorder_level(airlock_nat(iadd(total,1)),work,output,0,total,level)
in reorder(n-1,work,output,total,isub(level,1)) end

implement bidi_line_order(work,start,finish) = let
  val output = buf_make(imul(isub(finish,start),4))
  val total = collect(airlock_nat(isub(finish,start)),work,output,start,0)
  val range = limits(airlock_nat(total),work,output,0,@{minimum=127,maximum=0})
  val steps = imax(0,iadd(isub(range.maximum,range.minimum),1))
  val () = reorder(airlock_nat(steps),work,output,total,range.maximum)
in BidiOrder(output,total) end

implement bidi_order_count(order) = let val+ BidiOrder(output,total) = order in total end
implement bidi_order_index(order,i) = let val+ BidiOrder(output,total) = order in buf_get32(output,i) end
implement bidi_order_dispose(order) = let val+ ~BidiOrder(output,total) = order in buf_free(output) end
