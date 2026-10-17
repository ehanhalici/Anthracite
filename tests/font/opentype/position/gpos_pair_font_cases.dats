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
staload "data_font/opentype/position/gpos_value_cache_types.sats"
staload "data_font/opentype/position/gpos_value_cache.sats"
staload "data_font/opentype/position/gpos_pair_types.sats"
staload "data_font/opentype/position/gpos_pairs.sats"
staload "font/opentype/tables/opentype_fixture.sats"
staload "font/opentype/position/gpos_pair_contracts.sats"
staload "os/fs.sats"
staload "data_font/sfnt/sfnt.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/layout/ot_layout_header.sats"
staload "data_font/opentype/layout/ot_layout_lookups.sats"
fun sample(b: !Buf,t: !GposPairs,first: int,second: int,want: int): int = let
  val r=gpos_pair_query(b,t,first,second)
  val progress=case+ r.progress of | PairContinueSecond() => true | PairContinueFollowing() => false
in if r.matched andalso ieq(r.first.units.xAdvance,want) andalso
  ieq(r.second.units.xAdvance,0) andalso progress then 0 else 1 end
fun payload(b: !Buf,s: OtSpan,glyphs: int): int = case+ gpos_pair_parse(b,s,glyphs) of
  | ~PairRejected(e) => 1 | ~PairAccepted(t) => let
    val errors=sample(b,t,36,57,~131)+sample(b,t,55,82,~348)+sample(b,t,58,68,~131)+sample(b,t,36,36,57)
    val ()=gpos_pair_dispose(t)
  in errors end
fun lookup(b: !Buf,h: OtLayoutInfo,glyphs: int): int = let val root=ot_lookup_span(b,h,14) in
  case+ root.kind of | ChildMissing() => 1 | ChildInvalid() => 1 | ChildPresent() => let
    val s=root.span
    val child=ot_optional_child(s,ot_u16(b,s,6),8)
  in if ine(ot_u16(b,s,0),2) orelse ine(ot_u16(b,s,4),1) then 1 else case+ child.kind of
    | ChildMissing() => 1 | ChildInvalid() => 1 | ChildPresent() => payload(b,child.span,glyphs) end end
fun face(f: !SfntFace): int = let val+ SfntFace(b,info)=f in
  case+ sfnt_table(b,info.tables,TableGpos()) of
  | ~NoSfntTable() => 1 | ~HasSfntTable(s) => case+ ot_layout_header_parse(b,s) of
    | ~HeaderRejected(e) => 1 | ~HeaderAccepted(h) => lookup(b,h,info.glyphs) end
implement gpos_pair_test_font(path) = case+ sfnt_open(path) of
  | ~RejectedSfnt(e) => 1 | ~LoadedSfnt(f) => let val errors=face(f) val ()=sfnt_dispose(f) in errors end
