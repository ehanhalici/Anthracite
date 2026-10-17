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
staload "font/glyph/pass/glyph_pass_contracts.sats"
staload "font/glyph/core/glyph_lookup_contracts.sats"
fun expect(v: GlyphNeighbor,node: int,glyph: int): int = case+ v.status of
  | NeighborFound() => if ieq(v.node,node) andalso ieq(v.core.glyph,glyph) then 0 else 1
  | NeighborEnd() => 1 | NeighborDomain() => 1 | NeighborReference() => 1 | NeighborNode() => 1
fun ended(v: GlyphNeighbor): int = case+ v.status of
  | NeighborFound() => 1 | NeighborEnd() => if ieq(v.node,~1) then 0 else 1
  | NeighborDomain() => 1 | NeighborReference() => 1 | NeighborNode() => 1
fun one(b: !Buf,m: !GlyphMetadata,run: !GlyphRun(1),raw: int,node: int,travel: GlyphTravel,found: int,glyph: int): int =
  case+ ot_lookup_flags_of(raw) of
  | ~FlagsRejected(e) => 1 | ~FlagsAccepted(f) => expect(glyph_neighbor(b,m,run,f,0,node,travel),found,glyph)
fun end_at(b: !Buf,m: !GlyphMetadata,run: !GlyphRun(1),raw: int,node: int,travel: GlyphTravel): int =
  case+ ot_lookup_flags_of(raw) of
  | ~FlagsRejected(e) => 1 | ~FlagsAccepted(f) => ended(glyph_neighbor(b,m,run,f,0,node,travel))
fun ordered(b: !Buf,m: !GlyphMetadata,run: !GlyphRun(1)): int =
  one(b,m,run,8,1,GlyphForward(),3,13)+one(b,m,run,9,1,GlyphForward(),3,13)+
  one(b,m,run,8,3,GlyphBackward(),1,11)+one(b,m,run,4,1,GlyphForward(),2,12)+
  one(b,m,run,2,0,GlyphForward(),1,11)+end_at(b,m,run,2,1,GlyphBackward())+
  one(b,m,run,14,0,GlyphForward(),3,13)+one(b,m,run,14,3,GlyphForward(),4,14)+
  end_at(b,m,run,14,4,GlyphForward())+one(b,m,run,528,3,GlyphBackward(),2,12)+end_at(b,m,run,528,4,GlyphForward())
implement lookup_test_neighbors() = let
  val b=lookup_test_fixture(0) val m=lookup_test_metadata(b,3,128)
  val run=pass_test_run(6)
  val errors=ordered(b,m,run)
  val ()=glyph_run_dispose(run) and ()=glyph_metadata_dispose(m) and ()=buf_free(b)
in errors end
