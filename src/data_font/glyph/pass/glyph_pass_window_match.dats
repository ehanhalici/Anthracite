#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/context/ot_context_types.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/run/glyph_run_storage.sats"
staload "data_font/glyph/run/glyph_run_work.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/core/glyph_metadata.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/glyph/pass/glyph_pass_work.sats"
staload "data_font/glyph/pass/glyph_pass_window_types.sats"
staload "data_font/glyph/pass/glyph_pass_window_work.sats"
staload "data_font/opentype/context/ot_context.sats"
staload "data_font/glyph/pass/glyph_pass_window.sats"
implement glyph_window_span_valid(span,limits,capacity) =
  glyph_window_status_valid(span.status) andalso ige(span.start,0) andalso ile(span.start,limits.back)
    andalso ile(span.count,capacity) andalso ilt(span.start,span.count) andalso ige(span.input,1)
    andalso ile(span.input,limits.input) andalso ile(span.input,isub(span.count,span.start))
implement glyph_window_match(b,p,w,span) = let val+ GlyphContextWindow(glyphs,nodes,limits,capacity)=w
  val count=if glyph_window_span_valid(span,limits,capacity) then span.count else 0
in ot_context_match_bounded(b,p,glyphs,count,span.start,span.input) end
implement glyph_window_node(w,span,sequence) = let val+ GlyphContextWindow(glyphs,nodes,limits,capacity)=w
in if not(glyph_window_span_valid(span,limits,capacity)) orelse ilt(sequence,0) orelse ige(sequence,span.input)
  then ~1 else buf_get32(nodes,iadd(span.start,sequence)) end
