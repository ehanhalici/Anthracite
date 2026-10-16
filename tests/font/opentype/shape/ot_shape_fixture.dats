#include "font/opentype/shape/ot_shape_test.hats"
extern fun shape_test_failed(): OtShapeSchedule(1) = "mac#anth_die_box"
fun append_words(b: &Buf >> Buf,words: string): void = let val child=ot_fixture_words(words)
  val ()=buf_append_at(b,child,8,isub(buf_len(child),8)) in buf_free(child) end
fun lookup(b: &Buf >> Buf,words: string,index: int): void = let val relative=isub(buf_len(b),108)
  val ()=ot_fixture_put16(b,iadd(102,imul(index,2)),relative)
in append_words(b,words) end
implement shape_test_fixture(required,last) = let
  var b: Buf=ot_fixture_words("0001 0000 000A 0026 0064 0001 6172 6162 0008 0004 0000 0000 FFFF 0005 0000 0001 0002 0003 0004 0005 6363 6D70 0020 696E 6974 0026 6973 6F6C 002C 726C 6967 0032 7274 6C6D 0038 0000 0001 0000 0000 0001 0001 0000 0001 0001 0000 0001 0002 0000 0001 0000 0003 0000 0000 0000")
  val ()=ot_fixture_put16(b,24,required)
  val ()=lookup(b,"0001 0000 0001 0008 0001 0006 0001 0001 0001 0005",0)
  val ()=lookup(b,"0001 0000 0001 0008 0001 0006 0001 0001 0001 0006",1)
  val ()=lookup(b,last,2)
in b end
implement shape_test_masks() = @{initial=1u,medial=2u,final=4u,isolated=8u,mirror=16u}
implement shape_test_request() = @{profile=ShapeArabicHorizontal(),script= @{code=1634885986},
  language=ShapeDefaultLanguage(),direction=ShapeRTL()}
implement shape_test_schedule(b,m,required) = case+ ot_layout_parse(b,ot_fixture_span(b),OtSubstitution(),glyph_metadata_capabilities(m)) of
  | ~LayoutRejected(e) => let val ()=println!("event=shape_fixture status=layout_rejected offset=",e.offset)
    in shape_test_failed() end | ~LayoutAccepted(t) => let
    val result=ot_shape_schedule_parse(b,t,OtSubstitution(),shape_test_request(),shape_test_masks(),3,128)
    val ()=ot_layout_dispose(t)
  in case+ result of | ~ShapeRejected(e) => let val ()=println!("event=shape_fixture status=schedule_rejected offset=",e.offset)
    in shape_test_failed() end | ~ShapeAccepted(s) => s end
implement shape_test_run(errors) = let
  val r=ligation_test_run("0005 0005 0005",errors) val+ GlyphRun(phase,meta,storage)=r
  val ()=glyph_storage_set_core(storage,0,glyph_run_new_mask(glyph_storage_core(storage,0),8u))
  val ()=glyph_storage_set_core(storage,1,glyph_run_new_mask(glyph_storage_core(storage,1),1u))
  val ()=glyph_storage_set_core(storage,2,glyph_run_new_mask(glyph_storage_core(storage,2),2u))
in r end
