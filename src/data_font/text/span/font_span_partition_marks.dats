#include "data_font/text/span/font_span_internal.hats"
staload "data_font/text/span/private/font_span_partition.sats"
staload "data_font/native/text/native_text_items_work.sats"
extern fun partition_failed(): void = "mac#anth_die_void"
typedef PartitionPrevious = @{started=bool,candidate=FontSpanCandidate}
fun cut(previous: PartitionPrevious,next: FontSpanCandidate): int =
  if previous.started andalso font_span_candidate_same(previous.candidate,next) then 0 else 1
fun clusters{fuel:nat} .<fuel>. (fuel: int(fuel),f: !Font,assets: !NativeTextAssets,a: !NativeTextAnalysis,
  cuts: !Buf,start: int,limit: int,previous: PartitionPrevious): void =
  if ige(start,limit) then () else if fuel = 0 then partition_failed() else let
    val finish=font_span_cluster_finish(a,start,limit)
    val item=native_text_item_read(a,start,finish) val face=font_span_candidate(f,assets,a,item)
    val ()=buf_set(cuts,start,cut(previous,face))
  in clusters(fuel-1,f,assets,a,cuts,finish,limit,@{started=true,candidate=face}) end
fun items{fuel:nat} .<fuel>. (fuel: int(fuel),f: !Font,assets: !NativeTextAssets,a: !NativeTextAnalysis,
  cuts: !Buf,start: int,limit: int): void =
  if ige(start,limit) then () else if fuel = 0 then partition_failed() else let
    val finish=native_text_item_finish(a,start)
    val initial: PartitionPrevious= @{started=false,candidate=SpanMissingCandidate()}
    val ()=clusters(MAX_REC_FUEL,f,assets,a,cuts,start,finish,initial)
  in items(fuel-1,f,assets,a,cuts,finish,limit) end
implement font_span_partition_mark(f,assets,a,cuts) =
  items(MAX_REC_FUEL,f,assets,a,cuts,0,native_text_analysis_count(a))
