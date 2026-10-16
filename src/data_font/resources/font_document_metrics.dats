#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "data_font/resources/font.sats"
staload "data_font/resources/font_document_metrics.sats"
implement font_document_line_height(f,minimum) = let val metrics=font_document_metrics(f)
in imax(minimum,metrics.height) end
