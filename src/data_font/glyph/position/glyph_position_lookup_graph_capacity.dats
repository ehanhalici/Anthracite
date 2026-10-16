#include "data_font/glyph/position/glyph_position_lookup_graph_internal.hats"
fun domain(lookups: int,used: int,limits: OtContextLimits): bool =
  ige(lookups,0) andalso ile(lookups,WORD16_MAX_VALUE) andalso ige(used,0) andalso ile(used,MAX_REC_FUEL)
    andalso ige(limits.back,0) andalso ile(limits.back,WORD16_MAX_VALUE)
    andalso ige(limits.input,1) andalso ile(limits.input,WORD16_MAX_VALUE)
    andalso ige(limits.look,0) andalso ile(limits.look,WORD16_MAX_VALUE)
fun budget(lookups: int,meta: GlyphRunMeta,limits: OtContextLimits): GlyphPositionLookupGraphCapacity = let
  val cells=g0int2int_int_llint(lookups)*g0int2int_int_llint(meta.used)
  val window=g0int2int_int_llint(limits.back)+g0int2int_int_llint(limits.input)+g0int2int_int_llint(limits.look)
  val cost=cells*12LL+g0int2int_int_llint(lookups)*4LL
    +g0int2int_int_llint(meta.used)*g0int2int_int_llint(g0uint2int_size_int(sizeof<GlyphPosition>)+4)+window*8LL
  val frameBytes=g0int2int_int_llint(g0uint2int_size_int(sizeof<GlyphPositionLookupGraphFrame>))*2LL
  val available=g0int2int_int_llint(MAX_REC_FUEL)-cost
in if available < frameBytes then @{status=PositionCapacity(),cells=0,frames=0} else let
  val capacity=available/frameBytes
  val frames=if capacity < cells+1LL then capacity else cells+1LL
in @{status=PositionReady(),cells=airlock_i32(cells),frames=airlock_i32(frames)} end end
implement glyph_position_lookup_graph_capacity(lookups,meta,limits) =
  if not(domain(lookups,meta.used,limits)) then @{status=PositionReference(),cells=0,frames=0} else budget(lookups,meta,limits)
