staload "mem.sats"
staload "data_text/utf8/utf8.sats"
staload "data_text/unicode/unicode_db.sats"

datatype EmojiContext = EmojiNone | EmojiBase | EmojiJoiner
datatype ConjunctContext = ConjunctNone | ConjunctLinked
typedef GraphemeState = @{
  previous=GraphemeClass, regional=int, emoji=EmojiContext, conjunct=ConjunctContext
}
typedef GraphemeStep = @{boundary=bool, state=GraphemeState}

fun grapheme_initial(): GraphemeState
fun grapheme_step(db: !UnicodeDb, state: GraphemeState, cp: int): GraphemeStep
(* One byte per scalar boundary, including the start and end boundaries. *)
fun grapheme_boundaries(db: !UnicodeDb, text: !ScalarText): Buf
