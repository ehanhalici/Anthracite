#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/substitution/gsub_sequence_types.sats"
staload "data_font/opentype/sequence_lookup/ot_sequence_lookup_types.sats"
staload "data_font/opentype/sequence_lookup/ot_sequence_lookup_work.sats"
implement ot_sequence_action_matches(domain,action) = case+ action of
  | SubMultiple() => (case+ domain of | GsubMultiple() => true | GsubAlternate() => false)
  | SubAlternate() => (case+ domain of | GsubMultiple() => false | GsubAlternate() => true)
  | SubSingle() => false | SubLigature() => false | SubContext() => false
  | SubChained() => false | SubExtension() => false | SubReverse() => false
