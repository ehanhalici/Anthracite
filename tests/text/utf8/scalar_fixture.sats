staload "mem.sats"
staload "data_text/utf8/utf8.sats"
(* Hex codepoint fixtures compare scalar results. Real UTF-8 tests exercise
   source spans separately; synthetic fixtures intentionally use zero spans. *)
fun scalar_fixture_parse(source: !Buf, start: int, finish: int): ScalarText
fun scalar_fixture_column(source: !Buf, start: int, finish: int, column: int): ScalarText
fun scalar_fixture_differences(actual: !ScalarText, expected: !ScalarText): int
