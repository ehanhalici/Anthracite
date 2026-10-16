#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/bidi/bidi_types.sats"
staload "data_text/bidi/bidi_sequence.sats"

implement bidi_sequence_count(seq) = let val+ BidiSequence(indices,n,sos,eos,level) = seq in n end
implement bidi_sequence_index(seq,i) = let val+ BidiSequence(indices,n,sos,eos,level) = seq in buf_get32(indices,i) end
implement bidi_sequence_sos(seq) = let val+ BidiSequence(indices,n,sos,eos,level) = seq in sos end
implement bidi_sequence_eos(seq) = let val+ BidiSequence(indices,n,sos,eos,level) = seq in eos end
implement bidi_sequence_level(seq) = let val+ BidiSequence(indices,n,sos,eos,level) = seq in level end
implement bidi_sequence_class(work,seq,i) = bidi_current(work,bidi_sequence_index(seq,i))
implement bidi_sequence_set(work,seq,i,kind) = bidi_set_class(work,bidi_sequence_index(seq,i),kind)
implement bidi_sequence_dispose(seq) = let val+ ~BidiSequence(indices,n,sos,eos,level) = seq in buf_free(indices) end

fun fill {n:nat} .<n>. (n: int(n), work: !BidiWork, seq: !BidiSequence, i: int, kind: BidiClass): void =
  if n = 0 then () else let
    val () = bidi_sequence_set(work,seq,i,kind)
  in fill(n-1,work,seq,iadd(i,1),kind) end

implement bidi_sequence_fill(work,seq,start,finish,kind) =
  fill(airlock_nat(isub(finish,start)),work,seq,start,kind)
