#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/bidi/bidi_types.sats"
staload "data_text/bidi/bidi_predicates.sats"
staload "data_text/bidi/bidi_line.sats"

fun reset_one(work: !BidiWork, i: int, base: int, trailing: bool): bool = let
  val kind = bidi_original(work,i)
in if bidi_class_is_removed(kind) then trailing else if bidi_is_line_separator(kind) then let
    val () = bidi_set_level(work,i,base)
  in true end else if not(bidi_is_line_space(kind)) then false else let
    val () = if trailing then bidi_set_level(work,i,base) else ()
  in trailing end end

fun reset {n:nat} .<n>. (
  n: int(n), work: !BidiWork, i: int, base: int, trailing: bool
): void = if n = 0 then () else let
  val next = reset_one(work,i,base,trailing)
in reset(n-1,work,isub(i,1),base,next) end

implement bidi_line_reset(work,start,finish,base) =
  reset(airlock_nat(isub(finish,start)),work,isub(finish,1),base,true)
