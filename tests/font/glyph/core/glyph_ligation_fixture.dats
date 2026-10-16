#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/run/glyph_run.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/core/glyph_metadata.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/opentype/substitution/gsub_ligature_types.sats"
staload "data_font/opentype/substitution/gsub_ligatures.sats"
staload "data_font/glyph/pass/glyph_pass_ligature.sats"
staload "font/opentype/tables/opentype_fixture.sats"
staload "font/glyph/run/glyph_run_contracts.sats"
staload "font/glyph/core/glyph_ligation_contracts.sats"
staload "data_font/opentype/tables/opentype_lookup_flags.sats"
extern fun ligation_metadata_failed(): GlyphMetadata = "mac#anth_die_box"
extern fun ligation_table_failed(): GsubLigatures = "mac#anth_die_box"
extern fun ligation_run_failed(): GlyphRun(1) = "mac#anth_die_box"
extern fun ligation_flags_failed(): int = "mac#anth_die_int"
implement ligation_test_flags(code) = case+ ot_lookup_flags_of(code) of | ~FlagsAccepted(f) => f
  | ~FlagsRejected(e) => let val failed=ligation_flags_failed()
    in @{rtl=false,ignoreBase=false,ignoreLigature=false,ignoreMarks=false,useMarkSet=false,attachment=failed} end
implement ligation_test_metadata_bytes() = ot_fixture_words("0001 0000 000C 0000 0000 0000 0001 000A 0006 0001 0001 0003 0003 0002 0002")
implement ligation_test_metadata(b) = case+ glyph_metadata_parse(b,@{kind=ChildPresent(),span=ot_fixture_span(b)},3,128) of
  | ~GlyphMetadataAccepted(m) => m | ~GlyphMetadataRejected(e) => ligation_metadata_failed()
implement ligation_test_table(first,second,output) = let
  val b=ot_fixture_words("0001 0008 0001 000E 0001 0001 000A 0001 0004 000E 0002 000B")
  val ()=ot_fixture_put16(b,12,first) and ()=ot_fixture_put16(b,18,output) and ()=ot_fixture_put16(b,22,second)
in b end
implement ligation_test_parse(b) = case+ gsub_ligatures_parse(b,ot_fixture_span(b),128) of
  | ~LigaturesAccepted(t) => t | ~LigaturesRejected(e) => ligation_table_failed()
fun append{n:nat} .<n>. (left: int(n),run: GlyphRun(0),b: !Buf,i: int,errors: &int >> _): GlyphRun(0) =
  if left = 0 then run else let
    val seed: GlyphSeed= @{glyph=ot_fixture_read16(b,imul(i,2)),scalar=1576,sourceStart=imul(i,2),
      sourceEnd=imul(iadd(i,1),2),cluster=i,mask=1u}
    val next=run_test_take(glyph_run_append(run,seed),run_test_updated,errors)
  in append(left-1,next,b,iadd(i,1),errors) end
fun run(b: !Buf,count: int,errors: &int >> _): GlyphRun(1) = case+ glyph_run_make(3,128,imul(count,2),count) of
  | ~GlyphRunRejected(e) => ligation_run_failed()
  | ~GlyphRunCreated(r) => glyph_run_substitute(append(airlock_nat(count),r,b,0,errors))
implement ligation_test_run(s,errors) = let val b=ot_fixture_words(s)
  val r=run(b,idiv(isub(buf_len(b),8),2),errors) val ()=buf_free(b)
in r end
implement ligation_test_applied(run,b,m,flags,errors) = let
  val t=ligation_test_parse(b)
  val+ ~GlyphPassResult(result,status,visited,matches)=glyph_pass_ligature(b,t,m,run,ligation_test_flags(flags),0,@{kind=GlyphAll(),mask=0u})
  val ()=case+ status of | GlyphPassApplied() => () | GlyphPassDomain() => errors := iadd(errors,1)
    | GlyphPassReference() => errors := iadd(errors,1) | GlyphPassCapacity() => errors := iadd(errors,1)
  val ()=gsub_ligatures_dispose(t)
in result end
