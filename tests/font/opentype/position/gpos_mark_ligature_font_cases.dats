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
staload "data_font/opentype/position/gpos_anchor_cache_types.sats"
staload "data_font/opentype/position/gpos_anchor_cache.sats"
staload "data_font/opentype/position/gpos_mark_shared_types.sats"
staload "data_font/opentype/position/gpos_mark_shared.sats"
staload "data_font/opentype/position/gpos_mark_ligature_types.sats"
staload "data_font/opentype/position/gpos_mark_ligature.sats"
staload "font/opentype/tables/opentype_fixture.sats"
staload "font/opentype/position/gpos_mark_ligature_contracts.sats"
staload "os/fs.sats"
staload "data_font/sfnt/sfnt.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/layout/ot_layout_header.sats"
staload "data_font/opentype/layout/ot_layout_lookups.sats"
datatype TestFace = LatinLigatureMarks | ArabicLigatureMarks
fun signed16(raw: int): int = if ige(raw,WORD16_SIGN_BIT) then isub(raw,WORD16_MODULUS) else raw
fun sample(b: !Buf,t: !GposMarkLigature,oracle: !Buf,at: int): int = let
  val r=gpos_mark_ligature_query(b,t,ot_fixture_read16(oracle,iadd(at,2)),
    ot_fixture_read16(oracle,iadd(at,4)),ot_fixture_read16(oracle,iadd(at,6)))
  val ok=r.matched andalso ieq(r.markClass,ot_fixture_read16(oracle,iadd(at,8))) andalso
    ieq(r.components,ot_fixture_read16(oracle,iadd(at,10))) andalso
    ieq(r.mark.anchor.x,signed16(ot_fixture_read16(oracle,iadd(at,12)))) andalso
    ieq(r.mark.anchor.y,signed16(ot_fixture_read16(oracle,iadd(at,14)))) andalso
    ieq(r.target.anchor.x,signed16(ot_fixture_read16(oracle,iadd(at,16)))) andalso
    ieq(r.target.anchor.y,signed16(ot_fixture_read16(oracle,iadd(at,18))))
in if ok then 0 else 1 end
fun payload(b: !Buf,s: OtSpan,glyphs: int,oracle: !Buf,at: int): int = case+ gpos_mark_ligature_parse(b,s,glyphs) of
  | ~MarkLigatureRejected(e) => 1 | ~MarkLigatureAccepted(t) => let
    val errors=sample(b,t,oracle,at) val ()=gpos_mark_ligature_dispose(t) in errors end
fun lookup(b: !Buf,h: OtLayoutInfo,glyphs: int,oracle: !Buf,at: int): int = let
  val root=ot_lookup_span(b,h,ot_fixture_read16(oracle,at))
in case+ root.kind of | ChildMissing() => 1 | ChildInvalid() => 1 | ChildPresent() => let
    val child=ot_optional_child(root.span,ot_u16(b,root.span,6),8)
  in if ine(ot_u16(b,root.span,0),5) orelse ine(ot_u16(b,root.span,4),1) then 1 else
    case+ child.kind of | ChildMissing() => 1 | ChildInvalid() => 1
    | ChildPresent() => payload(b,child.span,glyphs,oracle,at) end end
fun rows {n:nat} .<n>. (n: int(n),b: !Buf,h: OtLayoutInfo,glyphs: int,oracle: !Buf,at: int): int =
  if n = 0 then 0 else iadd(lookup(b,h,glyphs,oracle,at),rows(n-1,b,h,glyphs,oracle,iadd(at,20)))
fun reference(b: !Buf,h: OtLayoutInfo,glyphs: int,which: TestFace): int = let
  val text=case+ which of
  | LatinLigatureMarks() => "0004 0002 047E 0CB0 0000 0000 0002 0268 0000 03E0 0050 0002 047E 0CB0 0001 0000 0002 0268 0000 037C 0048 0004 047C 0CB0 0000 0000 0002 025D 046A 039C 0668 0004 047C 0CB0 0001 0000 0002 025D 046A 0093 0735"
  | ArabicLigatureMarks() => "0004 0010 0150 00ED 0000 0000 0004 005D FFC7 041F FF9C 0010 0150 00ED 0001 0000 0004 005D FFC7 0342 FF9C 0011 0163 00ED 0000 0000 0004 006F 0351 041A 02D0 0011 0163 00ED 0001 0000 0004 006F 0351 031A 02CD"
  val oracle=ot_fixture_words(text)
  val errors=rows(4,b,h,glyphs,oracle,2)
  val ()=buf_free(oracle)
in errors end
fun face(f: !SfntFace,which: TestFace): int = let val+ SfntFace(b,info)=f in
  case+ sfnt_table(b,info.tables,TableGpos()) of
  | ~NoSfntTable() => 1 | ~HasSfntTable(s) => case+ ot_layout_header_parse(b,s) of
    | ~HeaderRejected(e) => 1 | ~HeaderAccepted(h) => reference(b,h,info.glyphs,which) end
fun loaded(path: string,which: TestFace): int = case+ sfnt_open(path) of
  | ~RejectedSfnt(e) => 1 | ~LoadedSfnt(f) => let val errors=face(f,which) val ()=sfnt_dispose(f) in errors end
implement mark_ligature_test_fonts(latin,arabic) =
  loaded(latin,LatinLigatureMarks())+loaded(arabic,ArabicLigatureMarks())
