#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/run/glyph_run.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/core/glyph_metadata.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/opentype/substitution/gsub_ligature_types.sats"
staload "data_font/opentype/substitution/gsub_ligatures.sats"
staload "data_font/glyph/pass/glyph_pass_ligature.sats"
staload "font/opentype/tables/opentype_fixture.sats"
staload "font/glyph/run/glyph_run_contracts.sats"
staload "font/glyph/core/glyph_ligation_contracts.sats"
fun prepared(second: int,errors: &int >> _): GlyphRun(1) = let
  val nodes=run_test_indices(0,2)
  val run=run_test_take(glyph_run_ligate(ligation_test_run("000A 000C 000B 000D",errors),nodes,2,14),run_test_updated,errors)
  val run=run_test_take(glyph_run_bind_mark(run,1,0,0),run_test_updated,errors)
  val run=run_test_take(glyph_run_bind_mark(run,3,0,second),run_test_updated,errors)
  val ()=buf_free(nodes)
in run end
fun pair(m: !GlyphMetadata,second: int,flags: int,live: int): int = let
  var errors: int=0
  val b=ligation_test_table(12,13,12)
  val run=ligation_test_applied(prepared(second,errors),b,m,flags,errors)
  val a=glyph_run_mark_association(run,1) and meta=glyph_run_meta(run)
  val ok=ieq(meta.live,live) andalso a.found andalso ieq(a.owner,0) andalso ieq(a.component,0)
  val ()=buf_free(b) and ()=glyph_run_dispose(run)
in iadd(errors,if ok then 0 else 1) end
fun nested(m: !GlyphMetadata): int = let
  var errors: int=0
  val nodes=run_test_indices(0,2)
  val run=run_test_take(glyph_run_ligate(ligation_test_run("000A 000C 000B 000B 000D",errors),nodes,2,14),run_test_updated,errors)
  val run=run_test_take(glyph_run_bind_mark(run,1,0,0),run_test_updated,errors)
  val b=ligation_test_table(14,11,15)
  val run=ligation_test_applied(run,b,m,8,errors)
  val a=glyph_run_mark_association(run,1) and owner=glyph_run_query(run,0)
  val ok=a.found andalso ieq(a.component,0) andalso ieq(owner.core.components,3)
  val ()=buf_free(nodes) and ()=buf_free(b) and ()=glyph_run_dispose(run)
in iadd(errors,if ok then 0 else 1) end
implement ligation_test_associations() = let val b=ligation_test_metadata_bytes() val m=ligation_test_metadata(b)
  val errors=pair(m,0,0,2)+pair(m,1,0,3)+pair(m,1,4,2)+nested(m)
  val ()=glyph_metadata_dispose(m) and ()=buf_free(b)
in errors end
