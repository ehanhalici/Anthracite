#include "share/atspre_staload.hats"
staload "mem.sats"
staload "data_font/opentype/substitution/gsub_sequence_types.sats"
staload "data_font/opentype/sequence_lookup/ot_sequence_lookup_types.sats"
staload "data_font/opentype/sequence_lookup/ot_sequence_lookup_work.sats"
fun illegal(t: !OtSequenceTables(2,1)): GsubSequenceInfo = ot_sequence_tables_get(t,0)
