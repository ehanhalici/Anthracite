#include "share/atspre_staload.hats"
staload "mem.sats"
staload "data_font/gsub_sequence_types.sats"
staload "data_font/ot_sequence_lookup_types.sats"
staload "data_font/ot_sequence_lookup.sats"
fun illegal(b: !Buf,t: !OtSequenceLookup(2)): void = let val result=ot_alternate_lookup_query(b,t,10,1) in () end
