#include "glyph_window_test.hats"
fun allocation(limits: OtContextLimits): int = case+ glyph_window_make(limits) of
  | ~WindowRejected(status) => if glyph_window_status_valid(status) then 1 else 0
  | ~WindowAllocated(w) => let val ()=glyph_window_dispose(w) in 1 end
fun capacity(mb: !Buf,m: !GlyphMetadata): int = let
  var errors: int=0 and remaining: int=2
  val r=ligation_test_run("0005 000C 0006",errors)
  val w=window_test_make(@{back=0,input=2,look=0})
  val o: GlyphWindowSelection= @{flags=ligation_test_flags(8),set=0,selection= @{kind=GlyphAll(),mask=0u}}
  val rejected=window_test_gather(mb,m,r,o,0,w,remaining)
  val failed=case+ rejected.status of | WindowCapacity() => true | WindowReady() => false | WindowSkipped() => false
    | WindowDomain() => false | WindowReference() => false
  val ()=remaining := 3
  val accepted=window_test_gather(mb,m,r,o,0,w,remaining)
  val meta=glyph_run_meta(r)
  val good=failed andalso glyph_window_status_valid(accepted.status) andalso ieq(remaining,0)
    andalso ieq(glyph_window_node(w,accepted,1),2) andalso ieq(glyph_window_node(w,accepted,2147483647),~1)
    andalso ieq(meta.live,3)
  val ()=glyph_window_dispose(w) and ()=glyph_run_dispose(r)
in iadd(errors,if good then 0 else 1) end
fun malformed(b: !Buf,p: !OtContextProgram(1),w: !GlyphContextWindow): int = let
  val beyond: GlyphWindowSpan= @{status=WindowReady(),start=0,count=2147483647,input=2}
  val input: GlyphWindowSpan= @{status=WindowReady(),start=0,count=2,input=2147483647}
  val a=glyph_window_match(b,p,w,beyond) and c=glyph_window_match(b,p,w,input)
  val ok=not(a.matched) andalso not(c.matched) andalso ieq(glyph_window_node(w,beyond,0),~1)
    andalso ieq(glyph_window_node(w,input,0),~1)
in if ok then 0 else 1 end
fun spans(): int = let val b=context_fixture(PlainCoverage())
  val errors: int=case+ ot_context_parse(b,ot_fixture_span(b),128,3,OtSubstitution(),ContextPlain()) of
    | ~ContextRejected(e) => 1 | ~ContextAccepted(p) => let
      val w=window_test_make(@{back=0,input=2,look=0})
      val e=malformed(b,p,w)
      val ()=glyph_window_dispose(w) and ()=ot_context_dispose(p)
    in e end
  val ()=buf_free(b)
in errors end
implement window_test_rejections() = let val b=ligation_test_metadata_bytes() val m=ligation_test_metadata(b)
  val errors=capacity(b,m)+spans()+allocation(@{back=0,input=0,look=0})
    +allocation(@{back=2147483647,input=2147483647,look=2147483647})
  val ()=glyph_metadata_dispose(m) and ()=buf_free(b)
in errors end
