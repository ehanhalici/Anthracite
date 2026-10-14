staload "mem.sats"
staload "data_font/opentype_types.sats"
datatype GsubSequenceDomain(int) = GsubMultiple(2) | GsubAlternate(3)
typedef GsubSequenceInfo = @{span=OtSpan,coverage=OtCoverageInfo,count=int,glyphs=int}
datavtype GsubSequences(kind:int) = GsubSequences(kind) of GsubSequenceInfo
datavtype GsubSequencesRead(kind:int) =
  | SequencesAccepted(kind) of GsubSequences(kind) | SequencesRejected(kind) of OtError
(* A flat borrowed view; only matched views contain a sequence. Read its glyphs
   only with 0 <= index < count. Alternate sets may contain zero choices. *)
typedef GsubSequenceView = @{matched=bool,span=OtSpan,count=int}
