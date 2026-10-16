#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/bidi/bidi_types.sats"

fun match_one(work: !BidiWork, stack: !Buf, depth: int, i: int): int = let
  val kind = bidi_original(work,i)
in if bidi_class_is_isolate(kind) then let val () = buf_set32(stack,depth,i) in iadd(depth,1) end
  else if bidi_class_is_pdi(kind) andalso igt(depth,0) then let
    val next = isub(depth,1)
    val opening = buf_get32(stack,next)
    val () = bidi_set_match(work,opening,i)
  in next end else depth end

fun match_all {n:nat} .<n>. (n: int(n), work: !BidiWork, stack: !Buf, depth: int, i: int): void =
  if n = 0 then () else let
    val next = match_one(work,stack,depth,i)
  in match_all(n-1,work,stack,next,iadd(i,1)) end

implement bidi_match_isolates(work) = let
  val n = bidi_count(work)
  val stack = buf_make(imul(n,4))
  val () = match_all(airlock_nat(n),work,stack,0,0)
in buf_free(stack) end
