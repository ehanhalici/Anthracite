#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/bidi_types.sats"

fun next_index(work: !BidiWork, i: int, finish: int): int =
  if not(bidi_class_is_isolate(bidi_original(work,i))) then iadd(i,1) else let
    val matching = bidi_match(work,i)
  in if ilt(matching,0) orelse ige(matching,finish) then finish else iadd(matching,1) end

extern fun paragraph_exhausted(): int = "mac#anth_die_int"

fun strong_index {n:nat} .<n>. (n: int(n), work: !BidiWork, i: int, finish: int): int =
  if ige(i,finish) then finish else if n = 0 then paragraph_exhausted()
  else if bidi_class_is_strong(bidi_original(work,i)) then i
  else strong_index(n-1,work,next_index(work,i,finish),finish)

fun strong_level(work: !BidiWork, start: int, finish: int, fallback: int): int = let
  val at = strong_index(airlock_nat(imax(0,isub(finish,start))),work,start,finish)
in if ige(at,finish) then fallback else
  if bidi_class_is_ltr(bidi_original(work,at)) then 0 else 1 end

implement bidi_paragraph_level(work,direction) = case+ direction of
  | ForceLtr() => 0 | ForceRtl() => 1
  | AutoLtr() => strong_level(work,0,bidi_count(work),0)
  | AutoRtl() => strong_level(work,0,bidi_count(work),1)

implement bidi_first_strong_level(work,start,finish) = strong_level(work,start,finish,0)
