#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/gpos_value_types.sats"
staload "data_font/gpos_values.sats"
staload "data_font/gpos_anchor_cache_types.sats"
staload "data_font/gpos_anchor_cache.sats"
staload "data_font/gpos_mark_matrix_types.sats"
staload "data_font/gpos_mark_matrix.sats"
staload "opentype_fixture.sats"
staload "gpos_mark_matrix_contracts.sats"
staload "os/fs.sats"
staload "data_font/sfnt.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/ot_layout_header.sats"
staload "data_font/ot_layout_lookups.sats"
datatype TestFace = LatinMarks | ArabicMarks
fun signed16(raw: int): int = if ige(raw,32768) then isub(raw,65536) else raw
fun sample {kind:int}(b: !Buf,t: !GposMarkMatrix(kind),oracle: !Buf,at: int): int = let
  val r=gpos_mark_matrix_query(b,t,ot_fixture_read16(oracle,iadd(at,4)),ot_fixture_read16(oracle,iadd(at,6)))
  val ok=r.matched andalso ieq(r.markClass,ot_fixture_read16(oracle,iadd(at,8))) andalso
    ieq(r.mark.anchor.x,signed16(ot_fixture_read16(oracle,iadd(at,10)))) andalso
    ieq(r.mark.anchor.y,signed16(ot_fixture_read16(oracle,iadd(at,12)))) andalso
    ieq(r.target.anchor.x,signed16(ot_fixture_read16(oracle,iadd(at,14)))) andalso
    ieq(r.target.anchor.y,signed16(ot_fixture_read16(oracle,iadd(at,16))))
in if ok then 0 else 1 end
fun payload {kind:int}(b: !Buf,s: OtSpan,glyphs: int,domain: GposMarkMatrixDomain(kind),oracle: !Buf,at: int): int =
  case+ gpos_mark_matrix_parse(b,s,glyphs,domain) of
  | ~MarkMatrixRejected(e) => 1 | ~MarkMatrixAccepted(t) => let
    val errors=sample(b,t,oracle,at) val ()=gpos_mark_matrix_dispose(t) in errors end
fun payload_of(b: !Buf,s: OtSpan,glyphs: int,kind: int,oracle: !Buf,at: int): int = case+ kind of
  | 4 => payload(b,s,glyphs,MarkToBase(),oracle,at)
  | 6 => payload(b,s,glyphs,MarkToMark(),oracle,at) | _ => 1
fun lookup(b: !Buf,h: OtLayoutInfo,glyphs: int,oracle: !Buf,at: int): int = let
  val root=ot_lookup_span(b,h,ot_fixture_read16(oracle,at))
  val kind=ot_fixture_read16(oracle,iadd(at,2))
in case+ root.kind of | ChildMissing() => 1 | ChildInvalid() => 1 | ChildPresent() => let
    val child=ot_optional_child(root.span,ot_u16(b,root.span,6),8)
  in if ine(ot_u16(b,root.span,0),kind) orelse ine(ot_u16(b,root.span,4),1) then 1 else
    case+ child.kind of | ChildMissing() => 1 | ChildInvalid() => 1
    | ChildPresent() => payload_of(b,child.span,glyphs,kind,oracle,at) end end
fun rows {n:nat} .<n>. (n: int(n),b: !Buf,h: OtLayoutInfo,glyphs: int,oracle: !Buf,at: int): int =
  if n = 0 then 0 else iadd(lookup(b,h,glyphs,oracle,at),rows(n-1,b,h,glyphs,oracle,iadd(at,18)))
fun reference(b: !Buf,h: OtLayoutInfo,glyphs: int,which: TestFace): int = let
  val text=case+ which of
  | LatinMarks() => "0004 0000 0006 0481 0486 0000 0268 0000 0270 FDE4 0003 0004 047E 0457 0000 0268 0000 0258 0000 0005 0004 047C 0457 0000 025D 046A 0298 0484 0008 0004 04D0 04B3 0001 FFF7 0474 04D1 04A0"
  | ArabicMarks() => "0006 0000 0004 016E 001C 0000 0071 0181 00E5 FFE7 0003 0004 0141 0008 0000 0046 0000 007F FFB5 0005 0004 01E7 00BF 0000 0000 0000 01F3 00DC 0008 0004 015F 0008 0000 009A 013C 0080 0161 0012 0006 0150 0141 0000 005D FFC7 0047 FF30 0017 0006 011E 011E 0000 004A 02B7 0048 03A1"
  val oracle=ot_fixture_words(text)
  val errors=rows(airlock_nat(ot_fixture_read16(oracle,0)),b,h,glyphs,oracle,2)
  val ()=buf_free(oracle)
in errors end
fun face(f: !SfntFace,which: TestFace): int = let val+ SfntFace(b,info)=f in
  case+ sfnt_table(b,info.tables,TableGpos()) of
  | NoSfntTable() => 1 | HasSfntTable(s) => case+ ot_layout_header_parse(b,s) of
    | ~HeaderRejected(e) => 1 | ~HeaderAccepted(h) => reference(b,h,info.glyphs,which) end
fun loaded(path: string,which: TestFace): int = case+ sfnt_open(path) of
  | ~RejectedSfnt(e) => 1 | ~LoadedSfnt(f) => let val errors=face(f,which) val ()=sfnt_dispose(f) in errors end
implement mark_matrix_test_fonts(latin,arabic) = loaded(latin,LatinMarks())+loaded(arabic,ArabicMarks())
