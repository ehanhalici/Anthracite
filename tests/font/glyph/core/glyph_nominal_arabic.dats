#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "os/fs.sats"
staload "data_font/sfnt/sfnt.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/run/glyph_run.sats"
staload "data_font/glyph/core/glyph_nominal.sats"
staload "data_text/utf8/utf8.sats"
staload "data_text/unicode/unicode_db.sats"
staload "font/opentype/tables/opentype_fixture.sats"
staload "font/glyph/core/glyph_nominal_contracts.sats"
staload "data_font/opentype/substitution/gsub_sequence_types.sats"
staload "data_font/opentype/sequence_lookup/ot_sequence_lookup_types.sats"
staload "data_font/opentype/sequence_lookup/ot_sequence_lookup.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/core/glyph_metadata.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/glyph/pass/glyph_pass_sequence.sats"
staload "data_font/glyph/core/glyph_arabic.sats"
staload "data_text/unicode/unicode_property.sats"
staload "data_text/arabic/joining/arabic_join_types.sats"
staload "data_text/arabic/joining/arabic_join.sats"
staload "font/glyph/pass/glyph_pass_contracts.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/layout/ot_layout_parse.sats"
staload "data_font/opentype/layout/ot_layout_plan.sats"
staload "data_font/opentype/substitution_graph/ot_substitution_graph_types.sats"
staload "data_font/opentype/substitution_graph/ot_substitution_graph.sats"
staload "data_font/glyph/substitution/glyph_substitution_lookup_types.sats"
staload "data_font/glyph/substitution/glyph_substitution_engine.sats"
extern fun nominal_graph_failed(): OtSubstitutionGraph = "mac#anth_die_box"
fun graph_table(b: !Buf,span: OtSpan,m: !GlyphMetadata,glyphs: int): OtSubstitutionGraph =
  case+ ot_layout_parse(b,span,OtSubstitution(),glyph_metadata_capabilities(m)) of
  | ~LayoutRejected(e) => nominal_graph_failed() | ~LayoutAccepted(t) => let
    val result=ot_substitution_graph_parse(b,t,3,glyphs) val ()=ot_layout_dispose(t)
  in case+ result of | ~SubstitutionGraphRejected(e) => nominal_graph_failed() | ~SubstitutionGraphAccepted(g) => g end
fun graph(b: !Buf,info: SfntInfo,m: !GlyphMetadata): OtSubstitutionGraph =
  case+ sfnt_table(b,info.tables,TableGsub()) of | ~NoSfntTable() => nominal_graph_failed()
    | ~HasSfntTable(span) => graph_table(b,span,m,info.glyphs)
fun rows{n:nat} .<n>. (left: int(n),run: !GlyphRun(1),expected: !Buf,node: int,previous: int,i: int): int =
  if left = 0 then (if ieq(node,~1) then 0 else 1) else let
    val v=glyph_run_query(run,node) and at=imul(i,10)
    val mask: uint=if ilt(i,2) then 2147483649u else if ieq(i,2) then 2147483648u else 2147483652u
    val ok=ieq(v.core.glyph,ot_fixture_read16(expected,at)) andalso ieq(v.core.sourceStart,ot_fixture_read16(expected,at+2))
      andalso ieq(v.core.sourceEnd,ot_fixture_read16(expected,at+4)) andalso ieq(v.core.cluster,ot_fixture_read16(expected,at+6))
      andalso ieq(node,ot_fixture_read16(expected,at+8)) andalso g0uint_eq_uint(v.core.mask,mask)
      andalso ieq(v.core.scalar,if ieq(i,2) then 1614 else 1576) andalso ieq(v.links.previous,previous)
  in iadd(if ok then 0 else 1,rows(left-1,run,expected,v.links.next,node,iadd(i,1))) end
fun check(run: !GlyphRun(1),words: string): int = let val expected=ot_fixture_words(words)
  val errors=rows(5,run,expected,0,~1,0)
  val meta=glyph_run_meta(run)
  val ok=ieq(meta.live,5) andalso ieq(meta.used,5) andalso ieq(meta.sourceLength,6) andalso ieq(meta.tail,4)
  val ()=buf_free(expected)
in iadd(errors,if ok then 0 else 1) end
fun forms(b: !Buf,g: !OtSubstitutionGraph,m: !GlyphMetadata,run: GlyphRun(1),errors: &int >> _): GlyphRun(1) = let
  val run=pass_test_take(glyph_substitution_lookup(b,g,m,run,25,@{selection= @{kind=GlyphMasked(),mask=4u},alternate=1}),5,1,errors)
  val run=pass_test_take(glyph_substitution_lookup(b,g,m,run,23,@{selection= @{kind=GlyphMasked(),mask=1u},alternate=1}),5,1,errors)
in run end
implement nominal_test_arabic_run(face,db,text,joining,errors) = let
  val+ SfntFace(b,info)=face
  val m=nominal_test_metadata(b,info) and mask=nominal_test_mask()
  val g=graph(b,info,m)
  val run=glyph_arabic_prepare(joining,mask,@{before=BoundaryNone(),after=BoundaryNone()},nominal_test_run(face,db,text))
  val run=pass_test_take(glyph_substitution_lookup(b,g,m,run,15,@{selection= @{kind=GlyphAll(),mask=0u},alternate=1}),3,2,errors)
  val ()=errors := errors+check(run,"000E 0000 0002 0000 0000 0141 0000 0002 0000 0003 017A 0002 0004 0000 0001 000E 0004 0006 0004 0002 0141 0004 0006 0004 0004")
  val run=forms(b,g,m,run,errors)
  val ()=errors := errors+check(run,"0013 0000 0002 0000 0000 0141 0000 0002 0000 0003 017A 0002 0004 0000 0001 000F 0004 0006 0004 0002 0141 0004 0006 0004 0004")
  val ()=ot_substitution_graph_dispose(g) and ()=glyph_metadata_dispose(m) and ()=arabic_mask_dispose(mask)
in run end
implement nominal_test_arabic(face,db,joining) = let
  val b=nominal_test_bytes("بَب") val text=nominal_test_decode(b)
  var errors: int=0
  val run=nominal_test_arabic_run(face,db,text,joining,errors)
  val ()=glyph_run_dispose(run) and ()=scalar_dispose(text) and ()=buf_free(b)
in errors end
