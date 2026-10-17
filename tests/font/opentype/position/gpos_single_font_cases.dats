#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_reader.sats"
staload "data_font/opentype/position/gpos_value_types.sats"
staload "data_font/opentype/position/gpos_values.sats"
staload "font/opentype/tables/opentype_fixture.sats"
staload "font/opentype/position/gpos_value_contracts.sats"
staload "data_font/opentype/position/gpos_single_types.sats"
staload "data_font/opentype/position/gpos_single.sats"
staload "font/opentype/position/gpos_single_contracts.sats"
staload "os/fs.sats"
staload "data_font/sfnt/sfnt.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/layout/ot_layout_header.sats"
staload "data_font/opentype/layout/ot_layout_lookups.sats"
fun sample(b: !Buf,t: !GposSingle,gid: int): int = let
  val r=gpos_single_query(b,t,gid)
in if r.matched andalso ieq(r.value.units.xAdvance,~1233) andalso ieq(r.value.units.xPlace,0)
  andalso ieq(r.value.units.yPlace,0) andalso ieq(r.value.units.yAdvance,0) then 0 else 1 end
fun payload(b: !Buf,s: OtSpan,glyphs: int,a: int,c: int,d: int): int =
  case+ gpos_single_parse(b,s,glyphs) of
  | ~PositionSingleRejected(e) => 1 | ~PositionSingleAccepted(t) => let
    val errors=sample(b,t,a)+sample(b,t,c)+sample(b,t,d)
    val ()=gpos_single_dispose(t)
  in errors end
fun lookup(b: !Buf,h: OtLayoutInfo,glyphs: int,index: int,a: int,c: int,d: int): int = let
  val root=ot_lookup_span(b,h,index)
in case+ root.kind of
  | ChildMissing() => 1 | ChildInvalid() => 1 | ChildPresent() => let
    val s=root.span
    val child=ot_optional_child(s,ot_u16(b,s,6),8)
  in if ine(ot_u16(b,s,0),1) orelse ine(ot_u16(b,s,4),1) then 1 else case+ child.kind of
    | ChildMissing() => 1 | ChildInvalid() => 1 | ChildPresent() => payload(b,child.span,glyphs,a,c,d) end end
fun face(f: !SfntFace): int = let val+ SfntFace(b,info)=f in
  case+ sfnt_table(b,info.tables,TableGpos()) of
  | NoSfntTable() => 1 | HasSfntTable(s) => case+ ot_layout_header_parse(b,s) of
    | ~HeaderRejected(e) => 1 | ~HeaderAccepted(h) =>
      lookup(b,h,info.glyphs,7,648,649,712)+lookup(b,h,info.glyphs,9,1232,1235,1248) end
implement gpos_single_test_font(path) = case+ sfnt_open(path) of
  | ~RejectedSfnt(e) => 1 | ~LoadedSfnt(f) => let val errors=face(f) val ()=sfnt_dispose(f) in errors end
