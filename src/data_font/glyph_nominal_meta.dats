#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "data_font/glyph_run_types.sats"
staload "airlock.sats"
staload "data_text/utf8.sats"
staload "data_font/glyph_nominal_work.sats"
implement glyph_nominal_meta(meta,count) = @{used=count,live=count,
  head=if ieq(count,0) then ~1 else 0,tail=isub(count,1),font=meta.font,glyphs=meta.glyphs,
  sourceLength=meta.sourceLength,nextLigature=meta.nextLigature,properties=meta.properties}
fun extent{n:nat} .<n>. (left: int(n),text: !ScalarText,i: int,limit: int): int =
  if left = 0 then limit else extent(left-1,text,iadd(i,1),imax(limit,scalar_end(text,i)))
implement glyph_nominal_source_extent(text) = extent(airlock_nat(scalar_count(text)),text,0,0)
