#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/normalization_types.sats"
staload "data_text/normalization_graph_values.sats"
staload "data_text/normalization_bounds.sats"
staload "data_text/normalization_row.sats"

implement normalization_graph_initial(row) = let
  val unmapped = not(normalization_has_mapping(row.kind))
  val canonical = if normalization_is_canonical(row.kind) then 0 else 1
in @{cp=row.cp,ccc=row.ccc,kind=row.kind,offset=row.offset,count=row.count,depth=0,
    canonical=canonical,compatibility=(if unmapped then 1 else 0),excluded=row.excluded} end

implement normalization_graph_accumulate(parent,child) = let
  val canonical = if normalization_is_canonical(parent.kind) then normalization_count_sum(parent.canonical,child.canonical) else 1
in @{cp=parent.cp,ccc=parent.ccc,kind=parent.kind,offset=parent.offset,count=parent.count,
    depth=imax(parent.depth,child.depth),canonical=canonical,
    compatibility=normalization_count_sum(parent.compatibility,child.compatibility),excluded=parent.excluded} end

implement normalization_graph_finish(row) =
  @{cp=row.cp,ccc=row.ccc,kind=row.kind,offset=row.offset,count=row.count,
    depth=iadd(row.depth,if normalization_has_mapping(row.kind) then 1 else 0),
    canonical=row.canonical,compatibility=row.compatibility,excluded=row.excluded}
