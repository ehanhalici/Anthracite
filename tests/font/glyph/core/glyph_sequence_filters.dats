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
staload "font/glyph/core/glyph_lookup_contracts.sats"
fun fixture(flags: int): Buf = let
  val b=ot_fixture_words("0001 0002 000E 0000 0000 0020 002E 0001 000A 0006 0001 0002 0003 0004 0000 0003 0001 000C 0004 0001 0000 0000 0002 0001 0001 0000 0008 0001 0001 000C 0002 0000 0001 000A 0000 0001 0012 0006 0022 0022 0022 0022 0022 0022 0001 0006 000A 000B 000C 000D 000E 000F 0002 0014 0015")
  val ()=ot_fixture_put16(b,62,flags)
in b end
extern fun filter_table_failed(): OtSequenceLookup(2) = "mac#anth_die_box"
fun table(b: !Buf): OtSequenceLookup(2) = case+ ot_sequence_lookup_parse(b,@{offset=68,length=isub(buf_len(b),68)},128,GsubMultiple()) of
  | ~SequenceLookupRejected(e) => filter_table_failed() | ~SequenceLookupAccepted(t) => t
fun seed{n:nat} .<n>. (left: int(n),run: GlyphRun(1),i: int,errors: &int >> _): GlyphRun(1) =
  if left = 0 then run else seed(left-1,
    run_test_take(glyph_run_single(run,i,iadd(10,i)),run_test_updated,errors),iadd(i,1),errors)
fun rows{n:nat} .<n>. (left: int(n),run: !GlyphRun(1),read_bits: int,i: int,newId: int,node: int,previous: int): int =
  if left = 0 then (if ieq(node,~1) then 0 else 1) else let
    val matched=ine(imod(read_bits,2),0)
    val first=glyph_run_query(run,i) and second=glyph_run_query(run,newId)
    val a=seq_test_core(run,i,if matched then 20 else iadd(10,i),i)
    val c: int=if matched then seq_test_core(run,newId,21,i) else 0
    val linked=ieq(node,i) andalso ieq(first.links.previous,previous)
      andalso (not(matched) orelse (ieq(first.links.next,newId) andalso ieq(second.links.previous,i)))
    val next=if matched then second.links.next else first.links.next
    val prev=if matched then newId else i
  in iadd(iadd(a,c),iadd(if linked then 0 else 1,rows(left-1,run,idiv(read_bits,2),iadd(i,1),
    iadd(newId,if matched then 1 else 0),next,prev))) end
fun one(flags: int,read_bits: int,matches: int,selection: GlyphSelection): int = let
  val b=fixture(flags) val m=lookup_test_metadata(b,3,128) and t=table(b)
  var errors: int=0
  val input=seed(6,seq_test_nominal(128,10,6,errors),0,errors)
  val run=pass_test_take(glyph_pass_multiple(b,t,m,input,selection),6,matches,errors)
  val ()=errors := errors+rows(6,run,read_bits,0,6,0,~1)
  val meta=glyph_run_meta(run)
  val ()=if ieq(meta.used,iadd(6,matches)) andalso ieq(meta.live,meta.used) then () else errors := errors+1
  val ()=glyph_run_dispose(run) and ()=ot_sequence_lookup_dispose(t) and ()=glyph_metadata_dispose(m) and ()=buf_free(b)
in errors end
implement seq_test_filters() = let val all: GlyphSelection= @{kind=GlyphAll(),mask=0u} in
  one(0,63,6,all)+one(2,62,5,all)+one(4,61,5,all)+one(8,27,4,all)+one(14,24,2,all)
    +one(256,31,5,all)+one(16,31,5,all)+one(528,31,5,all)+one(536,27,4,all)
    +one(8,10,2,@{kind=GlyphMasked(),mask=2u})
end
