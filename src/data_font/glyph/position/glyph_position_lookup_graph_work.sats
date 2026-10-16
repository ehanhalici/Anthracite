staload "mem.sats"
staload "data_font/opentype/tables/opentype_types.sats"
staload "data_font/opentype/layout/ot_layout_types.sats"
staload "data_font/opentype/context/ot_context_types.sats"
staload "data_font/opentype/position_lookup/ot_position_lookup_types.sats"
staload "data_font/opentype/position_lookup/ot_position_graph_types.sats"
staload "data_font/glyph/run/glyph_run_types.sats"
staload "data_font/glyph/core/glyph_metadata_types.sats"
staload "data_font/glyph/pass/glyph_pass_types.sats"
staload "data_font/glyph/pass/glyph_pass_window_types.sats"
staload "data_font/glyph/position/glyph_position_types.sats"
staload "data_font/glyph/position/glyph_position_pair_work.sats"
staload "data_font/glyph/position/glyph_position_mark_work.sats"
staload "data_font/glyph/position/glyph_position_lookup_work.sats"
staload "data_font/glyph/position/glyph_position_lookup_graph_types.sats"
fun glyph_position_lookup_graph_empty(): GlyphPositionLookupGraphFrame
fun glyph_position_lookup_graph_enter(lookup: int,node: int): GlyphPositionLookupGraphFrame
fun glyph_position_lookup_graph_frame(old: GlyphPositionLookupGraphFrame,step: GlyphPositionLookupGraphStep): GlyphPositionLookupGraphFrame
fun glyph_position_lookup_graph_action(old: GlyphPositionLookupGraphFrame): GlyphPositionLookupGraphFrame
fun glyph_position_lookup_graph_stack_make(maximum: int): GlyphPositionLookupGraphStack
fun glyph_position_lookup_graph_stack_get(stack: !GlyphPositionLookupGraphStack,index: int): GlyphPositionLookupGraphFrame
fun glyph_position_lookup_graph_stack_set(stack: !GlyphPositionLookupGraphStack,index: int,value: GlyphPositionLookupGraphFrame): void
fun glyph_position_lookup_graph_stack_dispose(stack: GlyphPositionLookupGraphStack): void
fun glyph_position_lookup_graph_stack_reserve(stack: &GlyphPositionLookupGraphStack >> GlyphPositionLookupGraphStack,needed: int): GlyphPositionStatus
fun glyph_position_lookup_graph_capacity(lookups: int,meta: GlyphRunMeta,limits: OtContextLimits): GlyphPositionLookupGraphCapacity
fun glyph_position_lookup_graph_map_make(lookups: int,used: int,cells: int): GlyphPositionLookupGraphMap
fun glyph_position_lookup_graph_map_dispose(map: GlyphPositionLookupGraphMap): void
fun glyph_position_lookup_graph_map_build{n:nat}(b: !Buf,g: !OtPositionGraph,m: !GlyphMetadata,s: !GlyphStorage(n),
  meta: GlyphRunMeta,map: !GlyphPositionLookupGraphMap): GlyphPositionStatus
fun glyph_position_lookup_graph_map_node(map: !GlyphPositionLookupGraphMap,lookup: int,node: int,sequence: int): int
fun glyph_position_lookup_graph_check(graph: !OtPositionGraph,m: !GlyphMetadata,meta: GlyphRunMeta,lookup: int): GlyphPositionStatus
fun glyph_position_lookup_graph_validate(graph: !OtPositionGraph,m: !GlyphMetadata,meta: GlyphRunMeta): GlyphPositionStatus
fun glyph_position_lookup_graph_parents{n,k:nat}(m: !GlyphMetadata,s: !GlyphStorage(n),meta: GlyphRunMeta,
  selection: GlyphSelection,parents: !GlyphPositionBases(k)): GlyphPositionStatus
fun glyph_position_lookup_graph_parent{n,k:nat}(b: !Buf,p: !OtPositionPayload,m: !GlyphMetadata,s: !GlyphStorage(n),
  meta: GlyphRunMeta,node: int,parents: !GlyphPositionBases(k),remaining: &int >> _): GlyphMarkParent
fun glyph_position_lookup_graph_direct{n,k,r:nat}(b: !Buf,t: !OtPositionLookup,m: !GlyphMetadata,s: !GlyphStorage(n),meta: GlyphRunMeta,
  scale: GlyphScale,c: !GlyphPositionCache(k),selection: GlyphSelection,d: GlyphPositionDirection,node: int,
  parents: !GlyphPositionBases(r),remaining: &int >> _): GlyphPairStep
fun glyph_position_lookup_graph_context{n:nat}(b: !Buf,entry: !OtPositionGraphEntry,m: !GlyphMetadata,s: !GlyphStorage(n),
  meta: GlyphRunMeta,selection: GlyphSelection,node: int,w: !GlyphContextWindow,remaining: &int >> _): GlyphPositionLookupGraphStep
fun glyph_position_lookup_graph_step{n,k,r:nat}(b: !Buf,g: !OtPositionGraph,m: !GlyphMetadata,s: !GlyphStorage(n),meta: GlyphRunMeta,
  scale: GlyphScale,c: !GlyphPositionCache(k),selection: GlyphSelection,d: GlyphPositionDirection,lookup: int,node: int,
  parents: !GlyphPositionBases(r),w: !GlyphContextWindow,remaining: &int >> _): GlyphPositionLookupGraphStep
fun glyph_position_lookup_graph_completed(result: GlyphPairStep): GlyphPositionLookupGraphStep
fun glyph_position_lookup_graph_failed(status: GlyphPositionStatus,next: int): GlyphPositionLookupGraphStep
fun glyph_position_lookup_graph_window_status(status: GlyphWindowStatus): GlyphPositionStatus
fun glyph_position_lookup_graph_event_fault(status: GlyphPositionStatus): GlyphPositionLookupGraphEvent
fun glyph_position_lookup_graph_event_continue(depth: int): GlyphPositionLookupGraphEvent
fun glyph_position_lookup_graph_event_done(stack: &GlyphPositionLookupGraphStack >> GlyphPositionLookupGraphStack,active: !Buf,used: int,
  depth: int,result: GlyphPairStep): GlyphPositionLookupGraphEvent
fun glyph_position_lookup_graph_actions(b: !Buf,stack: &GlyphPositionLookupGraphStack >> GlyphPositionLookupGraphStack,map: !GlyphPositionLookupGraphMap,
  active: !Buf,used: int,depth: int): GlyphPositionLookupGraphEvent
fun glyph_position_lookup_graph_transition{n,k,r:nat}(b: !Buf,g: !OtPositionGraph,m: !GlyphMetadata,s: !GlyphStorage(n),meta: GlyphRunMeta,
  scale: GlyphScale,c: !GlyphPositionCache(k),selection: GlyphSelection,d: GlyphPositionDirection,
  parents: !GlyphPositionBases(r),w: !GlyphContextWindow,stack: &GlyphPositionLookupGraphStack >> GlyphPositionLookupGraphStack,map: !GlyphPositionLookupGraphMap,
  active: !Buf,depth: int,remaining: &int >> _): GlyphPositionLookupGraphEvent
fun glyph_position_lookup_graph_nested{n,k,r:nat}(b: !Buf,g: !OtPositionGraph,m: !GlyphMetadata,s: !GlyphStorage(n),meta: GlyphRunMeta,
  scale: GlyphScale,c: !GlyphPositionCache(k),selection: GlyphSelection,d: GlyphPositionDirection,lookup: int,node: int,
  parents: !GlyphPositionBases(r),w: !GlyphContextWindow,stack: &GlyphPositionLookupGraphStack >> GlyphPositionLookupGraphStack,map: !GlyphPositionLookupGraphMap,active: !Buf,
  remaining: &int >> _): GlyphPairStep
fun glyph_position_lookup_graph_walk{n,k,r:nat}(b: !Buf,g: !OtPositionGraph,m: !GlyphMetadata,s: !GlyphStorage(n),meta: GlyphRunMeta,
  scale: GlyphScale,c: !GlyphPositionCache(k),selection: GlyphSelection,d: GlyphPositionDirection,lookup: int,
  parents: !GlyphPositionBases(r),w: !GlyphContextWindow,stack: &GlyphPositionLookupGraphStack >> GlyphPositionLookupGraphStack,map: !GlyphPositionLookupGraphMap,active: !Buf,
  remaining: &int >> _,matches: &int >> _): GlyphPositionStatus
fun glyph_position_lookup_graph_scratch{n:nat}(b: !Buf,g: !OtPositionGraph,m: !GlyphMetadata,s: !GlyphStorage(n),meta: GlyphRunMeta,
  scale: GlyphScale,selection: GlyphSelection,d: GlyphPositionDirection,lookup: int,w: !GlyphContextWindow,
  capacity: GlyphPositionLookupGraphCapacity,matches: &int >> _): GlyphPositionStatus
