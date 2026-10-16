#include "data_font/text/font_text_internal.hats"
staload "data_font/text/private/font_text_dispatch.sats"
extern fun source_failed(): void = "mac#anth_die_void"
implement font_text_raw_source(p,length) = let
  val ()=if ilt(length,0) orelse igt(length,MAX_REC_FUEL) then source_failed() else ()
  var source=buf_make(length) val ()=buf_append(source,p,length)
in source end
implement font_text_slice_source(b,start,length) = let
  val ()=if ilt(start,0) orelse igt(start,buf_cap(b)) then source_failed() else ()
  val remaining=isub(buf_cap(b),start)
  val ()=if ilt(length,0) orelse igt(length,remaining) then source_failed() else ()
  var source=buf_make(length) val ()=buf_append_at(source,b,start,length)
in source end
