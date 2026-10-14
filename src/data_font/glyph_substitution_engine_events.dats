#include "data_font/glyph_substitution_engine_internal.hats"
implement glyph_substitution_event_fault(status) = @{kind=SubFault(),depth=0,status=status,next= ~1,matched=false}
implement glyph_substitution_event_continue(depth) = @{kind=SubContinue(),depth=depth,status=GlyphPassApplied(),next= ~1,matched=false}
implement glyph_substitution_event_done(depth,next,matched) =
  if ieq(depth,0) then @{kind=SubReturned(),depth=0,status=GlyphPassApplied(),next=next,matched=matched}
  else glyph_substitution_event_continue(isub(depth,1))
