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
staload "glyph_run_contracts.sats"
staload "glyph_pass_contracts.sats"
staload "glyph_lookup_contracts.sats"
fun sparse(errors: &int >> _): GlyphRun(1) = let
  val outputs=run_test_indices(20,21)
  val first=run_test_take(glyph_run_multiple(pass_test_run(6),0,outputs,2),run_test_updated,errors)
  val nodes=run_test_indices(1,3)
  val second=run_test_take(glyph_run_ligate(first,nodes,2,22),run_test_updated,errors)
  val ()=buf_free(outputs) and ()=buf_free(nodes)
in second end
fun inspect(b: !Buf,m: !GlyphMetadata,run: !GlyphRun(1),f: OtLookupFlags): int = let
  val first=glyph_neighbor(b,m,run,f,0,0,GlyphForward())
  val gap=glyph_neighbor(b,m,run,f,0,1,GlyphForward())
  val reverse=glyph_neighbor(b,m,run,f,0,4,GlyphBackward())
  val removed=glyph_neighbor(b,m,run,f,0,3,GlyphForward())
  val gone: bool=case+ removed.status of | NeighborNode() => true | NeighborFound() => false
    | NeighborEnd() => false | NeighborDomain() => false | NeighborReference() => false
  val ok=ieq(first.node,6) andalso ieq(first.core.glyph,21) andalso ieq(gap.node,4)
    andalso ieq(reverse.node,1) andalso ieq(reverse.core.glyph,22) andalso gone
in if ok then 0 else 1 end
implement lookup_test_neighbor_sparse() = let
  val b=lookup_test_fixture(0) val m=lookup_test_metadata(b,3,128)
  var errors: int=0
  val run=sparse(errors)
  val extra: int=case+ ot_lookup_flags_of(8) of
    | ~FlagsRejected(e) => 1 | ~FlagsAccepted(f) => inspect(b,m,run,f)
  val ()=glyph_run_dispose(run) and ()=glyph_metadata_dispose(m) and ()=buf_free(b)
in iadd(errors,extra) end
