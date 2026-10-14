#include "data_font/ot_reverse_lookup_internal.hats"
fun parsed(b: !Buf,s: OtSpan,glyphs: int): OtReverseSlotRead = case+ gsub_reverse_parse(b,s,glyphs) of
  | ~ReverseRejected(e) => ReverseSlotRejected(e) | ~ReverseAccepted(t) => ReverseSlotAccepted(ReverseSlot(t))
fun direct(b: !Buf,s: OtSpan,glyphs: int,a: OtLookupKind(1)): OtReverseSlotRead = case+ a of
  | SubReverse() => parsed(b,s,glyphs) | SubSingle() => ReverseSlotRejected(ot_error(OtUnsupported(),s))
  | SubMultiple() => ReverseSlotRejected(ot_error(OtUnsupported(),s))
  | SubAlternate() => ReverseSlotRejected(ot_error(OtUnsupported(),s))
  | SubLigature() => ReverseSlotRejected(ot_error(OtUnsupported(),s))
  | SubContext() => ReverseSlotRejected(ot_error(OtUnsupported(),s))
  | SubChained() => ReverseSlotRejected(ot_error(OtUnsupported(),s))
  | SubExtension() => ReverseSlotRejected(ot_error(OtUnsupported(),s))
fun resolved(b: !Buf,s: OtSpan,glyphs: int,a: OtLookupKind(1)): OtReverseSlotRead = case+ a of
  | SubExtension() => (case+ ot_extension_parse(b,s,OtSubstitution()) of | ~ExtensionRejected(e) => ReverseSlotRejected(e)
    | ~ExtensionAccepted(t) => direct(b,t.span,glyphs,t.action))
  | SubReverse() => direct(b,s,glyphs,a) | SubSingle() => direct(b,s,glyphs,a) | SubMultiple() => direct(b,s,glyphs,a)
  | SubAlternate() => direct(b,s,glyphs,a) | SubLigature() => direct(b,s,glyphs,a)
  | SubContext() => direct(b,s,glyphs,a) | SubChained() => direct(b,s,glyphs,a)
implement ot_reverse_slot_parse(b,h,glyphs,index) = let
  val child=ot_optional_child(h.span,ot_u16(b,h.span,iadd(6,imul(index,2))),ot_lookup_header_floor(h))
in case+ child.kind of | ChildPresent() => resolved(b,child.span,glyphs,h.action)
  | ChildMissing() => ReverseSlotRejected(ot_error(OtBounds(),h.span))
  | ChildInvalid() => ReverseSlotRejected(ot_error(OtBounds(),h.span)) end
