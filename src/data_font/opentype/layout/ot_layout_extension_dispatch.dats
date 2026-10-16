#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/layout/ot_layout_extension.sats"
implement ot_lookup_extension_validate(b,s,action,count,floor) = case+ action of
  | SubExtension() => ot_extension_lookup_validate(b,s,OtSubstitution(),count,floor)
  | PosExtension() => ot_extension_lookup_validate(b,s,OtPositioning(),count,floor)
  | SubSingle() => None_vt() | SubMultiple() => None_vt() | SubAlternate() => None_vt()
  | SubLigature() => None_vt() | SubContext() => None_vt() | SubChained() => None_vt()
  | SubReverse() => None_vt() | PosSingle() => None_vt() | PosPair() => None_vt()
  | PosCursive() => None_vt() | PosMarkBase() => None_vt() | PosMarkLigature() => None_vt()
  | PosMarkMark() => None_vt() | PosContext() => None_vt() | PosChained() => None_vt()
