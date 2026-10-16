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
fun basic(m: !GlyphMetadata): int = let
  var errors: int=0
  val b=ligation_test_table(10,11,14)
  val run=ligation_test_applied(ligation_test_run("000A 000C 000B",errors),b,m,8,errors)
  val owner=glyph_run_query(run,0) and mark=glyph_run_query(run,1)
  val a=glyph_run_mark_association(run,1) and meta=glyph_run_meta(run)
  val ok=ieq(meta.live,2) andalso ieq(owner.core.glyph,14) andalso ieq(owner.core.components,2)
    andalso ieq(owner.core.sourceStart,0) andalso ieq(owner.core.sourceEnd,6) andalso ieq(owner.links.next,1)
    andalso a.found andalso ieq(a.owner,0) andalso ieq(a.component,0)
    andalso ieq(mark.core.cluster,0) andalso ieq(mark.core.sourceStart,2) andalso ieq(mark.core.sourceEnd,4)
  val ()=buf_free(b) and ()=glyph_run_dispose(run)
in iadd(errors,if ok then 0 else 1) end
fun retained(m: !GlyphMetadata,first: int,second: int,output: int,s: string): int = let
  var errors: int=0
  val b=ligation_test_table(first,second,output)
  val run=ligation_test_applied(ligation_test_run(s,errors),b,m,0,errors)
  val owner=glyph_run_query(run,0) and meta=glyph_run_meta(run)
  val ordinary=case+ owner.core.association of | Unassociated() => true | LigatureOwner() => false
    | LigatureMark() => false | LigatureForward() => false
  val ok=ieq(meta.live,1) andalso ieq(owner.core.glyph,output) andalso ieq(owner.core.components,1) andalso ordinary
    andalso ieq(meta.nextLigature,1) andalso ieq(owner.core.sourceStart,0) andalso ieq(owner.core.sourceEnd,4)
  val ()=buf_free(b) and ()=glyph_run_dispose(run)
in iadd(errors,if ok then 0 else 1) end
fun marked(m: !GlyphMetadata): int = let
  var errors: int=0
  val b=ot_fixture_words("0001 0008 0001 000E 0001 0001 000A 0001 0004 000E 0003 000C 000B")
  val run=ligation_test_applied(ligation_test_run("000A 000C 000B",errors),b,m,0,errors)
  val owner=glyph_run_query(run,0) and meta=glyph_run_meta(run)
  val ok=ieq(meta.live,1) andalso ieq(owner.core.components,2) andalso ieq(owner.core.glyph,14)
  val ()=buf_free(b) and ()=glyph_run_dispose(run)
in iadd(errors,if ok then 0 else 1) end
implement ligation_test_basic() = let val b=ligation_test_metadata_bytes() val m=ligation_test_metadata(b)
  val errors=basic(m)+retained(m,10,12,11,"000A 000C")+retained(m,12,13,12,"000C 000D")+marked(m)
  val ()=glyph_metadata_dispose(m) and ()=buf_free(b)
in errors end
