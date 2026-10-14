#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/gsub_ligature_types.sats"
staload "data_font/gsub_ligatures.sats"
staload "data_font/gsub_ligature_work.sats"
staload "data_font/ot_ligation_lookup_types.sats"
staload "data_font/ot_ligation_lookup_work.sats"
staload "data_font/ot_layout_extension.sats"
fun extended(b: !Buf,s: OtSpan,glyphs: int): GsubLigaturesRead = case+ ot_extension_parse(b,s,OtSubstitution()) of
  | ~ExtensionRejected(e) => LigaturesRejected(e) | ~ExtensionAccepted(t) => case+ t.action of
    | SubLigature() => gsub_ligatures_parse(b,t.span,glyphs)
    | SubSingle() => LigaturesRejected(ot_error(OtUnsupported(),t.span))
    | SubMultiple() => LigaturesRejected(ot_error(OtUnsupported(),t.span))
    | SubAlternate() => LigaturesRejected(ot_error(OtUnsupported(),t.span))
    | SubContext() => LigaturesRejected(ot_error(OtUnsupported(),t.span))
    | SubChained() => LigaturesRejected(ot_error(OtUnsupported(),t.span))
    | SubExtension() => LigaturesRejected(ot_error(OtUnsupported(),t.span))
    | SubReverse() => LigaturesRejected(ot_error(OtUnsupported(),t.span))
implement ot_ligation_payload(b,s,glyphs,action) = case+ action of
  | SubLigature() => gsub_ligatures_parse(b,s,glyphs) | SubExtension() => extended(b,s,glyphs)
  | SubSingle() => LigaturesRejected(ot_error(OtUnsupported(),s))
  | SubMultiple() => LigaturesRejected(ot_error(OtUnsupported(),s))
  | SubAlternate() => LigaturesRejected(ot_error(OtUnsupported(),s))
  | SubContext() => LigaturesRejected(ot_error(OtUnsupported(),s))
  | SubChained() => LigaturesRejected(ot_error(OtUnsupported(),s))
  | SubReverse() => LigaturesRejected(ot_error(OtUnsupported(),s))
