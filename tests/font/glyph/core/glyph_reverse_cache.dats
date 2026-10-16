#include "font/glyph/core/glyph_reverse_test.hats"
fun check(b: !Buf,m: !GlyphMetadata,expected: int): int = let
  val t=reverse_pass_parse(b) var errors: int=0
  val+ ~GlyphPassResult(r,status,visited,matches)=glyph_pass_reverse(b,t,m,reverse_pass_run(2,errors),@{kind=GlyphAll(),mask=0u})
  val first=glyph_run_query(r,0)
  val ok=reverse_pass_ready(status) andalso ieq(first.core.glyph,expected) andalso ieq(matches,1)
  val ()=glyph_run_dispose(r) and ()=ot_reverse_lookup_dispose(t)
in iadd(errors,if ok then 0 else 1) end
fun reject(b: !Buf): int = case+ ot_reverse_lookup_parse(b,ot_fixture_span(b),128) of
  | ~ReverseLookupRejected(e) => 0 | ~ReverseLookupAccepted(t) => let val ()=ot_reverse_lookup_dispose(t) in 1 end
fun priority(m: !GlyphMetadata): int = let
  val b=ot_fixture_words("0008 0000 0002 000A 0024 0001 000E 0000 0001 0014 0001 000A 0001 0001 000A 0001 0001 000B 0001 000E 0000 0001 0014 0001 000B 0001 0001 000A 0001 0001 000B")
  val errors=check(b,m,10)
  val ()=ot_fixture_put16(b,48,128)
  val invalid=reject(b) val ()=buf_free(b)
in errors+invalid end
fun extension(m: !GlyphMetadata): int = let
  val b=ot_fixture_words("0007 0000 0001 0008 0001 0008 0000 0008 0001 000E 0000 0001 0014 0001 000B 0001 0001 000A 0001 0001 000B")
  val errors=check(b,m,11)
  val ()=ot_fixture_put16(b,10,7)
  val invalid=reject(b) val ()=buf_free(b)
in errors+invalid end
implement reverse_pass_cache() = let
  val mb=ligation_test_metadata_bytes() val m=ligation_test_metadata(mb)
  val errors=priority(m)+extension(m)
  val ()=glyph_metadata_dispose(m) and ()=buf_free(mb)
in errors end
