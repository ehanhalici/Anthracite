#include "script_test.hats"
staload "data_text/script_data_types.sats"
staload "data_text/script_data.sats"
staload "data_text/script_items_types.sats"
staload "data_text/script_items.sats"
staload "data_text/unicode_db.sats"
staload "data_text/utf8.sats"
staload "data_text/bidi_bracket_data.sats"
staload "script_items_contracts.sats"
extern fun script_items_test_decode_failed(): ScalarText = "mac#anth_die_box"
fun script_items_test_bytes(value: string): Buf = let val count=c_strlen(value)
  var b: Buf=buf_make(iadd(count,1)) val ()=buf_append(b,c_str_ptr(value),count)
in b end
fun script_items_test_decode(b: !Buf): ScalarText = case+ text_decode(b,buf_len(b)) of
  | ~InvalidTextSpan() => script_items_test_decode_failed() | ~DecodedText(text) => text
