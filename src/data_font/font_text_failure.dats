#include "data_font/font_text_internal.hats"
staload "data_font/private/font_text_dispatch.sats"
extern fun dispatch_failed(): int = "mac#anth_die_int"
fun failure_code(error: FontSpanFailure): int = case+ error of
  | SpanAnalysis() => 1 | SpanItems() => 2 | SpanContext() => 3 | SpanShaping() => 4
  | SpanCapacity() => 5 | SpanOverflow() => 6 | SpanParagraph() => 7
  | SpanMissing() => 8 | SpanUnsupported() => 9
implement font_text_result_pixels(result) = case+ result of
  | FontTextValue(value) => value
  | FontTextInactive() => let val ()=println!("event=native_text_dispatch reason=inactive") in dispatch_failed() end
  | FontTextFailed(error) => let val ()=println!("event=native_text_dispatch reason=layout detail=",failure_code(error))
    in dispatch_failed() end
