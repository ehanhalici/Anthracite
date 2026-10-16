#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/normalization/normalization_order.sats"

fun read_scalar(values: !Buf, starts: !Buf, ends: !Buf, classes: !Buf, i: int): NormalizationOrderScalar =
  @{cp=buf_get32(values,i),start=buf_get32(starts,i),finish=buf_get32(ends,i),ccc=buf_get(classes,i)}

fun write_scalar(values: !Buf, starts: !Buf, ends: !Buf, classes: !Buf, i: int, scalar: NormalizationOrderScalar): void = let
  val () = buf_set32(values,i,scalar.cp)
  val () = buf_set32(starts,i,scalar.start)
  val () = buf_set32(ends,i,scalar.finish)
in buf_set(classes,i,scalar.ccc) end

extern fun permutation_exhausted(): void = "mac#anth_die_void"

fun rotate {n:nat} .<n>. (
  n: int(n), values: !Buf, starts: !Buf, ends: !Buf, classes: !Buf, permutation: !Buf,
  start: int, first: int, current: int, carried: NormalizationOrderScalar
): void = if n = 0 then permutation_exhausted() else let
  val source = buf_get32(permutation,current)
  val () = buf_set32(permutation,current,current)
in if ieq(source,first) then write_scalar(values,starts,ends,classes,iadd(start,current),carried)
  else let
    val next = read_scalar(values,starts,ends,classes,iadd(start,source))
    val () = write_scalar(values,starts,ends,classes,iadd(start,current),next)
  in rotate(n-1,values,starts,ends,classes,permutation,start,first,source,carried) end end

fun permutation_step(values: !Buf, starts: !Buf, ends: !Buf, classes: !Buf, permutation: !Buf, start: int, size: int, i: int): void =
  if ieq(buf_get32(permutation,i),i) then () else let
    val carried = read_scalar(values,starts,ends,classes,iadd(start,i))
  in rotate(airlock_nat(iadd(size,1)),values,starts,ends,classes,permutation,start,i,i,carried) end

fun apply {n:nat} .<n>. (
  n: int(n), values: !Buf, starts: !Buf, ends: !Buf, classes: !Buf, permutation: !Buf, start: int, size: int, i: int
): void = if n = 0 then () else let
  val () = permutation_step(values,starts,ends,classes,permutation,start,size,i)
in apply(n-1,values,starts,ends,classes,permutation,start,size,iadd(i,1)) end

implement normalization_order_permute(values,starts,ends,classes,permutation,start,size) =
  apply(airlock_nat(size),values,starts,ends,classes,permutation,start,size,0)
