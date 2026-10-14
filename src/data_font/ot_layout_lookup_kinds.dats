#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/ot_layout_lookups.sats"

fun kinds_1(code: int): Option_vt(OtLookupKind(1)) = case+ code of
  | 1 => Some_vt(SubSingle()) | 2 => Some_vt(SubMultiple()) | 3 => Some_vt(SubAlternate())
  | 4 => Some_vt(SubLigature()) | 5 => Some_vt(SubContext()) | 6 => Some_vt(SubChained())
  | 7 => Some_vt(SubExtension()) | 8 => Some_vt(SubReverse())
  | _ => None_vt()

fun kinds_2(code: int): Option_vt(OtLookupKind(2)) = case+ code of
  | 1 => Some_vt(PosSingle()) | 2 => Some_vt(PosPair()) | 3 => Some_vt(PosCursive())
  | 4 => Some_vt(PosMarkBase()) | 5 => Some_vt(PosMarkLigature()) | 6 => Some_vt(PosMarkMark())
  | 7 => Some_vt(PosContext()) | 8 => Some_vt(PosChained()) | 9 => Some_vt(PosExtension())
  | _ => None_vt()

implement ot_lookup_kind_of(domain,code) = case+ domain of
  | OtSubstitution() => kinds_1(code) | OtPositioning() => kinds_2(code)
implement ot_lookup_kind_code(action) = case+ action of
  | SubSingle() => 1 | SubMultiple() => 2 | SubAlternate() => 3
  | SubLigature() => 4 | SubContext() => 5 | SubChained() => 6
  | SubExtension() => 7 | SubReverse() => 8
  | PosSingle() => 1 | PosPair() => 2 | PosCursive() => 3
  | PosMarkBase() => 4 | PosMarkLigature() => 5 | PosMarkMark() => 6
  | PosContext() => 7 | PosChained() => 8 | PosExtension() => 9
implement ot_lookup_span(b,info,index) = ot_optional_child(info.lookups,
  ot_u16(b,info.lookups,iadd(2,imul(index,2))),iadd(2,imul(info.lookupCount,2)))
implement ot_lookup_info(b,s,action,flags) = let val count=ot_u16(b,s,4) in
  @{span=s,action=action,flags=flags,count=count,
    markSet=if flags.useMarkSet then ot_u16(b,s,iadd(6,imul(count,2))) else 0} end
