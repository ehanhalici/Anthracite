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
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/core/glyph_metadata.sats"
staload "data_font/opentype/single_lookup/ot_single_lookup_types.sats"
staload "data_font/opentype/single_lookup/ot_single_lookup.sats"
staload "font/opentype/tables/opentype_fixture.sats"
staload "font/glyph/core/glyph_lookup_contracts.sats"
extern fun metadata_failed(): GlyphMetadata = "mac#anth_die_box"
extern fun lookup_failed(): OtSingleLookup = "mac#anth_die_box"
implement lookup_test_fixture(flags) = let
  val b=ot_fixture_words("0001 0002 000E 0000 0000 0020 002E 0001 000A 0006 0001 0002 0003 0004 0000 0003 0001 000C 0004 0001 0000 0000 0002 0001 0001 0000 0008 0001 0001 000C 0001 0000 0001 000A 0000 0001 0006 0001 0002 0001 000A 0019 0000")
  val ()=ot_fixture_put16(b,62,flags)
in b end
implement lookup_test_metadata(b,font,glyphs) =
  case+ glyph_metadata_parse(b,@{kind=ChildPresent(),span= @{offset=8,length=60}},font,glyphs) of
  | ~GlyphMetadataRejected(e) => metadata_failed() | ~GlyphMetadataAccepted(metadata) => metadata
implement lookup_test_table(b,glyphs) = case+ ot_single_lookup_parse(b,@{offset=68,length=isub(buf_len(b),68)},glyphs) of
  | ~SingleLookupRejected(e) => lookup_failed() | ~SingleLookupAccepted(t) => t
fun rows{n:nat} .<n>. (n: int(n),run: !GlyphRun(1),expected: !Buf,i: int): int =
  if n = 0 then 0 else let
    val v=glyph_run_query(run,i)
    val ok=ieq(v.core.glyph,ot_fixture_read16(expected,imul(i,2)))
      andalso ieq(v.core.sourceStart,imul(i,2)) andalso ieq(v.core.sourceEnd,imul(iadd(i,1),2))
      andalso ieq(v.core.scalar,1576) andalso ieq(v.core.cluster,i)
  in iadd(if ok then 0 else 1,rows(n-1,run,expected,iadd(i,1))) end
implement lookup_test_glyphs(run,s) = let val expected=ot_fixture_words(s)
  val errors=rows(6,run,expected,0) val ()=buf_free(expected)
in errors end
