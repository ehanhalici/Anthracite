#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/normalization/normalization_types.sats"
staload "data_text/normalization/normalization_draft.sats"
staload "data_text/normalization/normalization_hangul.sats"
staload "data_text/normalization/normalization_graph.sats"
staload "data_text/normalization/normalization_graph_build.sats"
staload "data_text/normalization/normalization_graph_values.sats"

fun mapping_edge(draft: !NormalizationDraft, graph: !NormalizationGraph, parent: int, mapped: int): void = let
  val cp = normalization_draft_mapping(draft,mapped)
  val child = normalization_draft_find(draft,cp)
in if ige(child,0) then norm_graph_add(graph,child,parent) else let
    val row = normalization_draft_row(draft,parent)
    val value = normalization_leaf_info(cp)
  in normalization_draft_update(draft,parent,normalization_graph_accumulate(row,value)) end end

fun edges {n:nat} .<n>. (
  n: int(n), draft: !NormalizationDraft, graph: !NormalizationGraph, parent: int, mapped: int
): void = if n = 0 then () else let
  val () = mapping_edge(draft,graph,parent,mapped)
in edges(n-1,draft,graph,parent,iadd(mapped,1)) end

fun build_row(draft: !NormalizationDraft, graph: !NormalizationGraph, i: int): void = let
  val row = normalization_draft_row(draft,i)
  val () = normalization_draft_update(draft,i,normalization_graph_initial(row))
  val () = edges(airlock_nat(row.count),draft,graph,i,row.offset)
in if igt(norm_graph_pending(graph,i),0) then () else let
    val final = normalization_graph_finish(normalization_draft_row(draft,i))
    val () = normalization_draft_update(draft,i,final)
  in norm_graph_push(graph,i) end end

fun build {n:nat} .<n>. (n: int(n), draft: !NormalizationDraft, graph: !NormalizationGraph, i: int): void =
  if n = 0 then () else let val () = build_row(draft,graph,i) in build(n-1,draft,graph,iadd(i,1)) end

fun propagate_edge(draft: !NormalizationDraft, graph: !NormalizationGraph, edge: int, value: NormalizationRow): void = let
  val parent = norm_graph_target(graph,edge)
  val row = normalization_draft_row(draft,parent)
  val next = normalization_graph_accumulate(row,value)
  val ready = norm_graph_complete_dependency(graph,parent)
  val stored = if ready then normalization_graph_finish(next) else next
  val () = normalization_draft_update(draft,parent,stored)
in if ready then norm_graph_push(graph,parent) else () end

extern fun graph_exhausted(): void = "mac#anth_die_void"

fun propagate {n:nat} .<n>. (
  n: int(n), draft: !NormalizationDraft, graph: !NormalizationGraph, edge: int, value: NormalizationRow
): void = if ilt(edge,0) then () else if n = 0 then graph_exhausted() else let
  val () = propagate_edge(draft,graph,edge,value)
in propagate(n-1,draft,graph,norm_graph_next(graph,edge),value) end

fun queue {n:nat} .<n>. (n: int(n), draft: !NormalizationDraft, graph: !NormalizationGraph): void = let
  val node = norm_graph_pop(graph)
in if ilt(node,0) then () else if n = 0 then graph_exhausted() else let
    val value = normalization_draft_row(draft,node)
    val edge = norm_graph_head(graph,node)
    val () = propagate(airlock_nat(iadd(normalization_draft_mappings(draft),1)),draft,graph,edge,value)
  in queue(n-1,draft,graph) end end

fun lengths_valid {n:nat} .<n>. (n: int(n), draft: !NormalizationDraft, i: int): bool =
  if n = 0 then true else let
    val row = normalization_draft_row(draft,i)
  in igt(row.canonical,0) andalso igt(row.compatibility,0) andalso lengths_valid(n-1,draft,iadd(i,1)) end

implement normalization_draft_graph(draft) = let
  val n = normalization_draft_count(draft)
  val graph = norm_graph_make(n,normalization_draft_mappings(draft))
  val () = build(airlock_nat(n),draft,graph,0)
  val () = queue(airlock_nat(iadd(n,1)),draft,graph)
  val complete = ieq(norm_graph_processed(graph),n) andalso lengths_valid(airlock_nat(n),draft,0)
  val () = norm_graph_dispose(graph)
in complete end
