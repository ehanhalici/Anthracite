#include "data_font/ot_position_graph_internal.hats"
fun resolved(b: !Buf,s: OtSpan,a: OtLookupKind(2)): OtExtensionRead(2) = case+ a of
  | PosExtension() => ot_extension_parse(b,s,OtPositioning())
  | PosSingle() => ExtensionAccepted(@{span=s,action=a}) | PosPair() => ExtensionAccepted(@{span=s,action=a})
  | PosCursive() => ExtensionAccepted(@{span=s,action=a}) | PosMarkBase() => ExtensionAccepted(@{span=s,action=a})
  | PosMarkLigature() => ExtensionAccepted(@{span=s,action=a}) | PosMarkMark() => ExtensionAccepted(@{span=s,action=a})
  | PosContext() => ExtensionAccepted(@{span=s,action=a}) | PosChained() => ExtensionAccepted(@{span=s,action=a})
implement ot_position_graph_child(b,h,index) = let
  val child=ot_optional_child(h.span,ot_u16(b,h.span,iadd(6,imul(index,2))),ot_lookup_header_floor(h))
in case+ child.kind of | ChildMissing() => ExtensionRejected(ot_error(OtBounds(),h.span))
  | ChildInvalid() => ExtensionRejected(ot_error(OtBounds(),h.span))
  | ChildPresent() => resolved(b,child.span,h.action) end
