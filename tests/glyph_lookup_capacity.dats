#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_run.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/glyph_pass_lookup.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/glyph_metadata.sats"
staload "data_font/ot_single_lookup_types.sats"
staload "data_font/ot_single_lookup.sats"
staload "glyph_pass_contracts.sats"
staload "glyph_lookup_contracts.sats"
staload "opentype_fixture.sats"
fun check(b: !Buf,m: !GlyphMetadata): int = case+ ot_single_lookup_parse(b,ot_fixture_span(b),128) of
  | ~SingleLookupRejected(e) => 1 | ~SingleLookupAccepted(table) => let
    var errors: int=0
    val run=lookup_test_reject(glyph_pass_lookup(b,table,m,pass_test_run(32768),@{kind=GlyphAll(),mask=0u}),GlyphPassCapacity(),errors)
    val first=glyph_run_query(run,0) and last=glyph_run_query(run,32767)
    val ok=ieq(first.core.glyph,10) andalso ieq(last.core.glyph,25) andalso ieq(last.core.sourceEnd,65536)
    val ()=glyph_run_dispose(run) and ()=ot_single_lookup_dispose(table)
  in iadd(errors,if ok then 0 else 1) end
implement lookup_test_capacity() = let
  val b=pass_test_large_lookup()
  val errors: int=case+ glyph_metadata_parse(b,@{kind=ChildMissing(),span= @{offset=0,length=0}},3,128) of
    | ~GlyphMetadataRejected(e) => 1 | ~GlyphMetadataAccepted(m) => let
      val e=check(b,m) val ()=glyph_metadata_dispose(m)
    in e end
  val ()=buf_free(b)
in errors end
