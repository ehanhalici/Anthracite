#include "glyph_window_test.hats"
staload "data_font/glyph_run_storage.sats"
fun mask(run: !GlyphRun(1),node: int): void = let
  val+ GlyphRun(phase,meta,s)=run
  var core: GlyphCore=glyph_storage_core(s,node)
  val ()=core.mask := 2u
in glyph_storage_set_core(s,node,core) end
fun selected(b: !Buf,p: !OtContextProgram(1),mb: !Buf,m: !GlyphMetadata,r: !GlyphRun(1),expected: int): int = let
  var remaining: int=32
  val w=window_test_make(ot_context_limits(b,p))
  val o: GlyphWindowSelection= @{flags=ligation_test_flags(0),set=0,selection= @{kind=GlyphMasked(),mask=1u}}
  val span=window_test_gather(mb,m,r,o,2,w,remaining)
  val result=glyph_window_match(b,p,w,span)
  val ok=glyph_window_status_valid(span.status) andalso result.matched andalso ieq(result.inputCount,expected)
  val ()=glyph_window_dispose(w)
in if ok then 0 else 1 end
fun parse(b: !Buf,mb: !Buf,m: !GlyphMetadata,r: !GlyphRun(1),mode: OtContextMode,expected: int): int =
  case+ ot_context_parse(b,ot_fixture_span(b),128,3,OtSubstitution(),mode) of
  | ~ContextRejected(e) => 1 | ~ContextAccepted(p) => let
    val errors=selected(b,p,mb,m,r,expected) val ()=ot_context_dispose(p)
  in errors end
fun surroundings(mb: !Buf,m: !GlyphMetadata): int = let
  var errors: int=0
  val r=ligation_test_run("0001 0002 0005 0006 0007 0008",errors)
  val ()=mask(r,0) and ()=mask(r,1) and ()=mask(r,4) and ()=mask(r,5)
  val b=context_fixture(ChainCoverage())
  val e=parse(b,mb,m,r,ContextChained(),2)
  val ()=buf_free(b) and ()=glyph_run_dispose(r)
in iadd(errors,e) end
fun shorter(mb: !Buf,m: !GlyphMetadata): int = let
  var errors: int=0
  val r=ligation_test_run("0001 0002 0005 0006 0007 0008",errors)
  val ()=mask(r,3)
  val b=ot_fixture_words("0001 0008 0001 000E 0001 0001 0005 0002 0006 0010 0002 0001 0006 0000 0001 0001 0001 0000 0002")
  val e=parse(b,mb,m,r,ContextPlain(),1)
  val ()=buf_free(b)
  val look=ot_fixture_words("0003 0000 0001 000E 0001 0014 0000 0001 0001 0005 0001 0001 0006")
  val next=parse(look,mb,m,r,ContextChained(),1)
  val ()=buf_free(look) and ()=glyph_run_dispose(r)
in iadd(errors,iadd(e,next)) end
implement window_test_masks() = let val b=ligation_test_metadata_bytes() val m=ligation_test_metadata(b)
  val errors=surroundings(b,m)+shorter(b,m)
  val ()=glyph_metadata_dispose(m) and ()=buf_free(b)
in errors end
