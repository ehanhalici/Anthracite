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
fun multiple(b: !Buf): int = let val t=seq_test_table(b,GsubMultiple())
  val a=ot_multiple_lookup_query(b,t,10) and c=ot_multiple_lookup_query(b,t,11)
  val missing=ot_multiple_lookup_query(b,t,128) and negative=ot_multiple_lookup_query(b,t,~1)
  val ok=a.matched andalso ieq(a.count,3) andalso ieq(gsub_sequence_glyph(b,a,0),11)
    andalso ieq(gsub_sequence_glyph(b,a,1),0) andalso ieq(gsub_sequence_glyph(b,a,2),11)
    andalso c.matched andalso ieq(c.count,2) andalso ieq(gsub_sequence_glyph(b,c,0),12)
    andalso not(missing.matched orelse negative.matched)
  val ()=ot_sequence_lookup_dispose(t)
in if ok then 0 else 1 end
fun reject{kind:int}(b: !Buf,s: OtSpan,d: GsubSequenceDomain(kind)): int =
  case+ ot_sequence_lookup_parse(b,s,128,d) of
  | ~SequenceLookupRejected(e) => 0 | ~SequenceLookupAccepted(t) => let val ()=ot_sequence_lookup_dispose(t) in 1 end
fun cuts{n:nat} .<n>. (left: int(n),b: !Buf,i: int): int =
  if left = 0 then 0 else reject(b,@{offset=8,length=i},GsubMultiple())+cuts(left-1,b,iadd(i,1))
fun changed(at: int,value: int): int = let val b=seq_test_fixture()
  val ()=ot_fixture_put16(b,at,value)
  val errors=reject(b,ot_fixture_span(b),GsubMultiple()) val ()=buf_free(b)
in errors end
fun extended(): int = let
  val b=ot_fixture_words("0007 0000 0002 000A 0028 0001 0002 0000 0008 0001 0008 0001 000E 0001 0001 000A 0003 000B 0000 000B 0001 0002 0000 0008 0001 0008 0001 000E 0001 0001 000B 0002 000C 000D")
  val errors=multiple(b)
  val ()=ot_fixture_put16(b,42,3)
  val mixed=reject(b,ot_fixture_span(b),GsubMultiple())
  val ()=ot_fixture_put16(b,12,3)
  val other=reject(b,ot_fixture_span(b),GsubMultiple())
  val ()=buf_free(b)
in errors+mixed+other end
implement seq_test_cache() = let val b=seq_test_fixture()
  val errors=multiple(b)+cuts(airlock_nat(isub(buf_len(b),8)),b,0)+reject(b,ot_fixture_span(b),GsubAlternate())
  val ()=buf_free(b)
in errors+extended()+changed(2,32)+changed(6,0)+changed(24,0)+changed(26,128)+changed(22,128)+changed(38,0) end
