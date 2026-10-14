#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_run.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/glyph_metadata.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/gsub_ligature_types.sats"
staload "data_font/gsub_ligatures.sats"
staload "data_font/glyph_pass_ligature.sats"
staload "opentype_fixture.sats"
staload "glyph_run_contracts.sats"
staload "glyph_ligation_contracts.sats"
staload "data_font/opentype_lookup_flags.sats"
staload "data_font/glyph_run_storage.sats"
staload "data_font/glyph_run_work.sats"
fun masked(run: GlyphRun(1)): GlyphRun(1) = let val+ ~GlyphRun(p,meta,s)=run
  val core=glyph_storage_core(s,1) val ()=glyph_storage_set_core(s,1,glyph_run_new_mask(core,2u))
in GlyphRun(p,meta,s) end
fun masks(b: !Buf,m: !GlyphMetadata): int = let
  var errors: int=0
  val t=ligation_test_parse(b)
  val run=masked(ligation_test_run("000A 000B 000B",errors))
  val+ ~GlyphPassResult(run,status,visited,matches)=glyph_pass_ligature(b,t,m,run,ligation_test_flags(0),0,@{kind=GlyphMasked(),mask=1u})
  val meta=glyph_run_meta(run)
  val ok=ieq(meta.live,3) andalso ieq(matches,0) andalso ieq(visited,3)
  val ()=gsub_ligatures_dispose(t) and ()=glyph_run_dispose(run)
in iadd(errors,if ok then 0 else 1) end
fun rejected(b: !Buf,m: !GlyphMetadata): int = let
  var errors: int=0
  val t=ligation_test_parse(b)
  val+ ~GlyphPassResult(run,status,visited,matches)=glyph_pass_ligature(b,t,m,ligation_test_run("000A 000B",errors),ligation_test_flags(0),0,@{kind=GlyphAll(),mask=0u})
  val v=glyph_run_query(run,0) and meta=glyph_run_meta(run)
  val reference=case+ status of | GlyphPassReference() => true | GlyphPassApplied() => false
    | GlyphPassDomain() => false | GlyphPassCapacity() => false
  val ok=reference andalso ieq(meta.live,2) andalso ieq(v.core.glyph,10) andalso ieq(visited,0) andalso ieq(matches,0)
  val ()=gsub_ligatures_dispose(t) and ()=glyph_run_dispose(run)
in iadd(errors,if ok then 0 else 1) end
implement ligation_test_masks() = let
  val b=ligation_test_table(10,11,14) and bytes=ligation_test_metadata_bytes()
  val m=ligation_test_metadata(bytes)
  val errors=masks(b,m)
  val ()=glyph_metadata_dispose(m) and ()=buf_free(bytes)
  val missing=case+ glyph_metadata_parse(b,@{kind=ChildMissing(),span= @{offset=0,length=0}},3,128) of
    | ~GlyphMetadataAccepted(m) => let val errors=rejected(b,m) val ()=glyph_metadata_dispose(m) in errors end
    | ~GlyphMetadataRejected(e) => 1
  val ()=buf_free(b)
in iadd(errors,missing) end
