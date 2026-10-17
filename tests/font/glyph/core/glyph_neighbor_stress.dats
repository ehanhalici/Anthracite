#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/tables/opentype_lookup_flags.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/run/glyph_run.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/core/glyph_metadata.sats"
staload "data_font/opentype/single_lookup/ot_single_lookup_types.sats"
staload "data_font/glyph/core/glyph_neighbor_types.sats"
staload "data_font/glyph/core/glyph_neighbor.sats"
staload "font/glyph/run/glyph_run_contracts.sats"
staload "font/glyph/core/glyph_lookup_contracts.sats"
extern fun failed_nominal(): GlyphRun(0) = "mac#anth_die_box"
fun append{n:nat} .<n>. (n: int(n),run: GlyphRun(0),i: int,errors: &int >> _): GlyphRun(0) =
  if n = 0 then run else let
    val next=run_test_take(glyph_run_append(run,@{glyph=if ieq(i,32767) then 11 else 12,scalar=1614,
      sourceStart=imul(i,2),sourceEnd=imul(iadd(i,1),2),cluster=i,mask=1u}),run_test_updated,errors)
  in append(n-1,next,iadd(i,1),errors) end
fun nominal(errors: &int >> _): GlyphRun(1) = case+ glyph_run_make(3,128,WORD16_MODULUS,WORD16_SIGN_BIT) of
  | ~GlyphRunRejected(s) => glyph_run_substitute(failed_nominal())
  | ~GlyphRunCreated(run) => glyph_run_substitute(append(WORD16_SIGN_BIT,run,0,errors))
fun inspect(b: !Buf,m: !GlyphMetadata,run: !GlyphRun(1),f: OtLookupFlags): int = let
  val forward=glyph_neighbor(b,m,run,f,0,0,GlyphForward())
  val back=glyph_neighbor(b,m,run,f,0,32767,GlyphBackward())
  val ended: bool=case+ back.status of | NeighborEnd() => true | NeighborFound() => false
    | NeighborDomain() => false | NeighborReference() => false | NeighborNode() => false
  val ok=ieq(forward.node,32767) andalso ieq(forward.core.glyph,11)
    andalso ieq(forward.core.sourceEnd,WORD16_MODULUS) andalso ended
in if ok then 0 else 1 end
implement lookup_test_neighbor_stress() = let
  val b=lookup_test_fixture(0) val m=lookup_test_metadata(b,3,128)
  var errors: int=0 val run=nominal(errors)
  val extra: int=case+ ot_lookup_flags_of(8) of
    | ~FlagsRejected(e) => 1 | ~FlagsAccepted(f) => inspect(b,m,run,f)
  val ()=glyph_run_dispose(run) and ()=glyph_metadata_dispose(m) and ()=buf_free(b)
in iadd(errors,extra) end
