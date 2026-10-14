#include "glyph_reverse_test.hats"
fun budget(b: !Buf,t: !OtReverseLookup,m: !GlyphMetadata): int = let
  var errors: int=0 and remaining: int=5
  val+ ~GlyphPassResult(r,status,visited,matches)=glyph_pass_reverse_budget(b,t,m,reverse_pass_run(4,errors),
    @{kind=GlyphAll(),mask=0u},remaining)
  val a=glyph_run_query(r,0) and c=glyph_run_query(r,2)
  val limited=case+ status of | GlyphPassCapacity() => true | GlyphPassApplied() => false
    | GlyphPassDomain() => false | GlyphPassReference() => false
  val ok=limited andalso ieq(visited,0) andalso ieq(matches,0) andalso ieq(a.core.glyph,10) andalso ieq(c.core.glyph,10)
  val ()=glyph_run_dispose(r)
in iadd(errors,if ok then 0 else 1) end
extern fun foreign_run_failed(): GlyphRun(1) = "mac#anth_die_box"
fun foreign(errors: &int >> int): GlyphRun(1) = case+ glyph_run_make(4,128,1,1) of
  | ~GlyphRunRejected(e) => foreign_run_failed()
  | ~GlyphRunCreated(r) => glyph_run_substitute(run_test_take(glyph_run_append(r,
    @{glyph=10,scalar=97,sourceStart=0,sourceEnd=1,cluster=0,mask=1u}),run_test_updated,errors))
fun domain(b: !Buf,t: !OtReverseLookup,m: !GlyphMetadata): int = let var errors: int=0
  val run=foreign(errors)
  val+ ~GlyphPassResult(r,status,visited,matches)=glyph_pass_reverse(b,t,m,run,@{kind=GlyphAll(),mask=0u})
  val wrong=case+ status of | GlyphPassDomain() => true | GlyphPassApplied() => false
    | GlyphPassReference() => false | GlyphPassCapacity() => false
  val ()=glyph_run_dispose(r)
in iadd(errors,if wrong andalso ieq(visited,0) andalso ieq(matches,0) then 0 else 1) end
implement reverse_pass_rollback() = let
  val mb=ligation_test_metadata_bytes() val m=ligation_test_metadata(mb)
  val b=reverse_pass_table() val t=reverse_pass_parse(b)
  val errors=budget(b,t,m)+domain(b,t,m)
  val ()=ot_reverse_lookup_dispose(t) and ()=buf_free(b)
  val ()=glyph_metadata_dispose(m) and ()=buf_free(mb)
in errors end
