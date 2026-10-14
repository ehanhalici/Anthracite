staload "data_text/bidi_types.sats"
staload "data_text/bidi_sequence.sats"
staload "data_text/bidi_bracket_data.sats"
staload "data_text/utf8.sats"
fun bidi_resolve_neutrals(work: !BidiWork, seq: !BidiSequence): void
fun bidi_implicit_levels(work: !BidiWork, seq: !BidiSequence): void
(* P2 through I2 for one paragraph. Layout applies L1/L2 separately per line. *)
fun bidi_resolve(work: !BidiWork, text: !ScalarText, brackets: !BidiBrackets, direction: ParagraphDirection): int

