staload "mem.sats"
staload "data_text/bidi/bidi_types.sats"

datavtype BidiSequence = BidiSequence of (Buf, int, BidiClass, BidiClass, int)
(* Only the active logical indices of one isolating run sequence. *)
fun bidi_sequence_count(seq: !BidiSequence): int
fun bidi_sequence_index(seq: !BidiSequence, i: int): int
fun bidi_sequence_sos(seq: !BidiSequence): BidiClass
fun bidi_sequence_eos(seq: !BidiSequence): BidiClass
fun bidi_sequence_level(seq: !BidiSequence): int
fun bidi_sequence_class(work: !BidiWork, seq: !BidiSequence, i: int): BidiClass
fun bidi_sequence_set(work: !BidiWork, seq: !BidiSequence, i: int, kind: BidiClass): void
fun bidi_sequence_dispose(seq: BidiSequence): void
fun bidi_sequence_fill(work: !BidiWork, seq: !BidiSequence, start: int, finish: int, kind: BidiClass): void
