#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_reader.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/layout/ot_layout_header.sats"
staload "data_font/opentype/layout/ot_layout_features.sats"
staload "data_font/opentype/layout/ot_layout_language.sats"
staload "data_font/opentype/layout/ot_layout_lookups.sats"
staload "data_font/opentype/layout/ot_layout_parse.sats"
staload "data_font/opentype/layout/ot_layout_work.sats"

fun scripts{kind:int}(b: !Buf,info: OtLayoutInfo,remaining: &int >> _): OtLayoutRead(kind) =
  case+ ot_scripts_work(b,info,remaining) of
  | ~Some_vt(e) => LayoutRejected(e) | ~None_vt() => LayoutAccepted(OtLayoutStructure(info))
fun features{kind:int}(b: !Buf,info: OtLayoutInfo,remaining: &int >> _): OtLayoutRead(kind) =
  case+ ot_features_work(b,info,remaining) of
  | ~Some_vt(e) => LayoutRejected(e) | ~None_vt() => scripts(b,info,remaining)
fun structure{kind:int}(b: !Buf,info: OtLayoutInfo,domain: OtLayoutDomain(kind),caps: OtGdefCapabilities): OtLayoutRead(kind) = let
  var remaining: int=MAX_REC_FUEL
in case+ ot_lookups_work(b,info,domain,caps,remaining) of
  | ~Some_vt(e) => LayoutRejected(e) | ~None_vt() => features(b,info,remaining) end

implement ot_layout_parse(b,s,domain,caps) = case+ ot_layout_header_parse(b,s) of
  | ~HeaderRejected(e) => LayoutRejected(e)
  | ~HeaderAccepted(info) => structure(b,info,domain,caps)
implement ot_layout_info(table) = let val+ OtLayoutStructure(info)=table in info end
