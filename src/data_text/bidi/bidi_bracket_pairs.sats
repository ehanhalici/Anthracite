staload "mem.sats"
staload "data_text/utf8/utf8.sats"
staload "data_text/bidi/bidi_types.sats"
staload "data_text/bidi/bidi_sequence.sats"
staload "data_text/bidi/bidi_bracket_data.sats"
fun bidi_bracket_pairs(data: !BidiBrackets, text: !ScalarText, work: !BidiWork, seq: !BidiSequence): Buf
fun bidi_resolve_brackets(data: !BidiBrackets, text: !ScalarText, work: !BidiWork, seq: !BidiSequence): void
