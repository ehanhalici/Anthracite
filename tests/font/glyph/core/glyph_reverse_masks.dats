#include "font/glyph/core/glyph_reverse_test.hats"
staload "data_font/glyph/run/glyph_run_storage.sats"
staload "data_font/glyph/run/glyph_run_work.sats"
fun mask(run: !GlyphRun(1),node: int): void = let
  val+ GlyphRun(phase,meta,s)=run
  val core=glyph_storage_core(s,node)
in glyph_storage_set_core(s,node,glyph_run_new_mask(core,0u)) end
fun masked(b: !Buf,t: !OtReverseLookup,m: !GlyphMetadata): int = let var errors: int=0
  val base=reverse_pass_run(2,errors)
  val ()=mask(base,1)
  val run=base
  val+ ~GlyphPassResult(r,status,visited,matches)=glyph_pass_reverse(b,t,m,run,@{kind=GlyphMasked(),mask=1u})
  val first=glyph_run_query(r,0)
  val ok=reverse_pass_ready(status) andalso ieq(matches,1) andalso ieq(first.core.glyph,11)
  val ()=glyph_run_dispose(r)
in iadd(errors,if ok then 0 else 1) end
fun marks(m: !GlyphMetadata): int = let var errors: int=0
  val b=reverse_pass_table() val ()=ot_fixture_put16(b,2,8) val t=reverse_pass_parse(b)
  val+ ~GlyphPassResult(r,status,visited,matches)=glyph_pass_reverse(b,t,m,ligation_test_run("000A 000C 000B",errors),
    @{kind=GlyphAll(),mask=0u})
  val first=glyph_run_query(r,0) and mark=glyph_run_query(r,1)
  val ok=reverse_pass_ready(status) andalso ieq(matches,1) andalso ieq(first.core.glyph,11)
    andalso ieq(mark.core.glyph,12) andalso ieq(mark.core.sourceStart,2)
  val ()=glyph_run_dispose(r) and ()=ot_reverse_lookup_dispose(t) and ()=buf_free(b)
in iadd(errors,if ok then 0 else 1) end
implement reverse_pass_masks() = let
  val mb=ligation_test_metadata_bytes() val m=ligation_test_metadata(mb)
  val b=reverse_pass_table() val t=reverse_pass_parse(b)
  val errors=masked(b,t,m)+marks(m)
  val ()=ot_reverse_lookup_dispose(t) and ()=buf_free(b)
  val ()=glyph_metadata_dispose(m) and ()=buf_free(mb)
in errors end
