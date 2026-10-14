#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_run_work.sats"
implement glyph_run_expansion_meta(meta,node,last,added) =
  @{used=iadd(meta.used,added),live=iadd(meta.live,added),head=meta.head,
    tail=if ieq(meta.tail,node) then last else meta.tail,font=meta.font,glyphs=meta.glyphs,
    sourceLength=meta.sourceLength,nextLigature=meta.nextLigature,properties=meta.properties}
