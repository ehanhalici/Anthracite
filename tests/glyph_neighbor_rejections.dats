#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_font/opentype_types.sats"
staload "data_font/opentype_lookup_flags.sats"
staload "data_font/glyph_run_types.sats"
staload "data_font/glyph_run.sats"
staload "data_font/glyph_metadata_types.sats"
staload "data_font/glyph_metadata.sats"
staload "data_font/ot_single_lookup_types.sats"
staload "data_font/glyph_neighbor_types.sats"
staload "data_font/glyph_neighbor.sats"
staload "glyph_pass_contracts.sats"
staload "glyph_lookup_contracts.sats"
fun inspect(b: !Buf,m: !GlyphMetadata,run: !GlyphRun(1),f: OtLookupFlags): int = let
  val invalid=glyph_neighbor(b,m,run,f,0,6,GlyphForward())
  val negative=glyph_neighbor(b,m,run,f,0,~1,GlyphBackward())
  val reference=glyph_neighbor(b,m,run,f,1,0,GlyphForward())
  val bad_node: bool=case+ invalid.status of | NeighborNode() => true | NeighborFound() => false
    | NeighborEnd() => false | NeighborDomain() => false | NeighborReference() => false
  val bad_negative: bool=case+ negative.status of | NeighborNode() => true | NeighborFound() => false
    | NeighborEnd() => false | NeighborDomain() => false | NeighborReference() => false
  val bad_reference: bool=case+ reference.status of | NeighborReference() => true | NeighborFound() => false
    | NeighborEnd() => false | NeighborDomain() => false | NeighborNode() => false
in if bad_node andalso bad_negative andalso bad_reference then 0 else 1 end
fun foreign(b: !Buf,run: !GlyphRun(1),f: OtLookupFlags): int = let
  val m=lookup_test_metadata(b,4,128)
  val result=glyph_neighbor(b,m,run,f,0,0,GlyphForward())
  val rejected: bool=case+ result.status of | NeighborDomain() => true | NeighborFound() => false
    | NeighborEnd() => false | NeighborReference() => false | NeighborNode() => false
  val ()=glyph_metadata_dispose(m)
in if rejected then 0 else 1 end
implement lookup_test_neighbor_rejections() = let
  val b=lookup_test_fixture(0) val m=lookup_test_metadata(b,3,128)
  val run=pass_test_run(6)
  val errors: int=case+ ot_lookup_flags_of(16) of
    | ~FlagsRejected(e) => 1 | ~FlagsAccepted(f) => inspect(b,m,run,f)+foreign(b,run,f)
  val positioned=glyph_run_position(run)
  val phase_errors: int=case+ ot_lookup_flags_of(8) of
    | ~FlagsRejected(e) => 1 | ~FlagsAccepted(f) => let
      val result=glyph_neighbor(b,m,positioned,f,0,1,GlyphForward())
    in if ieq(result.node,3) andalso ieq(result.core.glyph,13) then 0 else 1 end
  val ()=glyph_run_dispose(positioned) and ()=glyph_metadata_dispose(m) and ()=buf_free(b)
in iadd(errors,phase_errors) end
