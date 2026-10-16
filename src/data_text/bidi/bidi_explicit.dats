#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/bidi/bidi_types.sats"
staload "data_text/bidi/bidi_status.sats"
staload "data_text/bidi/bidi_event.sats"

fun isolate_direction(work: !BidiWork, i: int): EmbeddingDirection = let
  val matching = bidi_match(work,i)
  val finish = if ilt(matching,0) then bidi_count(work) else matching
  val level = bidi_first_strong_level(work,iadd(i,1),finish)
in if ieq(level,0) then EmbedLeft() else EmbedRight() end

fun apply_override(work: !BidiWork, status: !BidiStatus, i: int): void =
  bidi_set_class(work,i,bidi_override_class(status,bidi_original(work,i)))

fun close_isolate(work: !BidiWork, status: !BidiStatus, counts: EmbeddingCounts, i: int): EmbeddingCounts = let
  val next = bidi_pop_isolate(status,counts)
  val () = bidi_set_level(work,i,bidi_status_level(status))
  val () = apply_override(work,status,i)
in next end

fun explicit_command(work: !BidiWork, status: !BidiStatus, counts: EmbeddingCounts, i: int, base: int): EmbeddingCounts =
  case+ bidi_event_of(bidi_original(work,i)) of
  | EmbedL() => bidi_push_embedding(status,counts,EmbedLeft(),OverrideNone())
  | EmbedR() => bidi_push_embedding(status,counts,EmbedRight(),OverrideNone())
  | OverrideL() => bidi_push_embedding(status,counts,EmbedLeft(),OverrideLeft())
  | OverrideR() => bidi_push_embedding(status,counts,EmbedRight(),OverrideRight())
  | IsolateL() => let val () = apply_override(work,status,i) in bidi_push_isolate(status,counts,EmbedLeft()) end
  | IsolateR() => let val () = apply_override(work,status,i) in bidi_push_isolate(status,counts,EmbedRight()) end
  | IsolateAuto() => let val () = apply_override(work,status,i) in bidi_push_isolate(status,counts,isolate_direction(work,i)) end
  | EndIsolate() => close_isolate(work,status,counts,i)
  | EndEmbedding() => bidi_pop_embedding(status,counts)
  | RemovedBoundary() => counts
  | EndParagraph() => let val () = bidi_set_level(work,i,base) in counts end
  | OrdinaryCharacter() => let val () = apply_override(work,status,i) in counts end

extern fun explicit_exhausted(): void = "mac#anth_die_void"

fun apply_all {n:nat} .<n>. (
  n: int(n), work: !BidiWork, status: !BidiStatus, counts: EmbeddingCounts, i: int, base: int
): void =
  if n = 0 then () else let
    val () = bidi_set_level(work,i,bidi_status_level(status))
    val next = explicit_command(work,status,counts,i,base)
  in apply_all(n-1,work,status,next,iadd(i,1),base) end

implement bidi_explicit_levels(work,base) = let
  val status = bidi_status_make(base)
  val counts = @{overflow_isolates=0,overflow_embeddings=0,valid_isolates=0}
  val () = apply_all(airlock_nat(bidi_count(work)),work,status,counts,0,base)
in bidi_status_dispose(status) end
