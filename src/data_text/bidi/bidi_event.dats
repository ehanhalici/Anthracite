#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "data_text/bidi/bidi_types.sats"
staload "data_text/bidi/bidi_event.sats"

implement bidi_event_of(kind) = case+ kind of
  | BLRE() => EmbedL() | BRLE() => EmbedR()
  | BLRO() => OverrideL() | BRLO() => OverrideR()
  | BLRI() => IsolateL() | BRLI() => IsolateR() | BFSI() => IsolateAuto()
  | BPDI() => EndIsolate() | BPDF() => EndEmbedding()
  | BBN() => RemovedBoundary() | BB() => EndParagraph()
  | BL() => OrdinaryCharacter() | BR() => OrdinaryCharacter() | BAL() => OrdinaryCharacter()
  | BEN() => OrdinaryCharacter() | BES() => OrdinaryCharacter() | BET() => OrdinaryCharacter()
  | BAN() => OrdinaryCharacter() | BCS() => OrdinaryCharacter() | BS() => OrdinaryCharacter()
  | BWS() => OrdinaryCharacter() | BON() => OrdinaryCharacter() | BNSM() => OrdinaryCharacter()
