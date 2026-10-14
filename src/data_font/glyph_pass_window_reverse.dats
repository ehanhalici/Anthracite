#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "mem.sats"
staload "data_font/ot_context_types.sats"
staload "data_font/gsub_reverse_types.sats"
staload "data_font/gsub_single_types.sats"
staload "data_font/gsub_reverse.sats"
staload "data_font/glyph_pass_window_types.sats"
staload "data_font/glyph_pass_window_work.sats"
staload "data_font/glyph_pass_window.sats"
implement glyph_window_reverse_match(b,t,w,span) = let
  val+ GlyphContextWindow(glyphs,nodes,limits,capacity)=w
  val count=if glyph_window_span_valid(span,limits,capacity) then span.count else 0
in gsub_reverse_match(b,t,glyphs,count,span.start) end
