#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/bidi/bidi_types.sats"
staload "data_text/utf8/utf8.sats"
staload "data_text/bidi/bidi_sequence.sats"
staload "data_text/bidi/bidi_predicates.sats"
staload "data_text/bidi/bidi_bracket_data.sats"
staload "data_text/bidi/bidi_bracket_pairs.sats"

typedef EnclosedDirections = @{left=bool, right=bool}
extern fun bracket_resolution_exhausted(): BidiClass = "mac#anth_die_box"

fun enclosed {n:nat} .<n>. (
  n: int(n), work: !BidiWork, seq: !BidiSequence, i: int, state: EnclosedDirections
): EnclosedDirections = if n = 0 then state else let
  val kind = bidi_numeric_direction(bidi_sequence_class(work,seq,i))
  val left = bidi_class_is_ltr(kind)
  val right = bidi_class_is_strong(kind) andalso not(left)
  val next = @{left=state.left orelse left,right=state.right orelse right}
in enclosed(n-1,work,seq,iadd(i,1),next) end

fun preceding {n:nat} .<n>. (n: int(n), work: !BidiWork, seq: !BidiSequence, i: int): BidiClass =
  if ilt(i,0) then bidi_sequence_sos(seq) else if n = 0 then bracket_resolution_exhausted() else let
    val kind = bidi_numeric_direction(bidi_sequence_class(work,seq,i))
  in if bidi_class_is_strong(kind) then kind else preceding(n-1,work,seq,isub(i,1)) end

fun pair_direction(work: !BidiWork, seq: !BidiSequence, opening: int, closing: int): BidiClass = let
  val directions = enclosed(airlock_nat(isub(isub(closing,opening),1)),work,seq,iadd(opening,1),@{left=false,right=false})
  val embedding = bidi_level_direction(bidi_sequence_level(seq))
  val matching = if bidi_class_is_ltr(embedding) then directions.left else directions.right
in if matching then embedding else if not(directions.left orelse directions.right) then BON()
  else preceding(airlock_nat(iadd(opening,1)),work,seq,isub(opening,1)) end

fun marks {n:nat} .<n>. (n: int(n), work: !BidiWork, seq: !BidiSequence, i: int, direction: BidiClass): void =
  if n = 0 then () else let
    val original = bidi_original(work,bidi_sequence_index(seq,i))
  in if not(bidi_is_nsm(original)) then () else let
      val () = bidi_sequence_set(work,seq,i,direction)
    in marks(n-1,work,seq,iadd(i,1),direction) end end

fun set_bracket(work: !BidiWork, seq: !BidiSequence, i: int, direction: BidiClass): void = let
  val () = bidi_sequence_set(work,seq,i,direction)
  val start = iadd(i,1)
in marks(airlock_nat(isub(bidi_sequence_count(seq),start)),work,seq,start,direction) end

fun resolve_pair(work: !BidiWork, seq: !BidiSequence, opening: int, closing: int): void = let
  val direction = pair_direction(work,seq,opening,closing)
in if not(bidi_class_is_strong(direction)) then () else let
    val () = set_bracket(work,seq,opening,direction)
  in set_bracket(work,seq,closing,direction) end end

fun resolve {n:nat} .<n>. (n: int(n), work: !BidiWork, seq: !BidiSequence, pairs: !Buf, i: int): void =
  if n = 0 then () else let
    val closing = buf_get32(pairs,i)
    val () = if ilt(closing,0) then () else resolve_pair(work,seq,i,closing)
  in resolve(n-1,work,seq,pairs,iadd(i,1)) end

implement bidi_resolve_brackets(data,text,work,seq) = let
  val pairs = bidi_bracket_pairs(data,text,work,seq)
  val () = resolve(airlock_nat(bidi_sequence_count(seq)),work,seq,pairs,0)
in buf_free(pairs) end
