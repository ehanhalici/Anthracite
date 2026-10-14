#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/normalization_types.sats"
staload "data_text/normalization_engine.sats"
staload "data_text/normalization_order.sats"
staload "data_text/normalization_data.sats"

fun classes_fill {n:nat} .<n>. (n: int(n), data: !NormalizationData, values: !Buf, classes: !Buf, i: int): void =
  if n = 0 then () else let
    val row = normalization_info(data,buf_get32(values,i))
    val () = buf_set(classes,i,row.ccc)
  in classes_fill(n-1,data,values,classes,iadd(i,1)) end

extern fun order_all_exhausted(): void = "mac#anth_die_void"

fun order_all {n:nat} .<n>. (
  n: int(n), values: !Buf, starts: !Buf, ends: !Buf, classes: !Buf, permutation: !Buf, counters: !Buf, start: int, total: int
): void = if ige(start,total) then () else if n = 0 then order_all_exhausted() else let
  val span = normalization_order_span(classes,start,total)
  val size = isub(span.finish,start)
  val () = if span.ordered then () else normalization_order_segment(values,starts,ends,classes,permutation,counters,start,size)
in order_all(n-1,values,starts,ends,classes,permutation,counters,span.finish,total) end

fun sort_needed(values: !Buf, starts: !Buf, ends: !Buf, classes: !Buf, total: int, maximum: int): void =
  if ieq(maximum,0) then () else let
    val permutation = buf_make(imul(maximum,4))
    val counters = buf_make(1024)
    val () = order_all(airlock_nat(iadd(total,1)),values,starts,ends,classes,permutation,counters,0,total)
    val () = buf_free(permutation)
  in buf_free(counters) end

implement normalization_order(data,text) = let
  val+ ~NormalText(values,starts,ends,total,errors) = text
  val classes = buf_make(total)
  val () = classes_fill(airlock_nat(total),data,values,classes,0)
  val maximum = normalization_order_maximum(classes,total)
  val () = sort_needed(values,starts,ends,classes,total,maximum)
  val () = buf_free(classes)
in NormalText(values,starts,ends,total,errors) end
