#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/substitution/gsub_single_types.sats"
staload "data_font/opentype/single_lookup/ot_single_lookup_types.sats"
staload "data_font/opentype/single_lookup/ot_single_lookup.sats"
staload "font/opentype/tables/opentype_fixture.sats"
staload "font/glyph/pass/glyph_pass_contracts.sats"
fun fixture(): Buf = ot_fixture_words(
  "0001 0000 0002 000A 0018 0001 0006 0001 0001 0002 000A 000B 0001 0006 0002 0001 0002 000A 000C")
fun expect(b: !Buf,t: !OtSingleLookup,glyph: int,output: int): int = let
  val result=ot_single_lookup_query(b,t,glyph)
in if result.matched andalso ieq(result.glyph,output) then 0 else 1 end
fun inspect(b: !Buf): int = case+ ot_single_lookup_parse(b,ot_fixture_span(b),128) of
  | ~SingleLookupRejected(e) => 1 | ~SingleLookupAccepted(t) => let
    val missing=ot_single_lookup_query(b,t,13)
    val outside=ot_single_lookup_query(b,t,128)
    val negative=ot_single_lookup_query(b,t,~1)
    val h=ot_single_lookup_header(t)
    val no_match=not(missing.matched orelse outside.matched orelse negative.matched)
      andalso ieq(missing.glyph,13) andalso ieq(outside.glyph,128) andalso ieq(negative.glyph,~1)
    val errors=expect(b,t,10,11)+expect(b,t,11,12)+expect(b,t,12,14)
    val ()=ot_single_lookup_dispose(t)
  in iadd(errors,if no_match andalso ieq(h.count,2) then 0 else 1) end
fun rejected(b: !Buf,s: OtSpan,glyphs: int): int = case+ ot_single_lookup_parse(b,s,glyphs) of
  | ~SingleLookupRejected(e) => 0
  | ~SingleLookupAccepted(t) => let val ()=ot_single_lookup_dispose(t) in 1 end
fun changed(at: int,value: int): int = let
  val b=fixture() val ()=ot_fixture_put16(b,at,value)
  val errors=rejected(b,ot_fixture_span(b),128) val ()=buf_free(b)
in errors end
fun cuts{n:nat} .<n>. (n: int(n),b: !Buf,length: int): int =
  if n = 0 then 0 else rejected(b,@{offset=8,length=length},128)+cuts(n-1,b,iadd(length,1))
fun special(delta: int,output: int): int = let
  val b=fixture() val ()=ot_fixture_put16(b,14,delta)
  val errors: int=case+ ot_single_lookup_parse(b,ot_fixture_span(b),128) of
    | ~SingleLookupRejected(e) => 1 | ~SingleLookupAccepted(t) => let
      val e=expect(b,t,10,output) val ()=ot_single_lookup_dispose(t)
    in e end
  val ()=buf_free(b)
in errors end
fun extension(): int = let
  val b=ot_fixture_words("0007 0000 0001 0008 0001 0001 0000 0008 0001 0006 0001 0001 0001 000A")
  val errors: int=case+ ot_single_lookup_parse(b,ot_fixture_span(b),128) of
    | ~SingleLookupRejected(e) => 1 | ~SingleLookupAccepted(t) => let
      val e=expect(b,t,10,11) val ()=ot_single_lookup_dispose(t)
    in e end
  val ()=buf_free(b)
in errors end
fun extended_priority(): int = let
  val b=ot_fixture_words("0007 0000 0002 000A 0020 0001 0001 0000 0008 0001 0006 0001 0001 0002 000A 000B 0001 0001 0000 0008 0001 0006 0002 0001 0002 000A 000C")
  val errors=inspect(b)
  val ()=ot_fixture_put16(b,34,2)
  val rejected_mixed=rejected(b,ot_fixture_span(b),128)
  val ()=ot_fixture_put16(b,12,2)
  val rejected_other=rejected(b,ot_fixture_span(b),128)
  val ()=buf_free(b)
in errors+rejected_mixed+rejected_other end
fun mark_set(): int = let
  val b=ot_fixture_words("0001 0010 0001 000A 0003 0001 0006 0001 0001 0001 000A")
  val errors: int=case+ ot_single_lookup_parse(b,ot_fixture_span(b),128) of
    | ~SingleLookupRejected(e) => 1 | ~SingleLookupAccepted(t) => let
      val h=ot_single_lookup_header(t)
      val e=expect(b,t,10,11)
      val ()=ot_single_lookup_dispose(t)
    in iadd(e,if h.flags.useMarkSet andalso ieq(h.markSet,3) then 0 else 1) end
  val ()=buf_free(b)
in errors end
fun empty_lookup(): int = let
  val b=ot_fixture_words("0001 0000 0000")
  val errors: int=case+ ot_single_lookup_parse(b,ot_fixture_span(b),128) of
    | ~SingleLookupRejected(e) => 1 | ~SingleLookupAccepted(t) => let
      val result=ot_single_lookup_query(b,t,10)
      val h=ot_single_lookup_header(t)
      val ()=ot_single_lookup_dispose(t)
    in if not(result.matched) andalso ieq(result.glyph,10) andalso ieq(h.count,0) then 0 else 1 end
  val ()=buf_free(b)
in errors end
implement pass_test_cached() = let
  val b=fixture()
  val errors=inspect(b)+cuts(airlock_nat(isub(buf_len(b),8)),b,0)+rejected(b,ot_fixture_span(b),0)
  val ()=buf_free(b)
in errors+special(0,10)+special(65526,0)+extension()+extended_priority()+mark_set()+empty_lookup()+changed(0,2)+changed(2,32)+
  changed(8,0)+changed(24,3)+changed(28,127)+changed(30,3)+changed(36,10) end
