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
fun status_code(s: GlyphPassStatus): int = case+ s of
  | GlyphPassApplied() => 0 | GlyphPassDomain() => 1 | GlyphPassReference() => 2 | GlyphPassCapacity() => 3
fun rejected(result: GlyphPassResult(1),expected: int,live: int,used: int): int = let
  val+ ~GlyphPassResult(run,status,visited,matches)=result
  val meta=glyph_run_meta(run) and first=glyph_run_query(run,0)
  val ok=ieq(status_code(status),expected) andalso ieq(visited,0) andalso ieq(matches,0)
    andalso ieq(meta.live,live) andalso ieq(meta.used,used) andalso ieq(first.core.glyph,10)
  val ()=glyph_run_dispose(run)
in if ok then 0 else 1 end
fun foreign(b: !Buf,t: !OtSequenceLookup(2)): int = let var errors: int=0
  val wrong=seq_test_metadata(b,4,128)
  val ()=errors := errors+rejected(glyph_pass_multiple(b,t,wrong,seq_test_nominal(128,10,2,errors),
    @{kind=GlyphAll(),mask=0u}),1,2,2)
  val ()=glyph_metadata_dispose(wrong)
  val mismatch=seq_test_metadata(b,3,127)
  val ()=errors := errors+rejected(glyph_pass_multiple(b,t,mismatch,seq_test_nominal(128,10,2,errors),
    @{kind=GlyphAll(),mask=0u}),1,2,2)
  val ()=glyph_metadata_dispose(mismatch)
in errors end
fun associated(b: !Buf,t: !OtSequenceLookup(2),m: !GlyphMetadata): int = let var errors: int=0
  val ids=run_test_indices(0,1)
  val input=run_test_take(glyph_run_ligate(seq_test_nominal(128,10,2,errors),ids,2,10),run_test_updated,errors)
  val ()=errors := errors+rejected(glyph_pass_multiple(b,t,m,input,@{kind=GlyphAll(),mask=0u}),2,1,2)
  val ()=buf_free(ids)
in errors end
fun dependencies(b: !Buf): int = let var errors: int=0
  val ()=ot_fixture_put16(b,2,8)
  val t=seq_test_table(b,GsubMultiple()) and m=seq_test_metadata(b,3,128)
  val ()=errors := errors+rejected(glyph_pass_multiple(b,t,m,seq_test_nominal(128,10,2,errors),
    @{kind=GlyphAll(),mask=0u}),2,2,2)
  val ()=ot_sequence_lookup_dispose(t) and ()=glyph_metadata_dispose(m)
in errors end
fun single_association(b: !Buf,m: !GlyphMetadata): int = let var errors: int=0
  val ()=ot_fixture_put16(b,24,1)
  val t=seq_test_table(b,GsubMultiple()) and ids=run_test_indices(0,1)
  val input=run_test_take(glyph_run_ligate(seq_test_nominal(128,10,2,errors),ids,2,10),run_test_updated,errors)
  val run=pass_test_take(glyph_pass_multiple(b,t,m,input,@{kind=GlyphAll(),mask=0u}),1,1,errors)
  val v=glyph_run_query(run,0)
  val owner=case+ v.core.association of | LigatureOwner() => true | Unassociated() => false
    | LigatureMark() => false | LigatureForward() => false
  val ()=if owner andalso ieq(v.core.components,2) andalso ieq(v.core.glyph,11) then () else errors := errors+1
  val ()=glyph_run_dispose(run) and ()=buf_free(ids) and ()=ot_sequence_lookup_dispose(t)
in errors end
implement seq_test_rejections() = let val b=seq_test_fixture()
  val t=seq_test_table(b,GsubMultiple()) and m=seq_test_metadata(b,3,128)
  val errors=foreign(b,t)+associated(b,t,m)
  val ()=ot_sequence_lookup_dispose(t)
  val retained=single_association(b,m)
  val ()=glyph_metadata_dispose(m)
  val references=dependencies(b)
  val ()=buf_free(b)
in errors+retained+references end
