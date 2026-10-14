#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/bidi_types.sats"
staload "data_text/bidi_sequence.sats"
staload "data_text/bidi_predicates.sats"
staload "data_text/bidi_weak.sats"

fun latin {n:nat} .<n>. (
  n: int(n), work: !BidiWork, seq: !BidiSequence, i: int, strong: BidiClass
): void = if n = 0 then () else let
  val kind = bidi_sequence_class(work,seq,i)
  val next = if bidi_class_is_strong(kind) then kind else strong
  val () = if bidi_is_en(kind) andalso bidi_class_is_ltr(strong) then bidi_sequence_set(work,seq,i,BL()) else ()
in latin(n-1,work,seq,iadd(i,1),next) end

implement bidi_weak_latin(work,seq) =
  latin(airlock_nat(bidi_sequence_count(seq)),work,seq,0,bidi_sequence_sos(seq))

