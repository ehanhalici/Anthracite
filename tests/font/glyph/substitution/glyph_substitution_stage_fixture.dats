#include "font/glyph/substitution/glyph_substitution_stage_test.hats"
extern fun substitution_stage_failed(): GlyphSubstitutionStage = "mac#anth_die_box"
fun append(b: &Buf >> Buf,words: string,index: int): void = let
  val child=ot_fixture_words(words) val offset=isub(buf_len(b),8)
  val ()=ot_fixture_put16(b,iadd(50,imul(index,2)),isub(offset,48))
  val ()=buf_append_at(b,child,8,isub(buf_len(child),8))
in buf_free(child) end
implement substitution_stage_fixture(last) = let
  var b: Buf=ot_fixture_words("0001 0000 000A 001E 0030 0001 6172 6162 0008 0004 0000 0000 FFFF 0001 0000 0001 6363 6D70 0008 0000 0003 0000 0001 0002 0003 0000 0000 0000")
  val ()=append(b,"0001 0000 0001 0008 0001 0006 0001 0001 0001 0005",0)
  val ()=append(b,"0001 0000 0001 0008 0001 0006 0001 0001 0001 0006",1)
  val ()=append(b,last,2)
in b end
fun planned(b: !Buf,t: !OtLayoutTable(1,0),m: !GlyphMetadata,set: !OtFeatureSet): GlyphSubstitutionStage = let
  val language=ot_language_default(b,ot_script_select(b,ot_layout_info(t),@{code=1634885986}))
in case+ ot_stage_plan(b,t,language,set) of | ~PlanRejected(e) => substitution_stage_failed()
  | ~PlanAccepted(p) => let
    val result=glyph_substitution_stage_parse(b,t,p,m,@{selection= @{kind=GlyphAll(),mask=0u},alternate=1})
    val ()=ot_plan_dispose(p)
  in case+ result of | ~SubStageRejected(e) => substitution_stage_failed() | ~SubStageAccepted(stage) => stage end end
fun selected(b: !Buf,t: !OtLayoutTable(1,0),m: !GlyphMetadata,features: string): GlyphSubstitutionStage =
  case+ ot_feature_set_parse(nominal_test_bytes(features)) of | ~FeatureSetRejected(e) => substitution_stage_failed()
  | ~FeatureSetAccepted(set) => let val stage=planned(b,t,m,set)
    val ()=ot_feature_set_dispose(set)
  in stage end
implement substitution_stage_build(b,m,features) =
  case+ ot_layout_parse(b,ot_fixture_span(b),OtSubstitution(),glyph_metadata_capabilities(m)) of
  | ~LayoutRejected(e) => substitution_stage_failed() | ~LayoutAccepted(t) => let
    val stage=selected(b,t,m,features) val ()=ot_layout_dispose(t)
  in stage end
