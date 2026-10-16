#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/bidi/bidi_types.sats"
staload "data_text/bidi/bidi_sequence.sats"
staload "data_text/bidi/bidi_predicates.sats"
staload "data_text/bidi/bidi_resolution.sats"

extern fun neutral_exhausted(): int = "mac#anth_die_int"

fun neutral_end {n:nat} .<n>. (n: int(n), work: !BidiWork, seq: !BidiSequence, i: int): int =
  if ige(i,bidi_sequence_count(seq)) then i else if n = 0 then neutral_exhausted()
  else if not(bidi_is_neutral(bidi_sequence_class(work,seq,i))) then i
  else neutral_end(n-1,work,seq,iadd(i,1))

fun resolve_group(work: !BidiWork, seq: !BidiSequence, start: int, left: BidiClass): int = let
  val finish = neutral_end(airlock_nat(iadd(bidi_sequence_count(seq),1)),work,seq,start)
  val after = if ieq(finish,bidi_sequence_count(seq)) then bidi_sequence_eos(seq)
    else bidi_sequence_class(work,seq,finish)
  val right = bidi_numeric_direction(after)
  val direction = if bidi_class_is_ltr(left) = bidi_class_is_ltr(right) then left
    else bidi_level_direction(bidi_sequence_level(seq))
  val () = bidi_sequence_fill(work,seq,start,finish,direction)
in finish end

fun resolve {n:nat} .<n>. (n: int(n), work: !BidiWork, seq: !BidiSequence, i: int, left: BidiClass): void =
  if ige(i,bidi_sequence_count(seq)) then () else if n = 0 then let val stop = neutral_exhausted() in () end
  else let
    val kind = bidi_sequence_class(work,seq,i)
    val next = if bidi_is_neutral(kind) then resolve_group(work,seq,i,left) else iadd(i,1)
    val strong = bidi_numeric_direction(bidi_sequence_class(work,seq,isub(next,1)))
  in resolve(n-1,work,seq,next,strong) end

implement bidi_resolve_neutrals(work,seq) =
  resolve(airlock_nat(iadd(bidi_sequence_count(seq),1)),work,seq,0,bidi_sequence_sos(seq))
