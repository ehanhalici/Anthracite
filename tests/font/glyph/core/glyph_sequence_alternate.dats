#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/substitution/gsub_single_types.sats"
staload "data_font/opentype/substitution/gsub_sequence_types.sats"
staload "data_font/opentype/substitution/gsub_sequences.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/run/glyph_run.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/glyph/pass/glyph_pass_sequence.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/core/glyph_metadata.sats"
staload "data_font/opentype/sequence_lookup/ot_sequence_lookup_types.sats"
staload "data_font/opentype/sequence_lookup/ot_sequence_lookup.sats"
staload "font/opentype/tables/opentype_fixture.sats"
staload "font/glyph/run/glyph_run_contracts.sats"
staload "font/glyph/pass/glyph_pass_contracts.sats"
staload "font/glyph/core/glyph_sequence_contracts.sats"
fun query(b: !Buf,t: !OtSequenceLookup(3),choice: int,matched: bool,glyph: int): int = let
  val r=ot_alternate_lookup_query(b,t,10,choice)
in if r.matched = matched andalso ieq(r.glyph,glyph) then 0 else 1 end
fun one(b: !Buf,count: int,choice: int,matched: bool,glyph: int): int = let
  val ()=ot_fixture_put16(b,24,count)
  val t=seq_test_table(b,GsubAlternate())
  val errors=query(b,t,choice,matched,glyph)
  val ()=ot_sequence_lookup_dispose(t)
in errors end
fun run(b: !Buf,t: !OtSequenceLookup(3),m: !GlyphMetadata,choice: int,matches: int,glyph: int): int = let var errors: int=0
  val run=pass_test_take(glyph_pass_alternate(b,t,m,seq_test_nominal(128,10,2,errors),
    @{kind=GlyphMasked(),mask=1u},choice),2,matches,errors)
  val ()=errors := errors+seq_test_core(run,0,glyph,0)+seq_test_core(run,1,10,1)
  val ()=glyph_run_dispose(run)
in errors end
implement seq_test_alternate() = let val b=seq_test_fixture()
  val ()=ot_fixture_put16(b,0,3) and ()=ot_fixture_put16(b,44,10)
  val t=seq_test_table(b,GsubAlternate()) and m=seq_test_metadata(b,3,128)
  val errors=query(b,t,0,false,10)+query(b,t,~1,false,10)+query(b,t,1,true,11)
    +query(b,t,2,true,0)+query(b,t,3,true,11)+query(b,t,4,false,10)
    +run(b,t,m,2,1,0)+run(b,t,m,0,0,10)+run(b,t,m,4,0,10)
  val ()=ot_sequence_lookup_dispose(t) and ()=glyph_metadata_dispose(m)
  val priority=one(b,0,1,true,12)+one(b,1,2,true,13)
  val ()=ot_fixture_put16(b,26,10)
  val identity=one(b,1,1,true,10)
  val ()=buf_free(b)
in errors+priority+identity end
