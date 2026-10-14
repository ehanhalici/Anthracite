staload "mem.sats"
datatype BracketKind = NoBracket | OpenBracket | CloseBracket
typedef BracketInfo = @{kind=BracketKind, paired=int}
datavtype BidiBrackets = BidiBrackets of (Buf, int)
datatype BracketError = BracketIo of int | BracketData
datavtype BracketLoad = BracketsLoaded of BidiBrackets | BracketsRejected of BracketError
fun bidi_brackets_load(path: string): BracketLoad
fun bidi_brackets_parse(source: !Buf): BracketLoad
fun bidi_bracket_info(data: !BidiBrackets, cp: int): BracketInfo
fun bidi_bracket_index(data: !BidiBrackets, cp: int): int
fun bidi_brackets_dispose(data: BidiBrackets): void
fun bidi_bracket_kind_of(code: int): BracketKind
fun bidi_bracket_kind_code(kind: BracketKind): int
fun bidi_bracket_is_open(kind: BracketKind): bool
fun bidi_bracket_is_close(kind: BracketKind): bool
fun bidi_bracket_canonical(cp: int): int
