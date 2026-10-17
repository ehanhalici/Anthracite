#include "font/glyph/core/glyph_window_test.hats"
fun prepared(errors: &int >> _): GlyphRun(1) = let
  val nodes=run_test_indices(0,2)
  val r=run_test_take(glyph_run_ligate(ligation_test_run("000A 000C 000B 000D",errors),nodes,2,14),run_test_updated,errors)
  val r=run_test_take(glyph_run_bind_mark(r,1,0,0),run_test_updated,errors)
  val r=run_test_take(glyph_run_bind_mark(r,3,0,1),run_test_updated,errors)
  val ()=buf_free(nodes)
in r end
fun look(mb: !Buf,m: !GlyphMetadata,r: !GlyphRun(1)): int = let
  val b=ot_fixture_words("0003 0000 0001 000E 0001 0014 0000 0001 0001 000C 0001 0001 000D")
  val errors: int=case+ ot_context_parse(b,ot_fixture_span(b),128,0,OtPositioning(),ContextChained()) of
    | ~ContextRejected(e) => 1 | ~ContextAccepted(p) => let
      var remaining: int=2
      val w=window_test_make(ot_context_limits(b,p))
      val o: GlyphWindowSelection= @{flags=ligation_test_flags(0),set=0,selection= @{kind=GlyphAll(),mask=0u}}
      val span=window_test_gather(mb,m,r,o,1,w,remaining)
      val result=glyph_window_match(b,p,w,span)
      val ok=glyph_window_status_valid(span.status) andalso result.matched andalso ieq(remaining,0)
        andalso ieq(span.input,1) andalso ieq(result.actionCount,0)
      val ()=glyph_window_dispose(w) and ()=ot_context_dispose(p)
    in if ok then 0 else 1 end
  val ()=buf_free(b)
in errors end
fun input(mb: !Buf,m: !GlyphMetadata,r: !GlyphRun(1)): int = let
  var remaining: int=16
  val w=window_test_make(@{back=0,input=2,look=0})
  val o: GlyphWindowSelection= @{flags=ligation_test_flags(0),set=0,selection= @{kind=GlyphAll(),mask=0u}}
  val span=window_test_gather(mb,m,r,o,1,w,remaining)
  val ok=glyph_window_status_valid(span.status) andalso ieq(span.input,1) andalso ieq(span.count,2)
    andalso ieq(glyph_window_node(w,span,1),~1)
  val ()=glyph_window_dispose(w)
in if ok then 0 else 1 end
implement window_test_associations() = let
  var errors: int=0
  val b=ligation_test_metadata_bytes() val m=ligation_test_metadata(b)
  val r=prepared(errors)
  val checked=look(b,m,r)+input(b,m,r)
  val ()=glyph_run_dispose(r) and ()=glyph_metadata_dispose(m) and ()=buf_free(b)
in iadd(errors,checked) end
