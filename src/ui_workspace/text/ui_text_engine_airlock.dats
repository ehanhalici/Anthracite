#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "mem.sats"
staload "ui_workspace/text/ui_text_engine_airlock.sats"
%{#
#include "data_font/legacy/arabic.cats"
%}
extern fun legacy_direction(p: ptr,n: int): int = "mac#anth_line_is_rtl"
implement ui_text_legacy_direction_code(b,n) = legacy_direction(buf_ptr(b),n)
