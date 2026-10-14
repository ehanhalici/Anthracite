#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
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
fun one(raw: int,matches: int,expected: string,selection: GlyphSelection): int = let
  val b=lookup_test_fixture(raw)
  val metadata=lookup_test_metadata(b,3,128) and table=lookup_test_table(b,128)
  var errors: int=0
  val run=pass_test_take(glyph_pass_lookup(b,table,metadata,pass_test_run(6),selection),6,matches,errors)
  val ()=errors := iadd(errors,lookup_test_glyphs(run,expected))
  val ()=glyph_run_dispose(run) and ()=ot_single_lookup_dispose(table) and ()=glyph_metadata_dispose(metadata)
  val ()=buf_free(b)
in errors end
fun repeated(): int = let
  val b=lookup_test_fixture(8)
  val metadata=lookup_test_metadata(b,3,128) and table=lookup_test_table(b,128)
  var errors: int=0
  val first=pass_test_take(glyph_pass_lookup(b,table,metadata,pass_test_run(6),@{kind=GlyphAll(),mask=0u}),6,4,errors)
  val second=pass_test_take(glyph_pass_lookup(b,table,metadata,first,@{kind=GlyphAll(),mask=0u}),6,2,errors)
  val ()=errors := iadd(errors,lookup_test_glyphs(second,"000C 000C 000C 000F 000F 000F"))
  val ()=glyph_run_dispose(second) and ()=ot_single_lookup_dispose(table) and ()=glyph_metadata_dispose(metadata)
  val ()=buf_free(b)
in errors end
implement lookup_test_filters() = let val all: GlyphSelection= @{kind=GlyphAll(),mask=0u} in
  one(0,6,"000B 000C 000D 000E 000F 0010",all)+one(2,5,"000A 000C 000D 000E 000F 0010",all)+
  one(4,5,"000B 000B 000D 000E 000F 0010",all)+one(8,4,"000B 000C 000C 000E 000F 000F",all)+
  one(14,2,"000A 000B 000C 000E 000F 000F",all)+one(256,5,"000B 000C 000D 000E 000F 000F",all)+
  one(16,5,"000B 000C 000D 000E 000F 000F",all)+one(528,5,"000B 000C 000D 000E 000F 000F",all)+
  one(536,4,"000B 000C 000C 000E 000F 000F",all)+
  one(8,2,"000A 000C 000C 000E 000E 000F",@{kind=GlyphMasked(),mask=2u})+repeated()
end
