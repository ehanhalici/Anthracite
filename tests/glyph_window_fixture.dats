#include "glyph_window_test.hats"
extern fun window_test_failed(): GlyphContextWindow = "mac#anth_die_box"
implement window_test_make(limits) = case+ glyph_window_make(limits) of
  | ~WindowAllocated(w) => w | ~WindowRejected(status) => window_test_failed()
implement window_test_gather(b,m,run,o,node,w,remaining) = let val+ GlyphRun(phase,meta,storage)=run
in glyph_window_gather(b,m,storage,meta,o,node,w,remaining) end
