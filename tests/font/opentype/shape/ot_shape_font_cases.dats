#include "font/opentype/shape/ot_shape_test.hats"
staload "data_font/glyph/core/glyph_arabic.sats"
staload "data_text/arabic/joining/arabic_join.sats"
staload "data_text/arabic/joining/arabic_join_types.sats"
staload "data_text/utf8/utf8.sats"
extern fun shape_font_table_failed(): OtLayoutTable(1,0) = "mac#anth_die_box"
fun table(b: !Buf,info: SfntInfo,m: !GlyphMetadata): OtLayoutTable(1,0) =
  case+ sfnt_table(b,info.tables,TableGsub()) of | NoSfntTable() => shape_font_table_failed()
  | HasSfntTable(span) => (case+ ot_layout_parse(b,span,OtSubstitution(),glyph_metadata_capabilities(m)) of
    | ~LayoutRejected(e) => shape_font_table_failed() | ~LayoutAccepted(t) => t)
fun rows{n:nat} .<n>. (left: int(n),r: !GlyphRun(1),o: !Buf,node: int,index: int,acc: int): int =
  if left = 0 then iadd(acc,if ieq(node,~1) then 0 else 1) else let val row=glyph_run_query(r,node)
    val ok=ieq(row.core.glyph,ot_fixture_read16(o,imul(index,2)))
  in rows(left-1,r,o,row.links.next,iadd(index,1),iadd(acc,if ok then 0 else 1)) end
fun example(face: !SfntFace,db: !UnicodeDb,joining: !PropertyMap(3),m: !GlyphMetadata,g: !OtSubstitutionGraph,
  s: !OtShapeSchedule(1),text: string,words: string): int = let
  val bytes=nominal_test_bytes(text) val decoded=nominal_test_decode(bytes) val masks=nominal_test_mask()
  val source=glyph_arabic_prepare(joining,masks,@{before=BoundaryNone(),after=BoundaryNone()},nominal_test_run(face,db,decoded))
  val+ SfntFace(b,info)=face
  val+ ~SubStageResult(r,status,applied,matches)=glyph_substitution_schedule_apply(b,g,s,m,source)
  val expected=ot_fixture_words(words) val meta=glyph_run_meta(r)
  val ready=case+ status of | GlyphPassApplied() => true | GlyphPassDomain() => false
    | GlyphPassReference() => false | GlyphPassCapacity() => false
  val errors=if ready andalso ieq(meta.live,idiv(isub(buf_len(expected),8),2))
    then rows(airlock_nat(meta.live),r,expected,meta.head,0,0) else 1
  val ()=glyph_run_dispose(r) and ()=buf_free(expected) and ()=arabic_mask_dispose(masks)
  val ()=scalar_dispose(decoded) and ()=buf_free(bytes)
in errors end
fun scheduled(face: !SfntFace,db: !UnicodeDb,joining: !PropertyMap(3),m: !GlyphMetadata,g: !OtSubstitutionGraph,
  s: OtShapeSchedule(1)): int = let
  val errors=example(face,db,joining,m,g,s,"بَب","0013 0141 017A 000F 0141")
    +example(face,db,joining,m,g,s,"سلام","0023 0045 000B 0048")
    +example(face,db,joining,m,g,s,"الله","0008 0046 0044 0051")
  val ()=ot_shape_schedule_dispose(s)
in errors end
fun graph(face: !SfntFace,db: !UnicodeDb,joining: !PropertyMap(3),m: !GlyphMetadata,
  t: !OtLayoutTable(1,0),s: OtShapeSchedule(1)): int = let val+ SfntFace(b,info)=face
in case+ ot_substitution_graph_parse(b,t,3,info.glyphs) of
  | ~SubstitutionGraphRejected(e) => let val ()=ot_shape_schedule_dispose(s) in 1 end
  | ~SubstitutionGraphAccepted(g) => let val errors=scheduled(face,db,joining,m,g,s)
    val ()=ot_substitution_graph_dispose(g) in errors end end
implement shape_test_font(face,db,joining) = let
  val+ SfntFace(b,info)=face val m=nominal_test_metadata(b,info) val t=table(b,info,m)
  val errors=case+ ot_shape_schedule_parse(b,t,OtSubstitution(),shape_test_request(),shape_test_masks(),3,info.glyphs) of
    | ~ShapeRejected(e) => 1 | ~ShapeAccepted(s) => graph(face,db,joining,m,t,s)
  val ()=ot_layout_dispose(t) and ()=glyph_metadata_dispose(m)
in errors end
