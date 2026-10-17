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
extern fun seq_metadata_failed(): GlyphMetadata = "mac#anth_die_box"
extern fun seq_lookup_failed{kind:int}(): OtSequenceLookup(kind) = "mac#anth_die_box"
extern fun seq_run_failed(): GlyphRun(1) = "mac#anth_die_box"
implement seq_test_fixture() = ot_fixture_words(
  "0002 0000 0002 000A 0020 0001 0008 0001 000E 0001 0001 000A 0003 000B 0000 000B 0001 0008 0001 000E 0001 0001 000B 0002 000C 000D")
implement seq_test_metadata(b,font,glyphs) =
  case+ glyph_metadata_parse(b,@{kind=ChildMissing(),span= @{offset=0,length=0}},font,glyphs) of
  | ~GlyphMetadataRejected(e) => seq_metadata_failed() | ~GlyphMetadataAccepted(m) => m
implement seq_test_table(b,d) = case+ ot_sequence_lookup_parse(b,ot_fixture_span(b),128,d) of
  | ~SequenceLookupRejected(e) => seq_lookup_failed() | ~SequenceLookupAccepted(t) => t
fun append{n:nat} .<n>. (left: int(n),run: GlyphRun(0),input: int,i: int,errors: &int >> _): GlyphRun(0) =
  if left = 0 then run else let
    val seed: GlyphSeed= @{glyph=input,scalar=if ieq(imod(i,2),0) then 1576 else 305,
      sourceStart=imul(i,2),sourceEnd=imul(iadd(i,1),2),cluster=i,mask=if ieq(imod(i,2),0) then 1u else 2u}
    val next=run_test_take(glyph_run_append(run,seed),run_test_updated,errors)
  in append(left-1,next,input,iadd(i,1),errors) end
implement seq_test_nominal(glyphs,input,count,errors) = case+ glyph_run_make(3,glyphs,imul(count,2),count) of
  | ~GlyphRunRejected(status) => seq_run_failed()
  | ~GlyphRunCreated(run) => glyph_run_substitute(append(airlock_nat(count),run,input,0,errors))
implement seq_test_core_cluster(run,node,glyph,source,cluster) = let val v=glyph_run_query(run,node)
  val found=case+ v.kind of | GlyphPresent() => true | GlyphMissing() => false
  val mask: uint=if ieq(imod(source,2),0) then 1u else 2u
  val ok=found andalso ieq(v.core.glyph,glyph) andalso ieq(v.core.sourceStart,imul(source,2))
    andalso ieq(v.core.sourceEnd,imul(iadd(source,1),2)) andalso ieq(v.core.cluster,cluster)
    andalso ieq(v.core.scalar,if ieq(imod(source,2),0) then 1576 else 305)
    andalso g0uint_eq_uint(v.core.mask,mask)
in if ok then 0 else 1 end
implement seq_test_core(run,node,glyph,source) = seq_test_core_cluster(run,node,glyph,source,source)
fun list{n:nat} .<n>. (left: int(n),run: !GlyphRun(1),expected: !Buf,node: int,previous: int,i: int): int =
  if left = 0 then let val meta=glyph_run_meta(run) in
    if ieq(node,~1) andalso ieq(meta.tail,previous) then 0 else 1 end else let
    val v=glyph_run_query(run,node)
    val found=case+ v.kind of | GlyphPresent() => true | GlyphMissing() => false
    val ok=found andalso ieq(v.core.glyph,ot_fixture_read16(expected,imul(i,2))) andalso ieq(v.links.previous,previous)
  in iadd(if ok then 0 else 1,list(left-1,run,expected,v.links.next,node,iadd(i,1))) end
implement seq_test_list(run,s) = let val expected=ot_fixture_words(s)
  val count=idiv(isub(buf_len(expected),8),2) and meta=glyph_run_meta(run)
  val errors=list(airlock_nat(count),run,expected,meta.head,~1,0)
  val ()=buf_free(expected)
in iadd(errors,if ieq(meta.live,count) then 0 else 1) end
