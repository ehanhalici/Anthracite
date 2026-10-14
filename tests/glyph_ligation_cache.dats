#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_reader.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_run.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/glyph_metadata.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/gsub_ligature_types.sats"
staload "data_font/ot_ligation_lookup_types.sats"
staload "data_font/ot_ligation_lookup.sats"
staload "data_font/glyph_pass_ligation.sats"
staload "opentype_fixture.sats"
staload "glyph_run_contracts.sats"
staload "glyph_ligation_contracts.sats"
fun checked(b: !Buf,m: !GlyphMetadata,expected: int,live: int): int =
  case+ ot_ligation_lookup_parse(b,ot_fixture_span(b),128) of | ~LigationLookupRejected(e) => 1
  | ~LigationLookupAccepted(t) => let
    var errors: int=0
    val input=run_test_indices(10,11)
    var remaining: int=1024
    val q=ot_ligation_lookup_query(b,t,input,2,0,remaining)
    val+ ~GlyphPassResult(run,status,visited,matches)=glyph_pass_ligation(b,t,m,ligation_test_run("000A 000B",errors),@{kind=GlyphAll(),mask=0u})
    val v=glyph_run_query(run,0) and meta=glyph_run_meta(run)
    val ready=case+ status of | GlyphPassApplied() => true | GlyphPassDomain() => false | GlyphPassReference() => false | GlyphPassCapacity() => false
    val ok=ready andalso q.result.matched andalso ieq(q.result.glyph,expected) andalso ieq(v.core.glyph,expected)
      andalso ieq(meta.live,live) andalso ieq(matches,1) andalso ieq(ot_ligation_lookup_maximum(t),2)
    val ()=buf_free(input) and ()=glyph_run_dispose(run) and ()=ot_ligation_lookup_dispose(t)
  in iadd(errors,if ok then 0 else 1) end
fun rejected(b: !Buf): int = case+ ot_ligation_lookup_parse(b,ot_fixture_span(b),128) of
  | ~LigationLookupRejected(e) => 0 | ~LigationLookupAccepted(t) => let val ()=ot_ligation_lookup_dispose(t) in 1 end
fun direct(m: !GlyphMetadata): int = let
  val b=ot_fixture_words("0004 0008 0002 000A 0022 0001 0008 0001 000E 0001 0001 000A 0001 0004 000E 0002 000B 0001 0008 0001 000E 0001 0001 000A 0001 0004 000F 0002 000B")
  val first=checked(b,m,14,1)
  val ()=ot_fixture_put16(b,28,10) and ()=ot_fixture_put16(b,30,1)
  val identity=checked(b,m,10,2)
  val ()=ot_fixture_put16(b,52,128)
  val invalid=rejected(b)
  val ()=buf_free(b)
in first+identity+invalid end
fun extended(m: !GlyphMetadata): int = let
  val b=ot_fixture_words("0007 0008 0002 000A 002A 0001 0004 0000 0008 0001 0008 0001 000E 0001 0001 000A 0001 0004 000E 0002 000B 0001 0004 0000 0008 0001 0008 0001 000E 0001 0001 000A 0001 0004 000F 0002 000B")
  val errors=checked(b,m,14,1)
  val ()=ot_fixture_put16(b,44,1)
  val invalid=rejected(b)
  val ()=buf_free(b)
in errors+invalid end
implement ligation_test_cache() = let val b=ligation_test_metadata_bytes() val m=ligation_test_metadata(b)
  val errors=direct(m)+extended(m)
  val ()=glyph_metadata_dispose(m) and ()=buf_free(b)
in errors end
