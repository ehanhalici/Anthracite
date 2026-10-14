#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "os/fs.sats"
staload "data_font/opentype_coverage.sats"
staload "data_font/gsub_ligature_types.sats"
staload "data_font/gsub_ligatures.sats"
staload "opentype_fixture.sats"
staload "font_fixture.sats"
staload "gsub_ligature_contracts.sats"
staload "data_font/sfnt.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/ot_layout_header.sats"
staload "data_font/ot_layout_lookups.sats"
fun input {n:nat} .<n>. (n: int(n),v: !Buf,oracle: !Buf,at: int,i: int): void =
  if n = 0 then () else let val ()=buf_set32(v,i,ot_fixture_read16(oracle,iadd(at,imul(i,2)))) in
    input(n-1,v,oracle,at,iadd(i,1)) end
fun payload(b: !Buf,s: OtSpan,glyphs: int,oracle: !Buf,at: int): int =
  case+ gsub_ligatures_parse(b,s,glyphs) of
  | ~LigaturesRejected(e) => 1 | ~LigaturesAccepted(t) => let
    val size=ot_fixture_read16(oracle,iadd(at,4))
    val expected=ot_fixture_read16(oracle,iadd(at,2))
    val v=buf_make(imul(size,4))
    val ()=input(airlock_nat(size),v,oracle,iadd(at,6),0)
    val r=gsub_ligatures_match(b,t,v,size,0)
    val ok=r.matched andalso ieq(r.glyph,expected) andalso ieq(r.components,size)
    val ()=buf_free(v) and ()=gsub_ligatures_dispose(t)
  in if ok then 0 else 1 end
fun lookup(b: !Buf,info: OtLayoutInfo,glyphs: int,oracle: !Buf,at: int): int = let
  val index=ot_fixture_read16(oracle,at)
in if ige(index,info.lookupCount) then 1 else let val child=ot_lookup_span(b,info,index) in
  case+ child.kind of
  | ChildMissing() => 1 | ChildInvalid() => 1 | ChildPresent() => let val s=child.span in
    if ilt(s.length,8) orelse ine(ot_u16(b,s,0),4) orelse ine(ot_u16(b,s,4),1) then 1 else let
      val target=ot_optional_child(s,ot_u16(b,s,6),8)
    in case+ target.kind of
      | ChildMissing() => 1 | ChildInvalid() => 1
      | ChildPresent() => payload(b,target.span,glyphs,oracle,at) end end end end
fun rows {n:nat} .<n>. (n: int(n),b: !Buf,info: OtLayoutInfo,glyphs: int,oracle: !Buf,at: int): int =
  if n = 0 then 0 else let
    val size=ot_fixture_read16(oracle,iadd(at,4))
    val error=lookup(b,info,glyphs,oracle,at)
  in error+rows(n-1,b,info,glyphs,oracle,iadd(at,iadd(6,imul(size,2)))) end
fun reference(font: LigatureTestFont): Buf = case+ font of
  | LigatureLatin() => ot_fixture_words("0003 0006 0CB6 0002 0C9A 0C49 0007 0CB4 0002 0C9A 0C43 0008 0BE3 0002 0049 004F")
  | LigatureArabic() => ot_fixture_words("0004 0005 0175 0002 0174 017E 000D 0131 0002 006B 012F 0027 00ED 0005 0008 0046 0044 0176 0051 0028 00EE 0003 0046 0044 0051")
fun oracle(b: !Buf,info: OtLayoutInfo,glyphs: int,font: LigatureTestFont): int = let
  val o=reference(font)
  val errors=rows(airlock_nat(ot_fixture_read16(o,0)),b,info,glyphs,o,2)
  val ()=buf_free(o)
in errors end
fun gsub(b: !Buf,info: SfntInfo,font: LigatureTestFont): int = case+ sfnt_table(b,info.tables,TableGsub()) of
  | NoSfntTable() => 1 | HasSfntTable(s) => case+ ot_layout_header_parse(b,s) of
    | ~HeaderRejected(e) => 1 | ~HeaderAccepted(h) =>
      if not(ot_rows_fit(h.lookups,2,h.lookupCount,2)) then 1 else oracle(b,h,info.glyphs,font)
fun face(face: !SfntFace,font: LigatureTestFont): int = let val+ SfntFace(b,info)=face in gsub(b,info,font) end
implement ligature_test_font(path,font) = case+ sfnt_open(path) of
  | ~RejectedSfnt(e) => 1 | ~LoadedSfnt(f) => let
    val errors=face(f,font) val ()=sfnt_dispose(f)
  in errors end
