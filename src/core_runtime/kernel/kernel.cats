#ifndef ANTH_KERNEL_CATS
#define ANTH_KERNEL_CATS
/* The single C adaptor of the release runtime kernel (docs/skill.md, "Dürüst
 * Sınırlar"). It holds nothing but:
 *   - storage declarations of the process-wide root cells (statics), and
 *   - one-line, loop-free, branch-free macros: C11 atomic load / store /
 *     fetch_add / CAS on a root cell, a thread-local cell, and syscalls.
 * Every decision (indexing, bounds, summing, protocols) is ATS2 code in
 * src/core_runtime/kernel/*.dats; the ATS declarations of these macros carry
 * the static bounds, so a macro is only ever reached with a proven index. */
#include <stdatomic.h>
#include <stdalign.h>
#include <stdint.h>
#include <time.h>
#include <string.h>
#include "core_runtime/performance_ids.h"

/* ---- per-thread statistics rows (thread_stats.dats) ---- */
#define ANTH_STATS_SLOTS 128
#define ANTH_STATS_WORDS 40
#define ANTH_PHASE_SLOTS 64
_Static_assert(PERF_COUNTER_COUNT <= 29, "counters end before live, allocs, frees (words 29-31)");
_Static_assert(ANTH_STATS_WORDS == 40, "word 32 (remote frees) is alone on the row's fifth line");
_Static_assert(PERF_PHASE_COUNT <= ANTH_PHASE_SLOTS, "phase table holds every phase");
typedef struct { alignas(64) _Atomic int64_t word[ANTH_STATS_WORDS]; } AnthStatsRow;
_Static_assert(sizeof(AnthStatsRow) % 64 == 0, "a stats row fills whole cache lines");
extern AnthStatsRow anth_root_stats[ANTH_STATS_SLOTS];
extern alignas(64) _Atomic int anth_root_stats_claimed;
extern alignas(64) _Atomic int anth_root_main_claimed;
extern _Atomic int anth_root_perf_enabled;
extern volatile int anth_root_sample_tag;
/* Main-thread phase timers: [0] total ns, [1] calls, [2] max ns. */
extern uint64_t anth_root_phase[3][ANTH_PHASE_SLOTS];
extern _Thread_local int anth_tls_stats_slot; /* slot + 1, 0 = none yet */
extern _Thread_local int anth_tls_is_main;    /* 0 unknown, 1 main, 2 other */

#define ANTH_KERNEL_STATS_ROOTS() \
  AnthStatsRow anth_root_stats[ANTH_STATS_SLOTS]; alignas(64) _Atomic int anth_root_stats_claimed; \
  alignas(64) _Atomic int anth_root_main_claimed; _Atomic int anth_root_perf_enabled; \
  volatile int anth_root_sample_tag; uint64_t anth_root_phase[3][ANTH_PHASE_SLOTS]; \
  _Thread_local int anth_tls_stats_slot; _Thread_local int anth_tls_is_main;

#define anth_k_stats_load(s, k) atomic_load_explicit(&anth_root_stats[(s)].word[(k)], memory_order_relaxed)
#define anth_k_stats_store(s, k, v) atomic_store_explicit(&anth_root_stats[(s)].word[(k)], (int64_t)(v), memory_order_relaxed)
#define anth_k_stats_fetch_add(s, k, v) ((void)atomic_fetch_add_explicit(&anth_root_stats[(s)].word[(k)], (int64_t)(v), memory_order_relaxed))
#define anth_k_stats_claim() atomic_fetch_add_explicit(&anth_root_stats_claimed, 1, memory_order_relaxed)
#define anth_k_stats_claimed() atomic_load_explicit(&anth_root_stats_claimed, memory_order_relaxed)
#define anth_k_main_claim() __extension__({ int anth_k_expected = 0; atomic_compare_exchange_strong(&anth_root_main_claimed, &anth_k_expected, 1); })
#define anth_k_perf_enabled() atomic_load_explicit(&anth_root_perf_enabled, memory_order_relaxed)
#define anth_k_perf_set_enabled(v) atomic_store_explicit(&anth_root_perf_enabled, (v), memory_order_relaxed)
#define anth_k_sample_tag_set(v) ((void)(anth_root_sample_tag = (v)))
#define anth_k_sample_tag() (anth_root_sample_tag)
#define anth_k_phase_load(t, p) (anth_root_phase[(t)][(p)])
#define anth_k_phase_store(t, p, v) ((void)(anth_root_phase[(t)][(p)] = (uint64_t)(v)))
#define anth_k_tls_stats_slot() (anth_tls_stats_slot)
#define anth_k_tls_stats_set_slot(v) ((void)(anth_tls_stats_slot = (v)))
#define anth_k_tls_is_main() (anth_tls_is_main)
#define anth_k_tls_set_is_main(v) ((void)(anth_tls_is_main = (v)))

/* ---- syscalls ---- */
#define anth_k_clock_ns() __extension__({ struct timespec anth_k_ts; clock_gettime(CLOCK_MONOTONIC, &anth_k_ts); (long)anth_k_ts.tv_sec * 1000000000L + (long)anth_k_ts.tv_nsec; })

/* ---- worker pool: typed payload transfer (any module) ---- */
void anth_workers_submit(int worker, int kind, void *job);
void *anth_workers_take(int worker, int kind);
void anth_search_park(int chunk, void *result);
void *anth_search_unpark(int chunk);
/* An ATS box (job / result) is a pointer; ownership moves with it. */
#define anth_k_submit_box(w, k, x) anth_workers_submit((w), (k), (void *)(x))
#define anth_k_take_box(w, k) anth_workers_take((w), (k))
#define anth_k_park_box(c, x) anth_search_park((c), (void *)(x))
#define anth_k_unpark_box(c) anth_search_unpark((c))
#define anth_k_submit_wrap(w, x) anth_k_submit_box((w), 0, (x))
#define anth_k_take_wrap(w) anth_k_take_box((w), 0)
#define anth_k_submit_search(w, x) anth_k_submit_box((w), 1, (x))
#define anth_k_take_search(w) anth_k_take_box((w), 1)

/* ---- SIGPROF sampler: developer tool, only with -DANTHRACITE_PROFILER=ON ---- */
#ifdef ANTHRACITE_PROFILER
void anth_perf_runtime_init(void);
void anth_perf_runtime_dump(const char *tag);
#else
#define anth_perf_runtime_init() ((void)0)
#define anth_perf_runtime_dump(tag) ((void)(tag))
#endif
#endif /* ANTH_KERNEL_CATS */

/* ---- worker pool storage and syscalls (workers.dats only, _GNU_SOURCE) ---- */
#if defined(ANTH_KERNEL_POOL_IMPL) && !defined(ANTH_KERNEL_POOL_CATS)
#define ANTH_KERNEL_POOL_CATS
#include <pthread.h>
#include <sched.h>
#include <fcntl.h>
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <sys/syscall.h>
#include <sys/ioctl.h>
#include <linux/futex.h>
#include <linux/perf_event.h>
#define ANTH_POOL_MAX 32
#define ANTH_RING_SLOTS 256
#define ANTH_RINGS 3            /* 0 = jobs (main -> workers); 1 + kind = results of kind */
#define ANTH_WSTATS 8           /* jobs, steals, busy ns, sleeps, cycles, instructions, cache misses */
#define ANTH_CPU_WORDS 16       /* 1024 CPUs, the layout of glibc's cpu_set_t */
#define ANTH_CPU_SETS 8         /* topology scratch sets */
#define ANTH_REGS 64            /* main-thread registers */
#define ANTH_SEARCH_CHUNKS 4096
#define ANTH_MAX_CPUS 1024
#define ANTH_TEXT_BYTES 262144  /* sysfs / procfs read buffer (main thread) */
#define ANTH_PATH_BYTES 1024
_Static_assert(sizeof(cpu_set_t) == ANTH_CPU_WORDS * sizeof(unsigned long long), "cpu set layout");
typedef struct {
  alignas(64) _Atomic uint32_t tail; uint32_t head_cache;   /* producer line */
  alignas(64) _Atomic uint32_t head; uint32_t tail_cache;   /* consumer line */
  alignas(64) _Atomic int kind[ANTH_RING_SLOTS];
  _Atomic(void *) payload[ANTH_RING_SLOTS];
} AnthRing;
typedef struct {
  AnthRing ring[ANTH_RINGS];
  alignas(64) _Atomic uint32_t wake; _Atomic uint32_t sleeping;
  alignas(64) _Atomic uint64_t stat[ANTH_WSTATS];            /* worker writes */
  alignas(64) unsigned long long cpus[ANTH_CPU_WORDS];       /* set before start, read-only after */
  int core; int chunk;
  alignas(64) int hw_fd[3]; void *context;                   /* worker-private */
  alignas(64) pthread_t thread; clockid_t clock; int64_t cpu_ns_seen; int active; /* main-private */
} AnthWorkerRoot;
_Static_assert(sizeof(AnthRing) % 64 == 0 && sizeof(AnthWorkerRoot) % 64 == 0, "pool state fills whole cache lines");
extern AnthWorkerRoot anth_root_pool[ANTH_POOL_MAX];
extern alignas(64) _Atomic int anth_root_pool_state;        /* 0 none, 1 starting, 2 ready */
extern alignas(64) _Atomic int anth_root_visual_build;
extern alignas(64) int64_t anth_root_reg[ANTH_REGS];
extern void *anth_root_wrap_document;
extern unsigned long long anth_root_cpuset[ANTH_CPU_SETS][ANTH_CPU_WORDS];
/* /proc/stat ticks per CPU: [0] previous sample, [1] current. */
extern int64_t anth_root_cpu_busy[2][ANTH_MAX_CPUS], anth_root_cpu_total[2][ANTH_MAX_CPUS];
extern int anth_root_search_first[ANTH_SEARCH_CHUNKS + 1];
extern void *anth_root_parked[ANTH_SEARCH_CHUNKS];
extern unsigned char anth_root_text[ANTH_TEXT_BYTES];
extern char anth_root_path[ANTH_PATH_BYTES];
/* Implemented in ATS (ext#); weak identity defaults keep executables without
   job runners linkable (the pool is then never used). */
void *anth_worker_main(void *index);
void *anth_worker_context_open(void);
void anth_worker_context_free(void *context);
void *anth_worker_run_wrap(void *context, void *job);
void *anth_worker_run_search(void *context, void *job);

#define ANTH_KERNEL_POOL_ROOTS() \
  AnthWorkerRoot anth_root_pool[ANTH_POOL_MAX]; alignas(64) _Atomic int anth_root_pool_state; \
  alignas(64) _Atomic int anth_root_visual_build; alignas(64) int64_t anth_root_reg[ANTH_REGS]; \
  void *anth_root_wrap_document; unsigned long long anth_root_cpuset[ANTH_CPU_SETS][ANTH_CPU_WORDS]; \
  int64_t anth_root_cpu_busy[2][ANTH_MAX_CPUS], anth_root_cpu_total[2][ANTH_MAX_CPUS]; \
  int anth_root_search_first[ANTH_SEARCH_CHUNKS + 1]; void *anth_root_parked[ANTH_SEARCH_CHUNKS]; \
  unsigned char anth_root_text[ANTH_TEXT_BYTES]; char anth_root_path[ANTH_PATH_BYTES]; \
  __attribute__((weak)) void *anth_worker_context_open(void) { return NULL; } \
  __attribute__((weak)) void anth_worker_context_free(void *context) { (void)context; } \
  __attribute__((weak)) void *anth_worker_run_wrap(void *context, void *job) { (void)context; return job; } \
  __attribute__((weak)) void *anth_worker_run_search(void *context, void *job) { (void)context; return job; }

#define ANTH_R(w, r) (anth_root_pool[(w)].ring[(r)])
#define anth_k_ring_tail_relaxed(w, r) atomic_load_explicit(&ANTH_R(w, r).tail, memory_order_relaxed)
#define anth_k_ring_tail_acquire(w, r) atomic_load_explicit(&ANTH_R(w, r).tail, memory_order_acquire)
#define anth_k_ring_tail_release(w, r, v) atomic_store_explicit(&ANTH_R(w, r).tail, (uint32_t)(v), memory_order_release)
#define anth_k_ring_head_relaxed(w, r) atomic_load_explicit(&ANTH_R(w, r).head, memory_order_relaxed)
#define anth_k_ring_head_acquire(w, r) atomic_load_explicit(&ANTH_R(w, r).head, memory_order_acquire)
#define anth_k_ring_head_release(w, r, v) atomic_store_explicit(&ANTH_R(w, r).head, (uint32_t)(v), memory_order_release)
#define anth_k_ring_head_cas(w, r, seen, next) __extension__({ uint32_t anth_k_seen = (uint32_t)(seen); atomic_compare_exchange_strong_explicit(&ANTH_R(w, r).head, &anth_k_seen, (uint32_t)(next), memory_order_acq_rel, memory_order_acquire); })
#define anth_k_ring_head_cache(w, r) (ANTH_R(w, r).head_cache)
#define anth_k_ring_set_head_cache(w, r, v) ((void)(ANTH_R(w, r).head_cache = (uint32_t)(v)))
#define anth_k_ring_tail_cache(w, r) (ANTH_R(w, r).tail_cache)
#define anth_k_ring_set_tail_cache(w, r, v) ((void)(ANTH_R(w, r).tail_cache = (uint32_t)(v)))
#define anth_k_ring_kind(w, r, s) atomic_load_explicit(&ANTH_R(w, r).kind[(s)], memory_order_relaxed)
#define anth_k_ring_set_kind(w, r, s, v) atomic_store_explicit(&ANTH_R(w, r).kind[(s)], (v), memory_order_relaxed)
#define anth_k_ring_payload(w, r, s) atomic_load_explicit(&ANTH_R(w, r).payload[(s)], memory_order_relaxed)
#define anth_k_ring_set_payload(w, r, s, p) atomic_store_explicit(&ANTH_R(w, r).payload[(s)], (void *)(p), memory_order_relaxed)
#define anth_k_wake_bump(w) ((void)atomic_fetch_add_explicit(&anth_root_pool[(w)].wake, 1, memory_order_seq_cst))
#define anth_k_wake_load(w) atomic_load_explicit(&anth_root_pool[(w)].wake, memory_order_seq_cst)
#define anth_k_sleeping_load(w) atomic_load_explicit(&anth_root_pool[(w)].sleeping, memory_order_seq_cst)
#define anth_k_sleeping_store(w, v) atomic_store_explicit(&anth_root_pool[(w)].sleeping, (uint32_t)(v), memory_order_seq_cst)
#define anth_k_futex_wait(w, seen) ((void)syscall(SYS_futex, (uint32_t *)&anth_root_pool[(w)].wake, FUTEX_WAIT_PRIVATE, (uint32_t)(seen), NULL, NULL, 0))
#define anth_k_futex_wake(w) ((void)syscall(SYS_futex, (uint32_t *)&anth_root_pool[(w)].wake, FUTEX_WAKE_PRIVATE, 1, NULL, NULL, 0))
#define anth_k_wstat(w, f) ((long)atomic_load_explicit(&anth_root_pool[(w)].stat[(f)], memory_order_relaxed))
#define anth_k_wstat_store(w, f, v) atomic_store_explicit(&anth_root_pool[(w)].stat[(f)], (uint64_t)(v), memory_order_relaxed)
#define anth_k_cpu_word(w, i) (anth_root_pool[(w)].cpus[(i)])
#define anth_k_set_cpu_word(w, i, v) ((void)(anth_root_pool[(w)].cpus[(i)] = (v)))
#define anth_k_core(w) (anth_root_pool[(w)].core)
#define anth_k_set_core(w, v) ((void)(anth_root_pool[(w)].core = (v)))
#define anth_k_chunk(w) (anth_root_pool[(w)].chunk)
#define anth_k_set_chunk(w, v) ((void)(anth_root_pool[(w)].chunk = (v)))
#define anth_k_hw_fd(w, i) (anth_root_pool[(w)].hw_fd[(i)])
#define anth_k_set_hw_fd(w, i, v) ((void)(anth_root_pool[(w)].hw_fd[(i)] = (v)))
#define anth_k_context(w) (anth_root_pool[(w)].context)
#define anth_k_set_context(w, c) ((void)(anth_root_pool[(w)].context = (c)))
#define anth_k_cpu_ns_seen(w) ((long)anth_root_pool[(w)].cpu_ns_seen)
#define anth_k_set_cpu_ns_seen(w, v) ((void)(anth_root_pool[(w)].cpu_ns_seen = (v)))
#define anth_k_active(w) (anth_root_pool[(w)].active)
#define anth_k_set_active(w, v) ((void)(anth_root_pool[(w)].active = (v)))
#define anth_k_pool_state() atomic_load_explicit(&anth_root_pool_state, memory_order_acquire)
#define anth_k_pool_claim() __extension__({ int anth_k_expected = 0; atomic_compare_exchange_strong(&anth_root_pool_state, &anth_k_expected, 1); })
#define anth_k_pool_ready() atomic_store_explicit(&anth_root_pool_state, 2, memory_order_release)
#define anth_k_visual_next_build() (atomic_fetch_add_explicit(&anth_root_visual_build, 1, memory_order_relaxed) + 1)
#define anth_k_reg(i) ((long)anth_root_reg[(i)])
#define anth_k_set_reg(i, v) ((void)(anth_root_reg[(i)] = (int64_t)(v)))
#define anth_k_wrap_document() (anth_root_wrap_document)
#define anth_k_set_wrap_document(p) ((void)(anth_root_wrap_document = (void *)(p)))
#define anth_k_set_word(s, i) (anth_root_cpuset[(s)][(i)])
#define anth_k_set_set_word(s, i, v) ((void)(anth_root_cpuset[(s)][(i)] = (v)))
#define anth_k_cpu_busy(t, c) ((long)anth_root_cpu_busy[(t)][(c)])
#define anth_k_set_cpu_busy(t, c, v) ((void)(anth_root_cpu_busy[(t)][(c)] = (v)))
#define anth_k_cpu_total(t, c) ((long)anth_root_cpu_total[(t)][(c)])
#define anth_k_set_cpu_total(t, c, v) ((void)(anth_root_cpu_total[(t)][(c)] = (v)))
#define anth_k_search_first(i) (anth_root_search_first[(i)])
#define anth_k_set_search_first(i, v) ((void)(anth_root_search_first[(i)] = (v)))
#define anth_k_parked(i) (anth_root_parked[(i)])
#define anth_k_set_parked(i, p) ((void)(anth_root_parked[(i)] = (void *)(p)))
#define anth_k_text(i) ((int)anth_root_text[(i)])
#define anth_k_set_path_byte(i, c) ((void)(anth_root_path[(i)] = (char)(c)))
#define anth_k_path_put(off, s) ((void)memcpy(anth_root_path + (off), (s), strlen(s)))

/* syscalls */
#define anth_k_open_path() open(anth_root_path, O_RDONLY | O_CLOEXEC)
#define anth_k_read_text(fd, off, n) ((int)read((fd), anth_root_text + (off), (size_t)(n)))
#define anth_k_close(fd) ((void)close(fd))
#define anth_k_getaffinity(s) sched_getaffinity(0, sizeof(cpu_set_t), (cpu_set_t *)anth_root_cpuset[(s)])
#define anth_k_getcpu() sched_getcpu()
#define anth_k_clk_tck() ((long)sysconf(_SC_CLK_TCK))
#define anth_k_l2_bytes() ((long)sysconf(_SC_LEVEL2_CACHE_SIZE))
#define anth_k_thread_start(w) pthread_create(&anth_root_pool[(w)].thread, NULL, anth_worker_main, (void *)(intptr_t)(w))
#define anth_k_thread_clock(w) ((void)pthread_getcpuclockid(anth_root_pool[(w)].thread, &anth_root_pool[(w)].clock))
#define anth_k_thread_cpu_ns(w) __extension__({ struct timespec anth_k_ts = {0, 0}; clock_gettime(anth_root_pool[(w)].clock, &anth_k_ts); (long)anth_k_ts.tv_sec * 1000000000L + (long)anth_k_ts.tv_nsec; })
#define anth_k_pin_self(w) ((void)pthread_setaffinity_np(pthread_self(), sizeof(cpu_set_t), (cpu_set_t *)anth_root_pool[(w)].cpus))
#define anth_k_worker_index(arg) ((int)(intptr_t)(arg))
#define anth_k_yield() ((void)sched_yield())
#define anth_k_pause() __builtin_ia32_pause()
#define anth_k_sleep_us(us) ((void)usleep((useconds_t)(us)))
#define anth_k_hw_open(cfg) __extension__({ struct perf_event_attr anth_k_a = {0}; anth_k_a.size = sizeof(anth_k_a); anth_k_a.type = PERF_TYPE_HARDWARE; anth_k_a.config = (uint64_t)(cfg); anth_k_a.disabled = 1; anth_k_a.exclude_kernel = 1; anth_k_a.exclude_hv = 1; (int)syscall(SYS_perf_event_open, &anth_k_a, 0, -1, -1, 0); })
#define anth_k_hw_enable(fd) ((void)ioctl((fd), PERF_EVENT_IOC_ENABLE, 0))
#define anth_k_hw_disable(fd) ((void)ioctl((fd), PERF_EVENT_IOC_DISABLE, 0))
#define anth_k_hw_read(fd) __extension__({ uint64_t anth_k_v = 0; (void)!read((fd), &anth_k_v, sizeof(anth_k_v)); (long)anth_k_v; })
#define anth_k_die(msg) (fprintf(stderr, "anthracite: worker pool misuse: %s\n", (msg)), abort())
#define anth_k_run_wrap(c, j) anth_worker_run_wrap((c), (j))
#define anth_k_run_search(c, j) anth_worker_run_search((c), (j))
#define anth_k_context_open() anth_worker_context_open()
#endif /* ANTH_KERNEL_POOL_IMPL */

/* ---- arena allocator storage and syscalls (arena.dats only) ---- */
#if defined(ANTH_KERNEL_ARENA_IMPL) && !defined(ANTH_KERNEL_ARENA_CATS)
#define ANTH_KERNEL_ARENA_CATS
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <unistd.h>
#ifndef MADV_POPULATE_WRITE
#define MADV_POPULATE_WRITE 23
#endif
#define ANTH_ARENA_HEAPS 128
#define ANTH_NCLASS 40
#define ANTH_SEG_PAGES 32
#define ANTH_LARGE_BUCKETS 64
#define ANTH_CLASS_INDEX 2049
#define ANTH_SEG_SHIFT 21
typedef struct {
  uint32_t magic; uint32_t kind; int owner; int next_free; /* owner heap, next cached span (segment + 1, 0 = none) */
  int64_t span; int64_t usable;
  uint8_t page_class[ANTH_SEG_PAGES];
} AnthSegHeader;
_Static_assert(sizeof(AnthSegHeader) <= 65536, "segment header fits page 0");
typedef struct {
  /* Owner-only. */
  alignas(64) void *free_list[ANTH_NCLASS];
  int64_t bump[ANTH_NCLASS], bump_end[ANTH_NCLASS];          /* arena offsets */
  int segment; int next_page; int index;
  int owner_slot; /* owner's stats slot + 1: set once, read by every freeing thread */
  /* Owner writes, statistics read: relaxed atomics, no RMW. */
  _Atomic uint64_t remote_frees; _Atomic uint64_t segments;
  /* Written by other threads: alone on its own line. */
  alignas(64) _Atomic(void *) remote;
} AnthHeapRoot;
_Static_assert(sizeof(AnthHeapRoot) % 64 == 0, "a heap fills whole cache lines");
extern AnthHeapRoot anth_root_heaps[ANTH_ARENA_HEAPS];
extern char *anth_root_arena_base;
extern void *anth_root_arena_raw;
extern int64_t anth_root_arena_reserve;
extern int anth_root_arena_enabled;
extern alignas(64) _Atomic int64_t anth_root_arena_next;
extern alignas(64) _Atomic int64_t anth_root_arena_committed;
extern alignas(64) _Atomic int anth_root_arena_state;      /* 0 none, 1 starting, 2 ready */
extern _Atomic int anth_root_heap_count;
extern _Atomic uint64_t anth_root_libc_fallback;
extern pthread_mutex_t anth_root_arena_lock[3];            /* commit, large spans, abandoned heaps */
extern int anth_root_large_free[ANTH_LARGE_BUCKETS + 1];
extern int anth_root_abandoned[ANTH_ARENA_HEAPS];
extern int anth_root_abandoned_count;
extern uint16_t anth_root_class_size[ANTH_NCLASS];
extern uint8_t anth_root_class_of[ANTH_CLASS_INDEX];
extern pthread_key_t anth_root_heap_key;
extern _Thread_local int anth_tls_heap;                     /* heap + 1, 0 = none */
extern _Thread_local int anth_tls_freed_slot;               /* see arena_freed_slot */
void anth_arena_heap_abandon(void *value);
void *anth_arena_populate(void *bytes);
/* Cold ATS2 slow paths (arena.dats): declared cold and out of line so the
 * ready / heap checks of the allocation fast path inline at every call. */
__attribute__((cold, noinline)) void anth_arena_start_init(void);
__attribute__((cold, noinline)) int anth_arena_first_heap(void);

#define ANTH_KERNEL_ARENA_ROOTS() \
  AnthHeapRoot anth_root_heaps[ANTH_ARENA_HEAPS]; char *anth_root_arena_base; void *anth_root_arena_raw; \
  int64_t anth_root_arena_reserve; int anth_root_arena_enabled; alignas(64) _Atomic int64_t anth_root_arena_next; \
  alignas(64) _Atomic int64_t anth_root_arena_committed; alignas(64) _Atomic int anth_root_arena_state; \
  _Atomic int anth_root_heap_count; _Atomic uint64_t anth_root_libc_fallback; \
  pthread_mutex_t anth_root_arena_lock[3] = {PTHREAD_MUTEX_INITIALIZER, PTHREAD_MUTEX_INITIALIZER, PTHREAD_MUTEX_INITIALIZER}; \
  int anth_root_large_free[ANTH_LARGE_BUCKETS + 1]; int anth_root_abandoned[ANTH_ARENA_HEAPS]; int anth_root_abandoned_count; \
  uint16_t anth_root_class_size[ANTH_NCLASS]; uint8_t anth_root_class_of[ANTH_CLASS_INDEX]; pthread_key_t anth_root_heap_key; \
  _Thread_local int anth_tls_heap; _Thread_local int anth_tls_freed_slot;

#define ANTH_SEG(s) ((AnthSegHeader *)(anth_root_arena_base + ((int64_t)(s) << ANTH_SEG_SHIFT)))
#define ANTH_H(h) (anth_root_heaps[(h)])
#define anth_k_seg_reset(s) ((void)memset(ANTH_SEG(s), 0, sizeof(AnthSegHeader)))
#define anth_k_seg_magic(s) ((int)ANTH_SEG(s)->magic)
#define anth_k_seg_set_magic(s, v) ((void)(ANTH_SEG(s)->magic = (uint32_t)(v)))
#define anth_k_seg_kind(s) ((int)ANTH_SEG(s)->kind)
#define anth_k_seg_set_kind(s, v) ((void)(ANTH_SEG(s)->kind = (uint32_t)(v)))
#define anth_k_seg_owner(s) (ANTH_SEG(s)->owner)
#define anth_k_seg_set_owner(s, v) ((void)(ANTH_SEG(s)->owner = (v)))
#define anth_k_seg_next(s) (ANTH_SEG(s)->next_free)
#define anth_k_seg_set_next(s, v) ((void)(ANTH_SEG(s)->next_free = (v)))
#define anth_k_seg_span(s) ((long)ANTH_SEG(s)->span)
#define anth_k_seg_set_span(s, v) ((void)(ANTH_SEG(s)->span = (v)))
#define anth_k_seg_usable(s) ((long)ANTH_SEG(s)->usable)
#define anth_k_seg_set_usable(s, v) ((void)(ANTH_SEG(s)->usable = (v)))
#define anth_k_seg_class(s, p) ((int)ANTH_SEG(s)->page_class[(p)])
#define anth_k_seg_set_class(s, p, c) ((void)(ANTH_SEG(s)->page_class[(p)] = (uint8_t)(c)))
#define anth_k_heap_free(h, c) (ANTH_H(h).free_list[(c)])
#define anth_k_heap_set_free(h, c, p) ((void)(ANTH_H(h).free_list[(c)] = (p)))
#define anth_k_heap_bump(h, c) ((long)ANTH_H(h).bump[(c)])
#define anth_k_heap_set_bump(h, c, v) ((void)(ANTH_H(h).bump[(c)] = (v)))
#define anth_k_heap_bump_end(h, c) ((long)ANTH_H(h).bump_end[(c)])
#define anth_k_heap_set_bump_end(h, c, v) ((void)(ANTH_H(h).bump_end[(c)] = (v)))
#define anth_k_heap_segment(h) (ANTH_H(h).segment)
#define anth_k_heap_set_segment(h, v) ((void)(ANTH_H(h).segment = (v)))
#define anth_k_heap_next_page(h) (ANTH_H(h).next_page)
#define anth_k_heap_set_next_page(h, v) ((void)(ANTH_H(h).next_page = (v)))
#define anth_k_heap_set_index(h, v) ((void)(ANTH_H(h).index = (v)))
#define anth_k_heap_remote_frees(h) ((long)atomic_load_explicit(&ANTH_H(h).remote_frees, memory_order_relaxed))
#define anth_k_heap_set_remote_frees(h, v) atomic_store_explicit(&ANTH_H(h).remote_frees, (uint64_t)(v), memory_order_relaxed)
#define anth_k_heap_segments(h) ((long)atomic_load_explicit(&ANTH_H(h).segments, memory_order_relaxed))
#define anth_k_heap_set_segments(h, v) atomic_store_explicit(&ANTH_H(h).segments, (uint64_t)(v), memory_order_relaxed)
#define anth_k_heap_remote_take(h) atomic_exchange_explicit(&ANTH_H(h).remote, NULL, memory_order_acquire)
#define anth_k_heap_remote_load(h) atomic_load_explicit(&ANTH_H(h).remote, memory_order_relaxed)
#define anth_k_heap_remote_cas(h, seen, p) __extension__({ void *anth_k_seen = (seen); atomic_compare_exchange_weak_explicit(&ANTH_H(h).remote, &anth_k_seen, (p), memory_order_release, memory_order_relaxed); })
#define anth_k_heap_owner_slot(h) (ANTH_H(h).owner_slot)
#define anth_k_heap_set_owner_slot(h, v) ((void)(ANTH_H(h).owner_slot = (v)))
#define anth_k_heap_address(h) ((void *)&ANTH_H(h))
#define anth_k_heap_bytes() ((long)sizeof(AnthHeapRoot))
#define anth_k_block_next(p) (*(void **)(p))
#define anth_k_block_set_next(p, q) ((void)(*(void **)(p) = (q)))
#define anth_k_ptr_off(p) ((long)((uintptr_t)(p) - (uintptr_t)anth_root_arena_base))
#define anth_k_off_ptr(o) ((void *)(anth_root_arena_base + (o)))
#define anth_k_class_size(c) ((int)anth_root_class_size[(c)])
#define anth_k_set_class_size(c, v) ((void)(anth_root_class_size[(c)] = (uint16_t)(v)))
#define anth_k_class_of(i) ((int)anth_root_class_of[(i)])
#define anth_k_set_class_of(i, v) ((void)(anth_root_class_of[(i)] = (uint8_t)(v)))
#define anth_k_large_free(b) (anth_root_large_free[(b)])
#define anth_k_set_large_free(b, s) ((void)(anth_root_large_free[(b)] = (s)))
#define anth_k_abandoned(i) (anth_root_abandoned[(i)])
#define anth_k_set_abandoned(i, h) ((void)(anth_root_abandoned[(i)] = (h)))
#define anth_k_abandoned_count() (anth_root_abandoned_count)
#define anth_k_set_abandoned_count(n) ((void)(anth_root_abandoned_count = (n)))
#define anth_k_arena_enabled() (anth_root_arena_enabled)
#define anth_k_arena_set_enabled(v) ((void)(anth_root_arena_enabled = (v)))
#define anth_k_arena_reserve() ((long)anth_root_arena_reserve)
#define anth_k_arena_set_reserve(v) ((void)(anth_root_arena_reserve = (v)))
#define anth_k_arena_next_add(n) ((long)atomic_fetch_add_explicit(&anth_root_arena_next, (n), memory_order_relaxed))
#define anth_k_committed_acquire() ((long)atomic_load_explicit(&anth_root_arena_committed, memory_order_acquire))
#define anth_k_committed_relaxed() ((long)atomic_load_explicit(&anth_root_arena_committed, memory_order_relaxed))
#define anth_k_committed_release(v) atomic_store_explicit(&anth_root_arena_committed, (v), memory_order_release)
#define anth_k_arena_state() atomic_load_explicit(&anth_root_arena_state, memory_order_acquire)
#define anth_k_arena_claim() __extension__({ int anth_k_expected = 0; atomic_compare_exchange_strong(&anth_root_arena_state, &anth_k_expected, 1); })
#define anth_k_arena_ready() atomic_store_explicit(&anth_root_arena_state, 2, memory_order_release)
#define anth_k_heap_count_add() atomic_fetch_add_explicit(&anth_root_heap_count, 1, memory_order_relaxed)
#define anth_k_heap_count() atomic_load_explicit(&anth_root_heap_count, memory_order_relaxed)
#define anth_k_libc_fallback_add() ((void)atomic_fetch_add_explicit(&anth_root_libc_fallback, 1, memory_order_relaxed))
#define anth_k_libc_fallback() ((long)atomic_load_explicit(&anth_root_libc_fallback, memory_order_relaxed))
#define anth_k_lock(i) ((void)pthread_mutex_lock(&anth_root_arena_lock[(i)]))
#define anth_k_unlock(i) ((void)pthread_mutex_unlock(&anth_root_arena_lock[(i)]))
#define anth_k_tls_heap() (anth_tls_heap)
#define anth_k_tls_set_heap(v) ((void)(anth_tls_heap = (v)))
#define anth_k_tls_freed_slot() (anth_tls_freed_slot)
#define anth_k_tls_set_freed_slot(v) ((void)(anth_tls_freed_slot = (v)))
#define anth_k_heap_key_create() ((void)pthread_key_create(&anth_root_heap_key, anth_arena_heap_abandon))
#define anth_k_heap_key_set(v) ((void)pthread_setspecific(anth_root_heap_key, (void *)(intptr_t)(v)))
#define anth_k_key_value(p) ((int)(intptr_t)(p))
#define anth_k_phys_bytes() ((long)sysconf(_SC_PHYS_PAGES) * (long)sysconf(_SC_PAGESIZE))
#define anth_k_map_reserve(n) mmap(NULL, (size_t)(n), PROT_NONE, MAP_PRIVATE | MAP_ANONYMOUS | MAP_NORESERVE, -1, 0)
#define anth_k_map_failed(p) ((p) == MAP_FAILED)
#define anth_k_unmap(p, n) ((void)munmap((p), (size_t)(n)))
#define anth_k_set_raw(p) ((void)(anth_root_arena_raw = (p)))
#define anth_k_raw_off_aligned(p) ((long)((((uintptr_t)(p) + ((uintptr_t)1 << ANTH_SEG_SHIFT) - 1) & ~(((uintptr_t)1 << ANTH_SEG_SHIFT) - 1)) - (uintptr_t)(p)))
#define anth_k_set_base(p, off) ((void)(anth_root_arena_base = (char *)(p) + (off)))
#define anth_k_protect(off, n) mprotect(anth_root_arena_base + (off), (size_t)(n), PROT_READ | PROT_WRITE)
#define anth_k_hugepage(off, n) ((void)madvise(anth_root_arena_base + (off), (size_t)(n), MADV_HUGEPAGE))
#define anth_k_populate(n) ((void)madvise(anth_root_arena_base, (size_t)(n), MADV_POPULATE_WRITE))
#define anth_k_populate_start(n) __extension__({ pthread_t anth_k_t; pthread_attr_t anth_k_at; pthread_attr_init(&anth_k_at); pthread_attr_setdetachstate(&anth_k_at, PTHREAD_CREATE_DETACHED); (void)pthread_create(&anth_k_t, &anth_k_at, anth_arena_populate, (void *)(intptr_t)(n)); pthread_attr_destroy(&anth_k_at); })
#define anth_k_populate_bytes(p) ((long)(intptr_t)(p))
#define anth_k_libc_malloc(n) malloc((size_t)(n))
#define anth_k_libc_realloc(p, n) realloc((p), (size_t)(n))
#define anth_k_libc_free(p) free(p)
#define anth_k_zero(p, n) ((void)memset((p), 0, (size_t)(n)))
#define anth_k_copy(d, s, n) ((void)memcpy((d), (s), (size_t)(n)))
#define anth_k_size_lint(n) ((long)(n))
#define anth_k_lint_size(n) ((size_t)(n))
#define anth_k_size_max() ((long)PTRDIFF_MAX)
#define anth_k_arena_die(msg) (fprintf(stderr, "anthracite: arena invariant violated: %s\n", (msg)), abort())
#endif /* ANTH_KERNEL_ARENA_IMPL */
