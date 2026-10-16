staload "data_text/bidi/bidi_types.sats"
datatype ExplicitEvent =
  | EmbedL | EmbedR | OverrideL | OverrideR | IsolateL | IsolateR | IsolateAuto
  | EndIsolate | EndEmbedding | RemovedBoundary | EndParagraph | OrdinaryCharacter
fun bidi_event_of(kind: BidiClass): ExplicitEvent
