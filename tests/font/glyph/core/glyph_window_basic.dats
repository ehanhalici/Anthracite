#include "font/glyph/core/glyph_window_test.hats"
fun queried{kind:int}(b: !Buf,p: !OtContextProgram(kind),mb: !Buf,m: !GlyphMetadata,which: ContextFixture): int = let
  var errors: int=0 and remaining: int=32
  val r=ligation_test_run("0001 0002 0005 000C 0006 0007 0008",errors)
  val w=window_test_make(ot_context_limits(b,p))
  val o: GlyphWindowSelection= @{flags=ligation_test_flags(8),set=0,selection= @{kind=GlyphAll(),mask=0u}}
  val span=window_test_gather(mb,m,r,o,2,w,remaining)
  val result=glyph_window_match(b,p,w,span)
  val chained=case+ context_fixture_mode(which) of | ContextPlain() => false | ContextChained() => true
  val first=glyph_window_node(w,span,0) and second=glyph_window_node(w,span,1)
  val ok=glyph_window_status_valid(span.status) andalso result.matched andalso ieq(result.inputCount,2)
    andalso ieq(result.actionCount,2) andalso ieq(first,2) andalso ieq(second,4)
    andalso ieq(span.start,if chained then 2 else 0) andalso ieq(remaining,if chained then 25 else 29)
  val ()=glyph_window_dispose(w) and ()=glyph_run_dispose(r)
in iadd(errors,if ok then 0 else 1) end
fun parsed{kind:int}(b: !Buf,mb: !Buf,m: !GlyphMetadata,which: ContextFixture,domain: OtLayoutDomain(kind)): int =
  case+ ot_context_parse(b,ot_fixture_span(b),128,3,domain,context_fixture_mode(which)) of
  | ~ContextRejected(e) => 1 | ~ContextAccepted(p) => let
    val errors=queried(b,p,mb,m,which) val ()=ot_context_dispose(p)
  in errors end
fun check(mb: !Buf,m: !GlyphMetadata,which: ContextFixture): int = let val b=context_fixture(which)
  val errors=parsed(b,mb,m,which,OtSubstitution())+parsed(b,mb,m,which,OtPositioning())
  val ()=buf_free(b)
in errors end
implement window_test_basic() = let val b=ligation_test_metadata_bytes() val m=ligation_test_metadata(b)
  val errors=check(b,m,PlainGlyph())+check(b,m,PlainClass())+check(b,m,PlainCoverage())
    +check(b,m,ChainGlyph())+check(b,m,ChainClass())+check(b,m,ChainCoverage())
  val ()=glyph_metadata_dispose(m) and ()=buf_free(b)
in errors end
