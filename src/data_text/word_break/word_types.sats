staload "mem.sats"
staload "data_text/utf8/utf8.sats"
staload "data_text/unicode/unicode_db.sats"
staload "data_text/unicode/unicode_property.sats"

(* WMissing denotes absent lookbehind/lookahead, not a Unicode property.
   All variants are nullary: carrying FSM context allocates no boxes. *)
datatype WordKind =
  | WMissing | WOther | WCR | WLF | WNewline | WExtend | WZWJ | WRegional
  | WFormat | WKatakana | WHebrew | WLetter | WSingle | WDouble
  | WMidNumLet | WMidLetter | WMidNum | WNumeric | WExtendNum | WSpace

typedef WordState = @{raw=WordKind,previous=WordKind,before=WordKind,regional=int}
typedef WordStep = @{boundary=bool,state=WordState}

fun word_kind_of(code: int): WordKind
fun word_initial(): WordState
fun word_step(map: !PropertyMap(1), emoji: !UnicodeDb, state: WordState, cp: int, following: WordKind): WordStep
fun word_boundaries(map: !PropertyMap(1), emoji: !UnicodeDb, text: !ScalarText): Buf
