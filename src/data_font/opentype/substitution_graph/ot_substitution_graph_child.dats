#include "data_font/opentype/substitution_graph/ot_substitution_graph_internal.hats"
fun resolved(b: !Buf,s: OtSpan,a: OtLookupKind(1)): OtExtensionRead(1) = case+ a of
  | SubExtension() => ot_extension_parse(b,s,OtSubstitution())
  | SubSingle() => ExtensionAccepted(@{span=s,action=a}) | SubMultiple() => ExtensionAccepted(@{span=s,action=a})
  | SubAlternate() => ExtensionAccepted(@{span=s,action=a}) | SubLigature() => ExtensionAccepted(@{span=s,action=a})
  | SubContext() => ExtensionAccepted(@{span=s,action=a}) | SubChained() => ExtensionAccepted(@{span=s,action=a})
  | SubReverse() => ExtensionAccepted(@{span=s,action=a})
implement ot_substitution_graph_child(b,h,index) = let
  val child=ot_optional_child(h.span,ot_u16(b,h.span,iadd(6,imul(index,2))),ot_lookup_header_floor(h))
in case+ child.kind of | ChildMissing() => ExtensionRejected(ot_error(OtBounds(),h.span))
  | ChildInvalid() => ExtensionRejected(ot_error(OtBounds(),h.span))
  | ChildPresent() => resolved(b,child.span,h.action) end
