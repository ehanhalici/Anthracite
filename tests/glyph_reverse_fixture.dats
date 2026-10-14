#include "glyph_reverse_test.hats"
extern fun reverse_pass_failed(): OtReverseLookup = "mac#anth_die_box"
extern fun reverse_run_failed(): GlyphRun(1) = "mac#anth_die_box"
implement reverse_pass_ready(s) = case+ s of | GlyphPassApplied() => true
  | GlyphPassDomain() => false | GlyphPassReference() => false | GlyphPassCapacity() => false
implement reverse_pass_parse(b) = case+ ot_reverse_lookup_parse(b,ot_fixture_span(b),128) of
  | ~ReverseLookupAccepted(t) => t | ~ReverseLookupRejected(e) => reverse_pass_failed()
implement reverse_pass_table() =
  ot_fixture_words("0008 0000 0001 0008 0001 000E 0000 0001 0014 0001 000B 0001 0001 000A 0001 0001 000B")
fun append{n:nat} .<n>. (left: int(n),run: GlyphRun(0),i: int,errors: &int >> int): GlyphRun(0) =
  if left = 0 then run else let
    val seed: GlyphSeed= @{glyph=if left = 1 then 11 else 10,scalar=97,sourceStart=i,
      sourceEnd=iadd(i,1),cluster=i,mask=1u}
    val next=run_test_take(glyph_run_append(run,seed),run_test_updated,errors)
  in append(left-1,next,iadd(i,1),errors) end
implement reverse_pass_run(count,errors) = case+ glyph_run_make(3,128,count,count) of
  | ~GlyphRunRejected(e) => reverse_run_failed()
  | ~GlyphRunCreated(r) => glyph_run_substitute(append(airlock_nat(count),r,0,errors))
