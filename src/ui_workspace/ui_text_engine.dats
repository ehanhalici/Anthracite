#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "data_font/font.sats"
staload "data_font/font_text.sats"
staload "ui_workspace/ui_text_engine.sats"
staload "mem.sats"
staload "data_font/font_text_types.sats"
staload "data_font/private/font_text_dispatch.sats"
staload "ui_workspace/ui_text_engine_airlock.sats"
implement ui_text_engine_title(f) = if font_text_active(f) then "Yazi Tipi / Native" else "Yazi Tipi (fonts/)"
implement ui_text_line_direction_code(f,b,n) = if font_text_active(f) then
  font_text_result_pixels(font_text_direction_code(f,b,n)) else ui_text_legacy_direction_code(b,n)
