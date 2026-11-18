(* Literal vault search on worker threads.

   The file catalog is split into chunks that fit one worker's L2 work chunk
   (anth_workers_chunk_bytes); a file is never split, and a file larger than
   the chunk is a chunk of its own. Chunks are also kept small enough that
   every active worker gets at least two, so a slow worker cannot hold the
   search back (idle workers steal queued chunks).

   A worker reads each file from disk, matches it and records its rows as if
   the file were searched first (row 0). The main thread merges chunks in
   catalog order and applies SEARCH_RESULT_LIMIT exactly as the sequential
   search does. Files open in tabs are searched from their buffer on the main
   thread instead. *)
staload "mem.sats"
staload "search/literal/literal_search.sats"
staload "search/results/search_results.sats"
staload "search/results/search_file_cache.sats"
staload "ui_workspace/tabs/ui_tab.sats"
%{#
#include "core_runtime/kernel/kernel.cats"
%}
typedef SearchStamp = @{generation=int,chunk=int}
(* Query, case-map path, concatenated paths, file records (SEARCH_JOB_FILE_WORDS each), count. *)
datavtype SearchJob = SearchJob of (SearchStamp,Buf,Buf,Buf,Buf,int)
(* Text, metadata and jumps of all rows (row indices and text offsets relative
   to this result), file records (SEARCH_DONE_WORDS each), count. *)
datavtype SearchResult = SearchResult of (SearchStamp,Buf,Buf,Buf,Buf,int)
(* Typed transfer through the pool (kernel.cats box macros: an ATS box is a
   pointer; ownership moves with it, each slot is filled and emptied once). *)
fun search_job_submit(worker: int,job: SearchJob): void = "mac#anth_k_submit_search"
fun search_result_take(worker: int): SearchResult = "mac#anth_k_take_search"
fun search_result_park(chunk: int,result: SearchResult): void = "mac#anth_k_park_box"
fun search_result_unpark(chunk: int): SearchResult = "mac#anth_k_unpark_box"

(* Worker side: the worker keeps one compiled pattern, keyed by its query. *)
fun search_job_pattern(slot: Option_vt(LiteralPattern),key: &Buf >> _,job: !SearchJob): Option_vt(LiteralPattern)
fun search_job_run{b:bool}(slot: !option_vt(LiteralPattern,b),cache: &FileCache >> _,job: SearchJob): SearchResult

(* Main side. files: files merged this step; matched: of those, files with
   matches; truncated: some file was cut short; done: search finished. *)
typedef SearchMerged = @{files=int,matched=int,truncated=bool,done=bool}
fun search_parallel_available(): bool
fun search_parallel_begin(files: !Buf): void
fun search_parallel_step(files: !Buf,paths: !Buf,query: !Buf,case_map: !Buf,tabs: !Tabs,pattern: !LiteralPattern,
  hits: &Buf >> _,meta: &Buf >> _,jumps: &Buf >> _,rows: &int >> _): SearchMerged
(* Drops parked results and ends the run; stale in-flight results are
   discarded when they arrive (generation mismatch). *)
fun search_parallel_cancel(): void
(* Takes (and, for a finished run, disposes) results that have arrived. *)
fun search_parallel_settle(): void
