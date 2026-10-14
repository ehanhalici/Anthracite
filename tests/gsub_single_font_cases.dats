#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/opentype_coverage.sats"
staload "data_font/gsub_single_types.sats"
staload "os/fs.sats"
staload "data_font/gsub_single.sats"
staload "opentype_fixture.sats"
staload "font_fixture.sats"
staload "gsub_single_contracts.sats"

staload "data_font/sfnt.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/ot_layout_header.sats"
staload "data_font/ot_layout_lookups.sats"
staload "data_font/opentype_lookup_flags.sats"
fun subtable(b: !Buf,s: OtSpan,flags: OtLookupFlags,glyphs: int,input: int,output: int): int = let
  val count=ot_u16(b,s,4)
  val floor=iadd(iadd(6,imul(count,2)),if flags.useMarkSet then 2 else 0)
in if ieq(count,0) orelse igt(floor,s.length) then 1 else let
    val child=ot_optional_child(s,ot_u16(b,s,6),floor)
  in case+ child.kind of
    | ChildMissing() => 1 | ChildInvalid() => 1
    | ChildPresent() => single_expect(b,child.span,glyphs,input,output) end end
fun lookup(b: !Buf,info: OtLayoutInfo,glyphs: int,index: int,input: int,output: int): int =
  if ilt(index,0) orelse ige(index,info.lookupCount) then 1 else let val child=ot_lookup_span(b,info,index) in
    case+ child.kind of
    | ChildMissing() => 1 | ChildInvalid() => 1 | ChildPresent() => let val s=child.span in
      if ilt(s.length,6) orelse ine(ot_u16(b,s,0),1) then 1 else case+ ot_lookup_flags_of(ot_u16(b,s,2)) of
      | ~FlagsRejected(e) => 1 | ~FlagsAccepted(f) => subtable(b,s,f,glyphs,input,output) end end
fun rows {n:nat} .<n>. (n: int(n),b: !Buf,info: OtLayoutInfo,glyphs: int,oracle: !Buf,i: int,total: int): int =
  if n = 0 then total else let
    val at=iadd(2,imul(i,6))
    val index=ot_fixture_read16(oracle,at)
    val input=ot_fixture_read16(oracle,iadd(at,2))
    val output=ot_fixture_read16(oracle,iadd(at,4))
    val error=lookup(b,info,glyphs,index,input,output)
  in rows(n-1,b,info,glyphs,oracle,iadd(i,1),iadd(total,error)) end
fun oracle(b: !Buf,info: OtLayoutInfo,glyphs: int,font: SingleTestFont): int = let
  val reference=single_font_oracle(font)
  val count=ot_fixture_read16(reference,0)
  val errors=rows(airlock_nat(count),b,info,glyphs,reference,0,0)
  val ()=buf_free(reference)
  val ()=println!("event=gsub_single_font oracle_rows=",count," oracle_errors=",errors)
in errors end
fun header(b: !Buf,s: OtSpan,glyphs: int,font: SingleTestFont): int =
  case+ ot_layout_header_parse(b,s) of
  | ~HeaderRejected(e) => 1 | ~HeaderAccepted(info) =>
    if not(ot_rows_fit(info.lookups,2,info.lookupCount,2)) then 1 else oracle(b,info,glyphs,font)
fun table(b: !Buf,info: SfntInfo,font: SingleTestFont): int = case+ sfnt_table(b,info.tables,TableGsub()) of
  | NoSfntTable() => 1 | HasSfntTable(s) => header(b,s,info.glyphs,font)
fun face(face: !SfntFace,font: SingleTestFont): int = let val+ SfntFace(b,info)=face in table(b,info,font) end
implement single_test_font(path,font) = case+ sfnt_open(path) of
  | ~RejectedSfnt(e) => 1 | ~LoadedSfnt(f) => let
    val errors=face(f,font) val ()=sfnt_dispose(f)
  in errors end
