#include "font/glyph/core/glyph_reverse_test.hats"
fun cascade(b: !Buf,t: !OtReverseLookup,m: !GlyphMetadata): int = let
  var errors: int=0
  val+ ~GlyphPassResult(r,status,visited,matches)=glyph_pass_reverse(b,t,m,reverse_pass_run(4,errors),@{kind=GlyphAll(),mask=0u})
  val a=glyph_run_query(r,0) and c=glyph_run_query(r,2) and last=glyph_run_query(r,3)
  val ok=reverse_pass_ready(status) andalso ieq(visited,4) andalso ieq(matches,3)
    andalso ieq(a.core.glyph,11) andalso ieq(c.core.glyph,11) andalso ieq(last.core.glyph,11)
    andalso ieq(a.core.sourceStart,0) andalso ieq(a.core.sourceEnd,1) andalso ieq(c.core.cluster,2)
  val ()=glyph_run_dispose(r)
in iadd(errors,if ok then 0 else 1) end
fun empty(b: !Buf,t: !OtReverseLookup,m: !GlyphMetadata): int = let
  var errors: int=0
  val+ ~GlyphPassResult(r,status,visited,matches)=glyph_pass_reverse(b,t,m,reverse_pass_run(0,errors),@{kind=GlyphAll(),mask=0u})
  val ok=reverse_pass_ready(status) andalso ieq(visited,0) andalso ieq(matches,0)
  val ()=glyph_run_dispose(r)
in iadd(errors,if ok then 0 else 1) end
implement reverse_pass_basic() = let
  val mb=ligation_test_metadata_bytes() val m=ligation_test_metadata(mb)
  val b=reverse_pass_table() val t=reverse_pass_parse(b)
  val errors=cascade(b,t,m)+empty(b,t,m)
  val ()=ot_reverse_lookup_dispose(t) and ()=buf_free(b)
  val ()=glyph_metadata_dispose(m) and ()=buf_free(mb)
in errors end
