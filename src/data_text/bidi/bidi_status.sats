staload "mem.sats"
staload "data_text/bidi/bidi_types.sats"

datatype BidiOverride = OverrideNone | OverrideLeft | OverrideRight
datatype BidiEntry = EmbeddingEntry | IsolateEntry
datatype EmbeddingDirection = EmbedLeft | EmbedRight
typedef EmbeddingCounts = @{overflow_isolates=int,overflow_embeddings=int,valid_isolates=int}
datavtype BidiStatus = BidiStatus of (Buf, Buf, Buf, int)

macdef BIDI_MAX_DEPTH = 125
macdef BIDI_STATUS_CAPACITY = 127
fun bidi_status_make(base: int): BidiStatus
fun bidi_status_dispose(status: BidiStatus): void
fun bidi_status_level(status: !BidiStatus): int
fun bidi_status_override(status: !BidiStatus): BidiOverride
fun bidi_status_isolate(status: !BidiStatus): bool
fun bidi_status_depth(status: !BidiStatus): int
fun bidi_status_push(status: !BidiStatus, level: int, override: BidiOverride, entry: BidiEntry): void
fun bidi_status_pop(status: !BidiStatus): void
fun bidi_new_level(status: !BidiStatus, direction: EmbeddingDirection): int
fun bidi_override_class(status: !BidiStatus, original: BidiClass): BidiClass
fun bidi_push_embedding(status: !BidiStatus, counts: EmbeddingCounts, dir: EmbeddingDirection, override: BidiOverride): EmbeddingCounts
fun bidi_push_isolate(status: !BidiStatus, counts: EmbeddingCounts, dir: EmbeddingDirection): EmbeddingCounts
fun bidi_pop_isolate(status: !BidiStatus, counts: EmbeddingCounts): EmbeddingCounts
fun bidi_pop_embedding(status: !BidiStatus, counts: EmbeddingCounts): EmbeddingCounts
fun bidi_explicit_levels(work: !BidiWork, base: int): void
