#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_reader.sats"
staload "os/fs.sats"
staload "data_font/opentype/tables/opentype_coverage.sats"
staload "data_font/opentype/substitution/gsub_single_types.sats"
staload "data_font/opentype/substitution/gsub_sequence_types.sats"
staload "data_font/opentype/substitution/gsub_sequences.sats"
staload "data_font/opentype/substitution/gsub_sequence_work.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/layout/ot_layout_extension.sats"
staload "font/opentype/tables/opentype_fixture.sats"
staload "font/resources/font_fixture.sats"
staload "font/opentype/substitution/gsub_sequence_contracts.sats"
staload "data_font/sfnt/sfnt.sats"
staload "data_font/opentype/layout/ot_layout_header.sats"
staload "data_font/opentype/layout/ot_layout_lookups.sats"
fun view_glyphs {n:nat} .<n>. (n: int(n),b: !Buf,v: GsubSequenceView,oracle: !Buf,at: int,i: int): int =
  if n = 0 then 0 else let
    val expected=ot_fixture_read16(oracle,iadd(at,imul(i,2)))
    val actual=gsub_sequence_glyph(b,v,i)
  in iadd(if ieq(expected,actual) then 0 else 1,view_glyphs(n-1,b,v,oracle,at,iadd(i,1))) end
fun payload{kind:int}(b: !Buf,s: OtSpan,glyphs: int,domain: GsubSequenceDomain(kind),
  oracle: !Buf,at: int,input: int,count: int): int = case+ gsub_sequences_parse(b,s,glyphs,domain) of
  | ~SequencesRejected(e) => 1 | ~SequencesAccepted(t) => let
    val v=gsub_sequences_query(b,t,input)
    val errors: int=if not(v.matched) orelse ine(v.count,count) then 1
      else view_glyphs(airlock_nat(count),b,v,oracle,at,0)
    val ()=gsub_sequences_dispose(t)
  in errors end
fun payload_of(b: !Buf,s: OtSpan,glyphs: int,raw: int,oracle: !Buf,at: int,input: int,count: int): int = case+ raw of
  | 2 => payload(b,s,glyphs,GsubMultiple(),oracle,at,input,count)
  | 3 => payload(b,s,glyphs,GsubAlternate(),oracle,at,input,count) | _ => 1
fun lookup(b: !Buf,info: OtLayoutInfo,glyphs: int,oracle: !Buf,at: int): int = let
  val index=ot_fixture_read16(oracle,iadd(at,2))
  val raw=ot_fixture_read16(oracle,at)
  val input=ot_fixture_read16(oracle,iadd(at,4))
  val count=ot_fixture_read16(oracle,iadd(at,6))
in if ige(index,info.lookupCount) then 1 else let val child=ot_lookup_span(b,info,index) in
  case+ child.kind of
  | ChildMissing() => 1 | ChildInvalid() => 1 | ChildPresent() => let val s=child.span in
    if ilt(s.length,8) orelse ine(ot_u16(b,s,0),raw) orelse ine(ot_u16(b,s,4),1) then 1 else let
      val target=ot_optional_child(s,ot_u16(b,s,6),8)
    in case+ target.kind of
      | ChildMissing() => 1 | ChildInvalid() => 1
      | ChildPresent() => payload_of(b,target.span,glyphs,raw,oracle,iadd(at,8),input,count) end end end end
fun rows {n:nat} .<n>. (n: int(n),b: !Buf,info: OtLayoutInfo,glyphs: int,oracle: !Buf,at: int): int =
  if n = 0 then 0 else let
    val count=ot_fixture_read16(oracle,iadd(at,6))
    val errors=lookup(b,info,glyphs,oracle,at)
  in errors+rows(n-1,b,info,glyphs,oracle,iadd(at,iadd(8,imul(count,2)))) end
fun reference(b: !Buf,info: OtLayoutInfo,glyphs: int): int = let
  val oracle=ot_fixture_words("0007 0003 0001 008C 0002 00A0 0084 0002 000F 0266 0002 000E 0141 0002 0010 02EA 0002 003C 0137 0002 0017 000E 0001 0013 0002 0018 000E 0001 0010 0002 0019 0008 0001 0009 0002 001C 02D9 0001 0030")
  val errors=rows(7,b,info,glyphs,oracle,2)
  val ()=buf_free(oracle)
in errors end
fun gsub(b: !Buf,info: SfntInfo): int = case+ sfnt_table(b,info.tables,TableGsub()) of
  | NoSfntTable() => 1 | HasSfntTable(s) => case+ ot_layout_header_parse(b,s) of
    | ~HeaderRejected(e) => 1 | ~HeaderAccepted(h) =>
      if not(ot_rows_fit(h.lookups,2,h.lookupCount,2)) then 1 else reference(b,h,info.glyphs)
fun face(face: !SfntFace): int = let val+ SfntFace(b,info)=face in gsub(b,info) end
implement sequence_test_fonts(path) = case+ sfnt_open(path) of
  | ~RejectedSfnt(e) => 1 | ~LoadedSfnt(f) => let
    val errors=face(f) val ()=sfnt_dispose(f)
  in errors end
