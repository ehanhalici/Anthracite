staload "mem.sats"

(* Offsets always refer to the original UTF-8 source, never to a normalized
   or visually reordered copy. Invalid sequences retain their source span. *)
(* Nullary outcome tags and a flat record avoid allocating a payload object
   for every scalar under ATS_MEMALLOC_LIBC. Only Utf8Scalar carries a value. *)
datatype Utf8Outcome =
  | Utf8End of ()
  | Utf8Scalar of ()
  | Utf8Malformed of ()
typedef Utf8Step = @{kind=Utf8Outcome,value=int,next=int}
(* A borrowed source reader supplies at most four bytes, without buffer
   allocation. Buf and Doc share maximal-subpart decoding through this kernel. *)
typedef Utf8Window = @{available=int,first=int,second=int,third=int,fourth=int}
fun utf8_window_step(window: Utf8Window,offset: int): Utf8Step

datavtype ScalarText = ScalarText of (Buf, Buf, Buf, int, int)
datavtype DecodeResult =
  | DecodedText of ScalarText
  | InvalidTextSpan of ()

fun utf8_step(source: !Buf, limit: int, offset: int): Utf8Step
(* Length is a readable capacity span, bounded by MAX_REC_FUEL. Decoding
   measures first, then allocates exactly three words per emitted scalar. *)
fun text_decode(source: !Buf, length: int): DecodeResult
fun scalar_count(text: !ScalarText): int
fun scalar_errors(text: !ScalarText): int
fun scalar_value(text: !ScalarText, index: int): int
fun scalar_start(text: !ScalarText, index: int): int
fun scalar_end(text: !ScalarText, index: int): int
fun scalar_dispose(text: ScalarText): void
