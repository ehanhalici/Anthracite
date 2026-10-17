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

typedef WeakContext = @{previous=BidiClass, strong=BidiClass}

fun mark_type(kind: BidiClass, previous: BidiClass): BidiClass =
  if not(bidi_is_nsm(kind)) then kind
  else if bidi_class_is_isolate(previous) orelse bidi_class_is_pdi(previous) then BON() else previous

fun number_type(kind: BidiClass, strong: BidiClass): BidiClass =
  if bidi_is_en(kind) andalso bidi_is_arabic(strong) then BAN() else kind

fun resolve_one(work: !BidiWork, seq: !BidiSequence, i: int, state: WeakContext): WeakContext = let
  val marked = mark_type(bidi_sequence_class(work,seq,i),state.previous)
  val numbered = number_type(marked,state.strong)
  val strong = if bidi_class_is_strong(marked) then marked else state.strong
  val resolved = if bidi_is_arabic(numbered) then BR() else numbered
  val () = bidi_sequence_set(work,seq,i,resolved)
in @{previous=marked,strong=strong} end

fun resolve {n:nat} .<n>. (
  n: int(n), work: !BidiWork, seq: !BidiSequence, i: int, state: WeakContext
): void = if n = 0 then () else let
  val next = resolve_one(work,seq,i,state)
in resolve(n-1,work,seq,iadd(i,1),next) end

implement bidi_weak_marks(work,seq) = let
  val sos = bidi_sequence_sos(seq)
in resolve(airlock_nat(bidi_sequence_count(seq)),work,seq,0,@{previous=sos,strong=sos}) end
