#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/run/glyph_run.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/glyph/pass/glyph_pass_lookup.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/core/glyph_metadata.sats"
staload "data_font/opentype/single_lookup/ot_single_lookup_types.sats"
staload "data_font/opentype/single_lookup/ot_single_lookup.sats"
staload "font/glyph/pass/glyph_pass_contracts.sats"
staload "font/glyph/core/glyph_lookup_contracts.sats"
staload "font/opentype/tables/opentype_fixture.sats"
fun same(a: GlyphPassStatus,b: GlyphPassStatus): bool = case+ a of
  | GlyphPassApplied() => (case+ b of | GlyphPassApplied() => true | GlyphPassDomain() => false
    | GlyphPassReference() => false | GlyphPassCapacity() => false)
  | GlyphPassDomain() => (case+ b of | GlyphPassApplied() => false | GlyphPassDomain() => true
    | GlyphPassReference() => false | GlyphPassCapacity() => false)
  | GlyphPassReference() => (case+ b of | GlyphPassApplied() => false | GlyphPassDomain() => false
    | GlyphPassReference() => true | GlyphPassCapacity() => false)
  | GlyphPassCapacity() => (case+ b of | GlyphPassApplied() => false | GlyphPassDomain() => false
    | GlyphPassReference() => false | GlyphPassCapacity() => true)
implement lookup_test_reject(result,expected,errors) = let
  val+ ~GlyphPassResult(run,status,visited,matches)=result
  val ()=if same(status,expected) andalso ieq(visited,0) andalso ieq(matches,0) then () else errors := iadd(errors,1)
in run end
fun mismatch(font: int,propertyGlyphs: int,tableGlyphs: int): int = let
  val b=lookup_test_fixture(0)
  val metadata=lookup_test_metadata(b,font,propertyGlyphs) and table=lookup_test_table(b,tableGlyphs)
  var errors: int=0
  val run=lookup_test_reject(glyph_pass_lookup(b,table,metadata,pass_test_run(6),@{kind=GlyphAll(),mask=0u}),GlyphPassDomain(),errors)
  val ()=errors := iadd(errors,lookup_test_glyphs(run,"000A 000B 000C 000D 000E 000F"))
  val ()=glyph_run_dispose(run) and ()=ot_single_lookup_dispose(table) and ()=glyph_metadata_dispose(metadata)
  val ()=buf_free(b)
in errors end
fun bad_set(): int = let
  val b=lookup_test_fixture(16)
  val ()=ot_fixture_put16(b,68,1)
  val metadata=lookup_test_metadata(b,3,128) and table=lookup_test_table(b,128)
  var errors: int=0
  val run=lookup_test_reject(glyph_pass_lookup(b,table,metadata,pass_test_run(6),@{kind=GlyphAll(),mask=0u}),GlyphPassReference(),errors)
  val ()=errors := iadd(errors,lookup_test_glyphs(run,"000A 000B 000C 000D 000E 000F"))
  val ()=glyph_run_dispose(run) and ()=ot_single_lookup_dispose(table) and ()=glyph_metadata_dispose(metadata)
  val ()=buf_free(b)
in errors end
fun absent(): int = let
  val b=lookup_test_fixture(2)
  val errors: int=case+ glyph_metadata_parse(b,@{kind=ChildMissing(),span= @{offset=0,length=0}},3,128) of
    | ~GlyphMetadataRejected(e) => 1 | ~GlyphMetadataAccepted(metadata) => let
      val table=lookup_test_table(b,128)
      var e: int=0
      val run=lookup_test_reject(glyph_pass_lookup(b,table,metadata,pass_test_run(6),@{kind=GlyphAll(),mask=0u}),GlyphPassReference(),e)
      val extra=lookup_test_glyphs(run,"000A 000B 000C 000D 000E 000F")
      val ()=glyph_run_dispose(run) and ()=ot_single_lookup_dispose(table) and ()=glyph_metadata_dispose(metadata)
    in e+extra end
  val ()=buf_free(b)
in errors end
implement lookup_test_references() = mismatch(4,128,128)+mismatch(3,129,128)+mismatch(3,128,129)+bad_set()+absent()
