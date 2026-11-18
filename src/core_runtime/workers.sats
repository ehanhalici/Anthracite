(* Worker pool for CPU-heavy, side-effect-free jobs (line shaping, search),
   implemented in ATS2 by core_runtime/kernel/workers.dats over the root cells
   and atomics of kernel/kernel.cats.

   Lifetime: created once (text engine startup) and kept until the process
   exits; no thread is created or destroyed afterwards.

   Placement: one worker per physical core (SMT siblings are not cores), each
   pinned to its core's logical CPUs. Cores sharing the main thread's L3 come
   first, then the rest; the main thread's own core is left out. The pool is
   capped by the affinity mask and the cgroup CPU quota.

   Load: workers_active() samples /proc/stat at most every 250 ms and leaves
   out workers whose core is busy with other programs (own worker CPU time
   excluded). Idle workers steal queued jobs from other workers' rings.

   Chunks: workers_chunk_bytes() is half of a worker's share of its core's L2.

   Rings: main -> worker job rings are single-producer / multi-consumer
   (claims are a CAS on `head`); worker -> main result rings are SPSC. The
   producer and consumer indices live on separate cache lines; idle workers
   sleep on a futex word (Dekker handshake with the producer).

   Payloads are owned ATS boxes; ownership moves with the payload (the typed
   submit/take wrappers of each job kind). ANTHRACITE_WORKERS=<n> overrides the
   worker count (0 disables the pool). *)
%{#
#include "core_runtime/kernel/kernel.cats"
%}
macdef WORKER_JOB_WRAP = 0
macdef WORKER_JOB_SEARCH = 1
fun workers_ensure(): int = "ext#anth_workers_ensure"
fun workers_count(): int = "ext#anth_workers_count"
fun workers_active(): int = "ext#anth_workers_active"
fun workers_is_active(worker: int): bool = "ext#anth_workers_is_active"
fun workers_chunk_bytes(): int = "ext#anth_workers_chunk_bytes"
fun workers_has_room(worker: int): bool = "ext#anth_workers_has_room"
fun workers_queued(worker: int): int = "ext#anth_workers_queued"
fun workers_has_result(worker: int,kind: int): bool = "ext#anth_workers_has_result"
(* Raw transfer (main thread): call submit only after has_room, take only
   after has_result; misuse aborts. Typed wrappers bind anth_k_submit_box. *)
fun workers_submit(worker: int,kind: int,job: ptr): void = "ext#anth_workers_submit"
fun workers_take(worker: int,kind: int): ptr = "ext#anth_workers_take"
fun visual_next_build(): int = "ext#anth_visual_next_build"
(* Background line-shaping dispatch record (main thread only). *)
fun wrap_plan(document: ptr,build: int,start: int): int = "ext#anth_wrap_plan"
fun wrap_set_cursor(cursor: int): void = "ext#anth_wrap_set_cursor"
fun wrap_start(): int = "ext#anth_wrap_start"
(* An active worker with ring room and fewer than `cap` queued jobs, or ~1. *)
fun wrap_pick_worker(cap: int): int = "ext#anth_wrap_pick_worker"
fun workers_pick(cap: int): int = "ext#anth_workers_pick"
fun wrap_sent(worker: int): void = "ext#anth_wrap_sent"
fun wrap_received(worker: int): void = "ext#anth_wrap_received"
fun wrap_outstanding(): int = "ext#anth_wrap_outstanding"
fun wrap_disable(): void = "ext#anth_wrap_disable"
fun wrap_enabled(): bool = "ext#anth_wrap_enabled"
(* Running parallel search plan (main thread only). At most SEARCH_PLAN_CHUNKS
   chunks: the planner stops opening chunks there (the last one grows). *)
macdef SEARCH_PLAN_CHUNKS = 4096
fun search_begin(capacity: int): int = "ext#anth_search_begin"
fun search_plan_push(first_file: int): void = "ext#anth_search_plan_push"
fun search_plan_close(files: int): void = "ext#anth_search_plan_close"
fun search_generation(): int = "ext#anth_search_generation"
fun search_active(): bool = "ext#anth_search_active"
fun search_finish(): void = "ext#anth_search_finish"
fun search_chunks(): int = "ext#anth_search_chunks"
fun search_first(chunk: int): int = "ext#anth_search_first"
fun search_dispatched(): int = "ext#anth_search_dispatched"
fun search_set_dispatched(n: int): void = "ext#anth_search_set_dispatched"
fun search_merged(): int = "ext#anth_search_merged"
fun search_set_merged(n: int): void = "ext#anth_search_set_merged"
fun search_has_parked(chunk: int): bool = "ext#anth_search_has_parked"
fun search_park_raw(chunk: int,result: ptr): void = "ext#anth_search_park"
fun search_unpark_raw(chunk: int): ptr = "ext#anth_search_unpark"
fun search_parallel_enabled(): bool = "ext#anth_search_parallel_enabled"
fun search_sent(): void = "ext#anth_search_sent"
fun search_got(): void = "ext#anth_search_got"
fun search_inflight(): int = "ext#anth_search_inflight"
(* Pool sums: 0 jobs, 1 steals, 2 busy ns, 3 cycles, 4 instructions, 5 cache misses. *)
macdef WORKER_TOTAL_JOBS = 0
macdef WORKER_TOTAL_STEALS = 1
macdef WORKER_TOTAL_BUSY_NS = 2
macdef WORKER_TOTAL_CYCLES = 3
macdef WORKER_TOTAL_INSTRUCTIONS = 4
macdef WORKER_TOTAL_CACHE_MISSES = 5
fun workers_total(field: int): llint = "ext#anth_workers_total"
(* Worker thread entry (pthread start routine). *)
fun worker_main(index: ptr): ptr = "ext#anth_worker_main"
