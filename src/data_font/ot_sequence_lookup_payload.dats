#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/ot_layout_extension.sats"
staload "data_font/gsub_sequence_types.sats"
staload "data_font/gsub_sequence_work.sats"
staload "data_font/ot_sequence_lookup_types.sats"
staload "data_font/ot_sequence_lookup_work.sats"
fun extended{kind:int}(b: !Buf,s: OtSpan,glyphs: int,d: GsubSequenceDomain(kind),
  remaining: &int >> _): GsubSequencesRead(kind) = case+ ot_extension_parse(b,s,OtSubstitution()) of
  | ~ExtensionRejected(e) => SequencesRejected(e)
  | ~ExtensionAccepted(v) => if ot_sequence_action_matches(d,v.action)
    then gsub_sequences_parse_work(b,v.span,glyphs,d,remaining)
    else SequencesRejected(ot_error(OtUnsupported(),s))
implement ot_sequence_payload(b,s,a,glyphs,d,remaining) =
  if ot_sequence_action_matches(d,a) then gsub_sequences_parse_work(b,s,glyphs,d,remaining)
  else case+ a of
  | SubExtension() => extended(b,s,glyphs,d,remaining)
  | SubSingle() => SequencesRejected(ot_error(OtUnsupported(),s))
  | SubMultiple() => SequencesRejected(ot_error(OtUnsupported(),s))
  | SubAlternate() => SequencesRejected(ot_error(OtUnsupported(),s))
  | SubLigature() => SequencesRejected(ot_error(OtUnsupported(),s))
  | SubContext() => SequencesRejected(ot_error(OtUnsupported(),s))
  | SubChained() => SequencesRejected(ot_error(OtUnsupported(),s))
  | SubReverse() => SequencesRejected(ot_error(OtUnsupported(),s))
