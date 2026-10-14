staload "mem.sats"
staload "data_text/utf8.sats"
staload "data_text/unicode_property.sats"

datatype BidiClass =
  | BL | BR | BAL | BEN | BES | BET | BAN | BCS | BB | BS | BWS | BON
  | BLRE | BLRO | BRLE | BRLO | BPDF | BNSM | BBN | BFSI | BLRI | BRLI | BPDI
datatype ParagraphDirection = AutoLtr | AutoRtl | ForceLtr | ForceRtl

(* Codepoints remain in the borrowed ScalarText. The work buffer owns only
   original/working properties, levels and matched-isolate source indices. *)
datavtype BidiWork = BidiWork of (Buf, Buf, Buf, Buf, int, int)
fun bidi_class_of(code: int): BidiClass
fun bidi_class_code(kind: BidiClass): int
fun bidi_direction_of(code: int): ParagraphDirection
fun bidi_class_is_strong(kind: BidiClass): bool
fun bidi_class_is_ltr(kind: BidiClass): bool
fun bidi_class_is_isolate(kind: BidiClass): bool
fun bidi_class_is_pdi(kind: BidiClass): bool
fun bidi_class_is_removed(kind: BidiClass): bool

fun bidi_make(map: !PropertyMap(2), text: !ScalarText): BidiWork
fun bidi_make_range(map: !PropertyMap(2), text: !ScalarText, start: int, finish: int): BidiWork
fun bidi_count(work: !BidiWork): int
fun bidi_source_index(work: !BidiWork, i: int): int
fun bidi_original(work: !BidiWork, i: int): BidiClass
fun bidi_current(work: !BidiWork, i: int): BidiClass
fun bidi_set_class(work: !BidiWork, i: int, kind: BidiClass): void
fun bidi_level(work: !BidiWork, i: int): int
fun bidi_set_level(work: !BidiWork, i: int, level: int): void
fun bidi_match(work: !BidiWork, i: int): int
fun bidi_set_match(work: !BidiWork, left: int, right: int): void
fun bidi_dispose(work: BidiWork): void
fun bidi_match_isolates(work: !BidiWork): void
fun bidi_paragraph_level(work: !BidiWork, direction: ParagraphDirection): int
fun bidi_first_strong_level(work: !BidiWork, start: int, finish: int): int
