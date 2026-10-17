#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/bidi/bidi_types.sats"
staload "data_text/bidi/bidi_status.sats"

fun can_push(counts: EmbeddingCounts, level: int): bool =
  ile(level,BIDI_MAX_DEPTH) andalso ieq(counts.overflow_isolates,0) andalso ieq(counts.overflow_embeddings,0)

implement bidi_push_embedding(status,counts,dir,override) = let
  val level = bidi_new_level(status,dir)
in if can_push(counts,level) then let
    val () = bidi_status_push(status,level,override,EmbeddingEntry())
  in counts end else
    @{overflow_isolates=counts.overflow_isolates,
      overflow_embeddings=iadd(counts.overflow_embeddings,if ieq(counts.overflow_isolates,0) then 1 else 0),
      valid_isolates=counts.valid_isolates} end

implement bidi_push_isolate(status,counts,dir) = let
  val level = bidi_new_level(status,dir)
in if can_push(counts,level) then let
    val () = bidi_status_push(status,level,OverrideNone(),IsolateEntry())
  in @{overflow_isolates=counts.overflow_isolates,overflow_embeddings=counts.overflow_embeddings,
      valid_isolates=iadd(counts.valid_isolates,1)} end
  else @{overflow_isolates=iadd(counts.overflow_isolates,1),
    overflow_embeddings=counts.overflow_embeddings,valid_isolates=counts.valid_isolates} end

extern fun isolate_exhausted(): void = "mac#anth_die_void"

fun pop_to_isolate {n:nat} .<n>. (n: int(n), status: !BidiStatus): void =
  if bidi_status_isolate(status) then bidi_status_pop(status)
  else if n = 0 then isolate_exhausted() else let
    val () = bidi_status_pop(status)
  in pop_to_isolate(n-1,status) end

implement bidi_pop_isolate(status,counts) =
  if igt(counts.overflow_isolates,0) then
    @{overflow_isolates=isub(counts.overflow_isolates,1),
      overflow_embeddings=counts.overflow_embeddings,valid_isolates=counts.valid_isolates}
  else if ieq(counts.valid_isolates,0) then counts else let
    val () = pop_to_isolate(BIDI_STATUS_CAPACITY,status)
  in @{overflow_isolates=0,overflow_embeddings=0,valid_isolates=isub(counts.valid_isolates,1)} end

implement bidi_pop_embedding(status,counts) =
  if igt(counts.overflow_isolates,0) then counts
  else if igt(counts.overflow_embeddings,0) then
    @{overflow_isolates=0,overflow_embeddings=isub(counts.overflow_embeddings,1),valid_isolates=counts.valid_isolates}
  else let
    val () = if igt(bidi_status_depth(status),1) andalso not(bidi_status_isolate(status))
      then bidi_status_pop(status) else ()
  in counts end
