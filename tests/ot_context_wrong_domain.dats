#include "share/atspre_staload.hats"
staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/ot_context_types.sats"
staload "data_font/ot_context.sats"
extern fun substitute(action: OtContextAction(1)): void
fun cannot_substitute(positioning: OtContextMatch(2),font: !Buf): void =
  substitute(ot_context_action(font,positioning,0))
