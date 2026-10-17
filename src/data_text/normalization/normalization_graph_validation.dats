#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/normalization/normalization_types.sats"
staload "data_text/normalization/normalization_validation.sats"
staload "data_text/normalization/normalization_graph_values.sats"
staload "data_text/normalization/normalization_row.sats"
staload "data_text/normalization/normalization_data.sats"

fun children {n:nat} .<n>. (
  n: int(n), data: !NormalizationData, i: int, depth: int, accumulated: NormalizationRow
): NormalizationRow = if n = 0 then accumulated else let
  val child = normalization_info(data,normalization_mapping(data,i))
  val valid = ilt(child.depth,depth)
  val next = if valid then normalization_graph_accumulate(accumulated,child) else
    @{cp=accumulated.cp,ccc=accumulated.ccc,kind=accumulated.kind,offset=accumulated.offset,count=accumulated.count,
      depth=depth,canonical= ~1,compatibility= ~1,excluded=accumulated.excluded}
in children(n-1,data,iadd(i,1),depth,next) end

fun graph_row_valid(data: !NormalizationData, row: NormalizationRow): bool =
  if not(normalization_has_mapping(row.kind)) then true else let
    val initial = normalization_graph_initial(row)
    val value = children(airlock_nat(row.count),data,row.offset,row.depth,initial)
    val final = normalization_graph_finish(value)
  in ieq(row.depth,final.depth) andalso ieq(row.canonical,final.canonical)
    andalso ieq(row.compatibility,final.compatibility) end

fun rows {n:nat} .<n>. (n: int(n), data: !NormalizationData, i: int): bool =
  if n = 0 then true else let
    val+ NormalizationData(bytes,h) = data
    val at = iadd(NORMALIZATION_HEADER_WORDS,imul(i,NORMALIZATION_ROW_WORDS))
    val row = normalization_row_read(bytes,at)
  in graph_row_valid(data,row) andalso rows(n-1,data,iadd(i,1)) end

implement normalization_graph_valid(data) = let
  val header = normalization_header(data)
in rows(airlock_nat(header.rows),data,0) end
