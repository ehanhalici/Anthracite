#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "mem.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/ot_layout_extension.sats"
staload "data_font/gsub_single_types.sats"
staload "data_font/gsub_single.sats"
staload "data_font/ot_single_lookup_types.sats"
staload "data_font/ot_single_lookup_work.sats"
fun extended(b: !Buf,s: OtSpan,glyphs: int): GsubSingleRead = case+ ot_extension_parse(b,s,OtSubstitution()) of
  | ~ExtensionRejected(e) => SingleRejected(e)
  | ~ExtensionAccepted(v) => case+ v.action of
    | SubSingle() => gsub_single_parse(b,v.span,glyphs)
    | SubMultiple() => SingleRejected(ot_error(OtUnsupported(),s))
    | SubAlternate() => SingleRejected(ot_error(OtUnsupported(),s))
    | SubLigature() => SingleRejected(ot_error(OtUnsupported(),s))
    | SubContext() => SingleRejected(ot_error(OtUnsupported(),s))
    | SubChained() => SingleRejected(ot_error(OtUnsupported(),s))
    | SubExtension() => SingleRejected(ot_error(OtUnsupported(),s))
    | SubReverse() => SingleRejected(ot_error(OtUnsupported(),s))
implement ot_single_payload(b,s,envelope,glyphs) = case+ envelope of
  | SingleDirect() => gsub_single_parse(b,s,glyphs) | SingleExtended() => extended(b,s,glyphs)
