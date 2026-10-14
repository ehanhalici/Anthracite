#include "glyph_reverse_test.hats"
fun rows{n:nat} .<n>. (left: int(n),run: !GlyphRun(1),node: int): int =
  if left = 0 then 0 else let val row=glyph_run_query(run,node)
    val error=if ieq(row.core.glyph,11) andalso ieq(row.core.sourceStart,node)
      andalso ieq(row.core.sourceEnd,iadd(node,1)) andalso ieq(row.core.cluster,node) then 0 else 1
  in iadd(error,rows(left-1,run,iadd(node,1))) end
implement reverse_pass_stress() = let
  val mb=ligation_test_metadata_bytes() val m=ligation_test_metadata(mb)
  val b=reverse_pass_table() val t=reverse_pass_parse(b) var errors: int=0
  val+ ~GlyphPassResult(r,status,visited,matches)=glyph_pass_reverse(b,t,m,reverse_pass_run(32768,errors),
    @{kind=GlyphAll(),mask=0u})
  val ok=reverse_pass_ready(status) andalso ieq(visited,32768) andalso ieq(matches,32767)
  val total=iadd(errors+rows(32768,r,0),if ok then 0 else 1)
  val ()=glyph_run_dispose(r) and ()=ot_reverse_lookup_dispose(t) and ()=buf_free(b)
  val ()=glyph_metadata_dispose(m) and ()=buf_free(mb)
in total end
