#include "share/atspre_staload.hats"
staload "data_font/opentype/layout/ot_layout_types.sats"
extern fun substitute(kind: OtLookupKind(1)): void
fun cannot_position_as_substitution(kind: OtLookupKind(2)): void = substitute(kind)
