#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/bidi/bidi_types.sats"
staload "data_text/bidi/bidi_sequence.sats"
staload "data_text/bidi/bidi_predicates.sats"
staload "data_text/bidi/bidi_weak.sats"

fun adjacent(work: !BidiWork, seq: !BidiSequence, i: int): BidiClass =
  if ilt(i,0) then bidi_sequence_sos(seq)
  else if ige(i,bidi_sequence_count(seq)) then bidi_sequence_eos(seq)
  else bidi_sequence_class(work,seq,i)

fun separator_type(kind: BidiClass, left: BidiClass, right: BidiClass): BidiClass =
  if not(bidi_is_separator(kind)) then kind
  else if bidi_is_en(left) andalso bidi_is_en(right) then BEN()
  else if bidi_is_cs(kind) andalso bidi_is_an(left) andalso bidi_is_an(right) then BAN()
  else kind

fun separators {n:nat} .<n>. (n: int(n), work: !BidiWork, seq: !BidiSequence, i: int): void =
  if n = 0 then () else let
    val kind = bidi_sequence_class(work,seq,i)
    val next = separator_type(kind,adjacent(work,seq,isub(i,1)),adjacent(work,seq,iadd(i,1)))
    val () = bidi_sequence_set(work,seq,i,next)
  in separators(n-1,work,seq,iadd(i,1)) end

extern fun weak_exhausted(): int = "mac#anth_die_int"

fun terminator_end {n:nat} .<n>. (n: int(n), work: !BidiWork, seq: !BidiSequence, i: int): int =
  if ige(i,bidi_sequence_count(seq)) then i else if n = 0 then weak_exhausted()
  else if not(bidi_is_et(bidi_sequence_class(work,seq,i))) then i
  else terminator_end(n-1,work,seq,iadd(i,1))

fun resolve_group(work: !BidiWork, seq: !BidiSequence, start: int): int = let
  val finish = terminator_end(airlock_nat(iadd(bidi_sequence_count(seq),1)),work,seq,start)
  val joins = bidi_is_en(adjacent(work,seq,isub(start,1))) orelse bidi_is_en(adjacent(work,seq,finish))
  val () = if joins then bidi_sequence_fill(work,seq,start,finish,BEN()) else ()
in finish end

fun terminators {n:nat} .<n>. (n: int(n), work: !BidiWork, seq: !BidiSequence, i: int): void =
  if ige(i,bidi_sequence_count(seq)) then () else if n = 0 then let val stop = weak_exhausted() in () end
  else let
    val next = if bidi_is_et(bidi_sequence_class(work,seq,i)) then resolve_group(work,seq,i) else iadd(i,1)
  in terminators(n-1,work,seq,next) end

fun remaining {n:nat} .<n>. (n: int(n), work: !BidiWork, seq: !BidiSequence, i: int): void =
  if n = 0 then () else let
    val kind = bidi_sequence_class(work,seq,i)
    val () = if bidi_is_separator(kind) orelse bidi_is_et(kind) then bidi_sequence_set(work,seq,i,BON()) else ()
  in remaining(n-1,work,seq,iadd(i,1)) end

implement bidi_weak_numbers(work,seq) = let
  val n = airlock_nat(bidi_sequence_count(seq))
  val () = separators(n,work,seq,0)
  val () = terminators(n+1,work,seq,0)
in remaining(n,work,seq,0) end
