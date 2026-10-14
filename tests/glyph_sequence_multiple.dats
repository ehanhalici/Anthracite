#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/ot_layout_types.sats"
staload "data_font/gsub_single_types.sats"
staload "data_font/gsub_sequence_types.sats"
staload "data_font/gsub_sequences.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_run.sats"
staload "data_font/glyph_pass_types.sats"
staload "data_font/glyph_pass_sequence.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/glyph_metadata.sats"
staload "data_font/ot_sequence_lookup_types.sats"
staload "data_font/ot_sequence_lookup.sats"
staload "opentype_fixture.sats"
staload "glyph_run_contracts.sats"
staload "glyph_pass_contracts.sats"
staload "glyph_sequence_contracts.sats"
fun all(b: !Buf,t: !OtSequenceLookup(2),m: !GlyphMetadata): int = let var errors: int=0
  val run=pass_test_take(glyph_pass_multiple(b,t,m,seq_test_nominal(128,10,2,errors),@{kind=GlyphAll(),mask=0u}),2,2,errors)
  val ()=errors := errors+seq_test_list(run,"000B 0000 000B 000B 0000 000B")
    +seq_test_core(run,0,11,0)+seq_test_core(run,2,0,0)+seq_test_core(run,3,11,0)
    +seq_test_core(run,1,11,1)+seq_test_core(run,4,0,1)+seq_test_core(run,5,11,1)
  val second=pass_test_take(glyph_pass_multiple(b,t,m,run,@{kind=GlyphAll(),mask=0u}),6,4,errors)
  val ()=errors := errors+seq_test_list(second,"000C 000D 0000 000C 000D 000C 000D 0000 000C 000D")
  val ()=glyph_run_dispose(second)
in errors end
fun masked(b: !Buf,t: !OtSequenceLookup(2),m: !GlyphMetadata): int = let var errors: int=0
  val run=pass_test_take(glyph_pass_multiple(b,t,m,seq_test_nominal(128,10,2,errors),@{kind=GlyphMasked(),mask=1u}),2,1,errors)
  val ()=errors := errors+seq_test_list(run,"000B 0000 000B 000A")+seq_test_core(run,0,11,0)
    +seq_test_core(run,2,0,0)+seq_test_core(run,3,11,0)+seq_test_core(run,1,10,1)
  val ()=glyph_run_dispose(run)
in errors end
fun empty(b: !Buf,t: !OtSequenceLookup(2),m: !GlyphMetadata): int = let var errors: int=0
  val run=pass_test_take(glyph_pass_multiple(b,t,m,seq_test_nominal(128,10,0,errors),@{kind=GlyphAll(),mask=0u}),0,0,errors)
  val meta=glyph_run_meta(run)
  val ()=if ieq(meta.live,0) andalso ieq(meta.head,~1) andalso ieq(meta.tail,~1) then () else errors := errors+1
  val ()=glyph_run_dispose(run)
in errors end
fun sparse(b: !Buf,t: !OtSequenceLookup(2),m: !GlyphMetadata): int = let var errors: int=0
  val nodes=run_test_indices(0,2)
  val initial=run_test_take(glyph_run_ligate(seq_test_nominal(128,10,3,errors),nodes,2,12),run_test_updated,errors)
  val run=pass_test_take(glyph_pass_multiple(b,t,m,initial,@{kind=GlyphAll(),mask=0u}),2,1,errors)
  val ()=errors := errors+seq_test_list(run,"000C 000B 0000 000B")+seq_test_core_cluster(run,1,11,1,0)
    +seq_test_core_cluster(run,3,0,1,0)+seq_test_core_cluster(run,4,11,1,0)
  val missing=glyph_run_query(run,2)
  val ()=case+ missing.kind of | GlyphMissing() => () | GlyphPresent() => errors := errors+1
  val ()=glyph_run_dispose(run) and ()=buf_free(nodes)
in errors end
implement seq_test_multiple() = let val b=seq_test_fixture()
  val t=seq_test_table(b,GsubMultiple()) and m=seq_test_metadata(b,3,128)
  val errors=all(b,t,m)+masked(b,t,m)+empty(b,t,m)+sparse(b,t,m)
  val ()=ot_sequence_lookup_dispose(t) and ()=glyph_metadata_dispose(m) and ()=buf_free(b)
in errors end
