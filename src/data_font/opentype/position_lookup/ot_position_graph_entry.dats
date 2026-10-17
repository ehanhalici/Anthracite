#include "data_font/opentype/position_lookup/ot_position_graph_internal.hats"
fun direct(b: !Buf,h: OtLookupInfo(2),glyphs: int): OtPositionGraphEntryRead =
  case+ ot_position_lookup_parse(b,h.span,glyphs) of
  | ~PositionLookupRejected(e) => GraphEntryRejected(e)
  | ~PositionLookupAccepted(t) => GraphEntryAccepted(PositionGraphDirect(t))
fun context(b: !Buf,h: OtLookupInfo(2),glyphs: int,lookups: int,mode: OtContextMode): OtPositionGraphEntryRead =
  case+ ot_position_context_tables(b,h,glyphs,lookups,mode) of
  | ~ContextTablesRejected(e) => GraphEntryRejected(e)
  | ~ContextTablesAccepted(t) => GraphEntryAccepted(PositionGraphContext(h,t))
fun action(b: !Buf,h: OtLookupInfo(2),glyphs: int,lookups: int,a: OtLookupKind(2)): OtPositionGraphEntryRead = case+ a of
  | PosContext() => context(b,h,glyphs,lookups,ContextPlain())
  | PosChained() => context(b,h,glyphs,lookups,ContextChained())
  | PosSingle() => direct(b,h,glyphs) | PosPair() => direct(b,h,glyphs)
  | PosCursive() => direct(b,h,glyphs) | PosMarkBase() => direct(b,h,glyphs)
  | PosMarkLigature() => direct(b,h,glyphs) | PosMarkMark() => direct(b,h,glyphs) | PosExtension() => direct(b,h,glyphs)
fun classify(b: !Buf,h: OtLookupInfo(2),glyphs: int,lookups: int): OtPositionGraphEntryRead = case+ h.action of
  | PosExtension() => if ieq(h.count,0) then direct(b,h,glyphs) else
    (case+ ot_position_graph_child(b,h,0) of | ~ExtensionRejected(e) => GraphEntryRejected(e)
      | ~ExtensionAccepted(c) => action(b,h,glyphs,lookups,c.action))
  | PosSingle() => action(b,h,glyphs,lookups,h.action) | PosPair() => action(b,h,glyphs,lookups,h.action)
  | PosCursive() => action(b,h,glyphs,lookups,h.action) | PosMarkBase() => action(b,h,glyphs,lookups,h.action)
  | PosMarkLigature() => action(b,h,glyphs,lookups,h.action) | PosMarkMark() => action(b,h,glyphs,lookups,h.action)
  | PosContext() => action(b,h,glyphs,lookups,h.action) | PosChained() => action(b,h,glyphs,lookups,h.action)
fun checked(b: !Buf,h: OtLookupInfo(2),glyphs: int,lookups: int): OtPositionGraphEntryRead =
  case+ ot_lookup_extension_validate(b,h.span,h.action,h.count,ot_lookup_header_floor(h)) of
  | ~Some_vt(e) => GraphEntryRejected(e) | ~None_vt() => classify(b,h,glyphs,lookups)
implement ot_position_graph_entry(b,span,glyphs,lookups) = case+ ot_lookup_header_parse(b,span,OtPositioning()) of
  | ~LookupHeaderRejected(e) => GraphEntryRejected(e) | ~LookupHeaderAccepted(h) => checked(b,h,glyphs,lookups)
