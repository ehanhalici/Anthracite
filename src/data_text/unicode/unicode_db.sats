staload "mem.sats"

datatype GraphemeClass =
  | GOther | GCR | GLF | GControl | GExtend | GZWJ | GRegional
  | GPrepend | GSpacing | GL | GV | GT | GLV | GLVT
datatype ConjunctClass = InNone | InConsonant | InExtend | InLinker
datavtype UnicodeDb = UnicodeDb of (Buf, int)
datavtype UnicodeLoad = UnicodeLoaded of UnicodeDb | UnicodeDataError of ()

fun unicode_load(path: string): UnicodeLoad
fun unicode_dispose(db: UnicodeDb): void
fun unicode_grapheme(db: !UnicodeDb, cp: int): GraphemeClass
fun unicode_conjunct(db: !UnicodeDb, cp: int): ConjunctClass
fun unicode_pictographic(db: !UnicodeDb, cp: int): bool
fun grapheme_class_of(code: int): GraphemeClass
fun conjunct_class_of(code: int): ConjunctClass
