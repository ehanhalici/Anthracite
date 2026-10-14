#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/bidi_types.sats"
staload "data_text/bidi_status.sats"

extern fun status_invalid(): void = "mac#anth_die_void"
extern fun override_invalid(): BidiOverride = "mac#anth_die_box"
extern fun entry_invalid(): BidiEntry = "mac#anth_die_box"

fun override_code(value: BidiOverride): int = case+ value of
  | OverrideNone() => 0 | OverrideLeft() => 1 | OverrideRight() => 2
fun override_of(value: int): BidiOverride = case+ value of
  | 0 => OverrideNone() | 1 => OverrideLeft() | 2 => OverrideRight() | _ => override_invalid()
fun entry_code(entry: BidiEntry): int = case+ entry of
  | EmbeddingEntry() => 0 | IsolateEntry() => 1
fun entry_of(value: int): BidiEntry = case+ value of
  | 0 => EmbeddingEntry() | 1 => IsolateEntry() | _ => entry_invalid()

implement bidi_status_make(base) = let
  val levels = buf_make(BIDI_STATUS_CAPACITY)
  val overrides = buf_make(BIDI_STATUS_CAPACITY)
  val isolates = buf_make(BIDI_STATUS_CAPACITY)
  val () = buf_set(levels,0,base)
in BidiStatus(levels,overrides,isolates,1) end

implement bidi_status_level(status) = let val+ BidiStatus(levels,overrides,isolates,n) = status in
  buf_get(levels,isub(n,1)) end
implement bidi_status_override(status) = let val+ BidiStatus(levels,overrides,isolates,n) = status in
  override_of(buf_get(overrides,isub(n,1))) end
implement bidi_status_isolate(status) = let val+ BidiStatus(levels,overrides,isolates,n) = status in
  case+ entry_of(buf_get(isolates,isub(n,1))) of
  | IsolateEntry() => true | EmbeddingEntry() => false end
implement bidi_status_depth(status) = let val+ BidiStatus(levels,overrides,isolates,n) = status in n end

implement bidi_status_push(status,level,override,entry) = case+ status of
  | @BidiStatus(levels,overrides,isolates,n) => let
      val () = if ige(n,BIDI_STATUS_CAPACITY) orelse ilt(level,0) orelse igt(level,BIDI_MAX_DEPTH)
        then status_invalid() else ()
      val () = buf_set(levels,n,level)
      val () = buf_set(overrides,n,override_code(override))
      val () = buf_set(isolates,n,entry_code(entry))
      val () = n := iadd(n,1)
    in fold@(status) end

implement bidi_status_pop(status) = case+ status of
  | @BidiStatus(levels,overrides,isolates,n) => let
      val () = if ile(n,1) then status_invalid() else ()
      val () = n := isub(n,1)
    in fold@(status) end

implement bidi_new_level(status,direction) = let val level = bidi_status_level(status) in
  case+ direction of
  | EmbedLeft() => iadd(level,isub(2,imod(level,2)))
  | EmbedRight() => iadd(level,iadd(1,imod(level,2))) end

implement bidi_override_class(status,original) = case+ bidi_status_override(status) of
  | OverrideNone() => original | OverrideLeft() => BL() | OverrideRight() => BR()

implement bidi_status_dispose(status) = let
  val+ ~BidiStatus(levels,overrides,isolates,n) = status
  val () = buf_free(levels)
  val () = buf_free(overrides)
in buf_free(isolates) end
