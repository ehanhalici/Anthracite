#include "share/atspre_staload.hats"
staload "mem.sats"
staload "data_font/opentype/substitution/gsub_sequence_types.sats"
staload "data_font/opentype/sequence_lookup/ot_sequence_lookup_types.sats"
staload "data_font/opentype/sequence_lookup/ot_sequence_lookup.sats"
fun illegal(b: !Buf,t: !OtSequenceLookup(2)): void = let val result=ot_alternate_lookup_query(b,t,10,1) in () end
