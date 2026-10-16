#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/normalization/normalization_order.sats"
extern fun order_span_exhausted(): int = "mac#anth_die_int"

fun span_end {n:nat} .<n>. (
  n: int(n), classes: !Buf, i: int, total: int, previous: int, ordered: bool
): NormalizationOrderSpan = if ige(i,total) then @{finish=i,ordered=ordered}
  else if n = 0 then let val stop = order_span_exhausted() in @{finish=i,ordered=ordered} end
  else let val current = buf_get(classes,i) in
    if ieq(current,0) then @{finish=i,ordered=ordered}
    else span_end(n-1,classes,iadd(i,1),total,current,ordered andalso ile(previous,current)) end

implement normalization_order_span(classes,start,total) =
  span_end(airlock_nat(iadd(isub(total,start),1)),classes,iadd(start,1),total,buf_get(classes,start),true)

fun maximum {n:nat} .<n>. (n: int(n), classes: !Buf, start: int, total: int, size: int): int =
  if ige(start,total) then size else if n = 0 then order_span_exhausted() else let
    val span = normalization_order_span(classes,start,total)
    val length = if span.ordered then 0 else isub(span.finish,start)
  in maximum(n-1,classes,span.finish,total,imax(size,length)) end

implement normalization_order_maximum(classes,total) =
  maximum(airlock_nat(iadd(total,1)),classes,0,total,0)
