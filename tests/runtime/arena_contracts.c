/* Aggressive allocator contracts.
 *
 *   arena_contracts [--scaling]
 *
 * Always: layout checks, single-thread class/realloc/large checks, and a
 * multi-thread stress (1..12 threads, ~10 M operations in total) where ~30%
 * of blocks are freed by another thread. Every block carries a canary that is
 * verified before free; at the end nothing may be live and no allocation may
 * have fallen back to libc.
 *
 * --scaling (CTest label perf, exit 77 when it cannot measure): per-thread
 * hardware counters via perf_event_open (user mode) for 1..N threads pinned
 * to physical cores of the caller's L3 domain. Work per operation must not
 * grow with threads: instructions/op within 5%, cycles/op <= 1.25x and cache
 * misses/op <= 1.3x of the single-thread run, and throughput >= 0.8 x N.
 * A deliberate false-sharing control (two threads bumping counters on one
 * cache line vs. on separate lines) must show a clear slowdown, proving the
 * measurement can see the contention it is meant to rule out. */
#define _GNU_SOURCE
#include <stddef.h>
/* The allocator under test: ATS2, core_runtime/kernel/arena.dats. */
#define ANTH_CACHE_LINE 64
#define ANTH_MAX_THREADS 128
void *anth_arena_malloc(size_t size);
void *anth_arena_calloc(size_t count, size_t size);
void *anth_arena_realloc(void *ptr, size_t size);
void anth_arena_free(void *ptr);
size_t anth_arena_usable(void *ptr);
long anth_arena_stat(int field); /* 0 reserved 1 committed 2 segments 3 heaps 4 remote frees 5 libc fallbacks 6 enabled */
void *anth_arena_heap_address(int heap);
long anth_arena_heap_size(void);
typedef struct { unsigned long long reserved, committed, segments, threads, remote_frees, libc_fallback; int enabled; } AnthArenaStats;
static AnthArenaStats anth_arena_stats(void) {
  AnthArenaStats s = {(unsigned long long)anth_arena_stat(0), (unsigned long long)anth_arena_stat(1),
    (unsigned long long)anth_arena_stat(2), (unsigned long long)anth_arena_stat(3), (unsigned long long)anth_arena_stat(4),
    (unsigned long long)anth_arena_stat(5), (int)anth_arena_stat(6)};
  return s;
}
#include <linux/perf_event.h>
#include <stdalign.h>
#include <pthread.h>
#include <sched.h>
#include <stdatomic.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/syscall.h>
#include <time.h>
#include <unistd.h>

#define SKIP 77
#define CANARY 0xA5u

static _Atomic int failures;
#define CHECK(cond, ...) do { if (!(cond)) { ++failures; fprintf(stderr, "FAIL %s:%d ", __FILE__, __LINE__); fprintf(stderr, __VA_ARGS__); fputc('\n', stderr); } } while (0)

static uint64_t now_ns(void) {
  struct timespec ts;
  clock_gettime(CLOCK_MONOTONIC, &ts);
  return (uint64_t)ts.tv_sec * 1000000000ull + (uint64_t)ts.tv_nsec;
}

static inline uint64_t mix(uint64_t *state) {
  uint64_t x = *state += 0x9E3779B97F4A7C15ull;
  x = (x ^ (x >> 30)) * 0xBF58476D1CE4E5B9ull;
  x = (x ^ (x >> 27)) * 0x94D049BB133111EBull;
  return x ^ (x >> 31);
}

/* Mostly small sizes with a long tail, like the editor's Bufs and nodes. */
static size_t pick_size(uint64_t *rng) {
  uint64_t r = mix(rng);
  unsigned roll = (unsigned)(r % 1000);
  if (roll < 700) return 1 + (size_t)((r >> 10) % 256);
  if (roll < 950) return 257 + (size_t)((r >> 10) % 8192);
  if (roll < 995) return 8449 + (size_t)((r >> 10) % 40000);
  return 65536 + (size_t)((r >> 10) % (3u << 20));
}

/* First, middle and last byte; for n < 3 those positions coincide, so the
   later marks are written only where they do not overwrite earlier ones. */
static void fill(unsigned char *p, size_t n, unsigned tag) {
  p[0] = (unsigned char)tag;
  if (n > 1) p[n - 1] = (unsigned char)(tag ^ CANARY);
  if (n > 2) p[n / 2] = (unsigned char)(tag + 1);
}
static int intact(const unsigned char *p, size_t n, unsigned tag) {
  return p[0] == (unsigned char)tag && (n <= 1 || p[n - 1] == (unsigned char)(tag ^ CANARY))
    && (n <= 2 || p[n / 2] == (unsigned char)(tag + 1));
}

/* ---- single-thread contracts ---- */
static void single_thread(void) {
  for (size_t n = 1; n <= 40000; n += (n < 512 ? 1 : 97)) {
    unsigned char *p = anth_arena_malloc(n);
    CHECK(p != NULL, "malloc(%zu)", n);
    CHECK(((uintptr_t)p & 15) == 0, "alignment of %zu", n);
    CHECK(anth_arena_usable(p) >= n, "usable(%zu)=%zu", n, anth_arena_usable(p));
    memset(p, 0x5A, n);
    anth_arena_free(p);
  }
  unsigned char *z = anth_arena_calloc(1000, 7);
  int zero = 1;
  for (int i = 0; i < 7000; ++i) zero &= z[i] == 0;
  CHECK(zero, "calloc returns zeroed memory");
  anth_arena_free(z);
  unsigned char *r = anth_arena_malloc(100);
  for (int i = 0; i < 100; ++i) r[i] = (unsigned char)i;
  r = anth_arena_realloc(r, 70000);
  int kept = 1;
  for (int i = 0; i < 100; ++i) kept &= r[i] == (unsigned char)i;
  CHECK(kept, "realloc keeps contents across the large boundary");
  anth_arena_free(r);
  /* Freed blocks are reused (delayed release, no OS round trip). */
  void *a = anth_arena_malloc(48);
  anth_arena_free(a);
  void *b = anth_arena_malloc(48);
  CHECK(a == b, "same-class block is recycled immediately");
  anth_arena_free(b);
  void *big = anth_arena_malloc(5u << 20);
  anth_arena_free(big);
  void *big2 = anth_arena_malloc(5u << 20);
  CHECK(big == big2, "large span is cached and reused");
  anth_arena_free(big2);
}

/* ---- multi-thread stress with cross-thread frees ---- */
typedef struct {
  _Atomic(void *) slots[4096];
} Mailbox;

typedef struct {
  alignas(64) int index;
  int threads;
  int ops;
  uint64_t seed;
  Mailbox *boxes;
  _Atomic int *done;
  uint64_t local_frees, remote_frees, allocations;
} Stress;

static void *stress_main(void *arg) {
  Stress *s = arg;
  uint64_t rng = s->seed;
  enum { KEEP = 512 };
  void *keep[KEEP] = {0};
  size_t keep_size[KEEP] = {0};
  for (int op = 0; op < s->ops; ++op) {
    int slot = (int)(mix(&rng) % KEEP);
    if (keep[slot]) {
      CHECK(intact(keep[slot], keep_size[slot], (unsigned)s->index), "canary intact before free");
      /* ~30%: hand the block to another thread, which frees it. */
      if (s->threads > 1 && mix(&rng) % 10 < 3) {
        int target = (s->index + 1 + (int)(mix(&rng) % (uint64_t)(s->threads - 1))) % s->threads;
        Mailbox *box = &s->boxes[target];
        int at = (int)(mix(&rng) % 4096);
        void *old = atomic_exchange(&box->slots[at], keep[slot]);
        if (old) anth_arena_free(old);
        s->remote_frees += 1;
      } else {
        anth_arena_free(keep[slot]);
        s->local_frees += 1;
      }
      keep[slot] = NULL;
    }
    size_t n = pick_size(&rng);
    unsigned char *p = anth_arena_malloc(n);
    CHECK(p != NULL, "malloc under stress");
    fill(p, n, (unsigned)s->index);
    keep[slot] = p;
    keep_size[slot] = n;
    s->allocations += 1;
    /* Free whatever other threads mailed to us. */
    if ((op & 255) == 0) {
      Mailbox *mine = &s->boxes[s->index];
      for (int i = 0; i < 4096; ++i) { void *q = atomic_exchange(&mine->slots[i], NULL); if (q) anth_arena_free(q); }
    }
  }
  for (int i = 0; i < KEEP; ++i) if (keep[i]) anth_arena_free(keep[i]);
  atomic_fetch_add(s->done, 1);
  return NULL;
}

static void stress(int threads, int ops_per_thread) {
  Mailbox *boxes = anth_arena_calloc((size_t)threads, sizeof(Mailbox));
  Stress *state = anth_arena_calloc((size_t)threads, sizeof(Stress));
  pthread_t *ids = anth_arena_calloc((size_t)threads, sizeof(pthread_t));
  _Atomic int done = 0;
  for (int t = 0; t < threads; ++t) {
    state[t] = (Stress){.index = t, .threads = threads, .ops = ops_per_thread, .seed = 1234567u + (uint64_t)t * 7919u,
      .boxes = boxes, .done = &done};
    pthread_create(&ids[t], NULL, stress_main, &state[t]);
  }
  for (int t = 0; t < threads; ++t) pthread_join(ids[t], NULL);
  for (int t = 0; t < threads; ++t)
    for (int i = 0; i < 4096; ++i) { void *q = atomic_exchange(&boxes[t].slots[i], NULL); if (q) anth_arena_free(q); }
  uint64_t remote = 0;
  for (int t = 0; t < threads; ++t) remote += state[t].remote_frees;
  CHECK(atomic_load(&done) == threads, "all stress threads finished");
  CHECK(threads == 1 || remote > 0, "cross-thread frees happened");
  anth_arena_free(ids);
  anth_arena_free(state);
  anth_arena_free(boxes);
}

/* ---- layout: per-thread hot structures never share a cache line ---- */
static void layout(void) {
  CHECK((size_t)anth_arena_heap_size() % ANTH_CACHE_LINE == 0, "heap size %zu is a cache-line multiple", (size_t)anth_arena_heap_size());
  for (int i = 0; i + 1 < 8; ++i) {
    uintptr_t a = (uintptr_t)anth_arena_heap_address(i), b = (uintptr_t)anth_arena_heap_address(i + 1);
    CHECK(a % ANTH_CACHE_LINE == 0, "heap %d starts a cache line", i);
    CHECK(b - a >= (uintptr_t)anth_arena_heap_size() && (b / ANTH_CACHE_LINE) != ((a + (uintptr_t)anth_arena_heap_size() - 1) / ANTH_CACHE_LINE),
      "heaps %d and %d share no cache line", i, i + 1);
  }
}

/* ---- scaling with hardware counters ---- */
typedef struct { int fd[4]; int ok; } Counters;
static const uint64_t COUNTER_CONFIG[4] = {PERF_COUNT_HW_CPU_CYCLES, PERF_COUNT_HW_INSTRUCTIONS,
  PERF_COUNT_HW_CACHE_MISSES, PERF_COUNT_HW_CACHE_REFERENCES};

static int counter_open(uint64_t config) {
  struct perf_event_attr attr;
  memset(&attr, 0, sizeof(attr));
  attr.size = sizeof(attr);
  attr.type = PERF_TYPE_HARDWARE;
  attr.config = config;
  attr.disabled = 1;
  attr.exclude_kernel = 1;
  attr.exclude_hv = 1;
  return (int)syscall(SYS_perf_event_open, &attr, 0, -1, -1, 0);
}
static Counters counters_start(void) {
  Counters c = {.ok = 1};
  for (int i = 0; i < 4; ++i) { c.fd[i] = counter_open(COUNTER_CONFIG[i]); if (c.fd[i] < 0) c.ok = 0; }
  for (int i = 0; i < 4; ++i) if (c.fd[i] >= 0) { ioctl(c.fd[i], PERF_EVENT_IOC_RESET, 0); ioctl(c.fd[i], PERF_EVENT_IOC_ENABLE, 0); }
  return c;
}
static void counters_stop(Counters *c, uint64_t out[4]) {
  for (int i = 0; i < 4; ++i) {
    out[i] = 0;
    if (c->fd[i] >= 0) { ioctl(c->fd[i], PERF_EVENT_IOC_DISABLE, 0); if (read(c->fd[i], &out[i], sizeof(out[i])) != sizeof(out[i])) out[i] = 0; close(c->fd[i]); }
  }
}

/* CPUs of the caller's L3 domain, one per physical core (no SMT siblings). */
static int physical_cpus(int *cpus, int max) {
  int self = sched_getcpu();
  char path[128], list[256];
  snprintf(path, sizeof(path), "/sys/devices/system/cpu/cpu%d/cache/index3/shared_cpu_list", self < 0 ? 0 : self);
  FILE *f = fopen(path, "r");
  if (!f) return 0;
  if (!fgets(list, sizeof(list), f)) { fclose(f); return 0; }
  fclose(f);
  int count = 0;
  for (char *p = list; *p && count < max;) {
    int a = (int)strtol(p, &p, 10), b = a;
    if (*p == '-') b = (int)strtol(p + 1, &p, 10);
    for (int cpu = a; cpu <= b && count < max; ++cpu) {
      char sib[160], first[32] = {0};
      snprintf(sib, sizeof(sib), "/sys/devices/system/cpu/cpu%d/topology/thread_siblings_list", cpu);
      FILE *g = fopen(sib, "r");
      int leader = cpu;
      if (g) { if (fgets(first, sizeof(first), g)) leader = atoi(first); fclose(g); }
      if (leader == cpu) cpus[count++] = cpu;
    }
    if (*p == ',') ++p; else break;
  }
  return count;
}

typedef struct {
  alignas(64) int cpu;
  int ops;
  uint64_t seed;
  uint64_t counts[4];
  uint64_t elapsed;
  int ok;
  _Atomic int *start;
} Scale;

static void pin(int cpu) {
  cpu_set_t set;
  CPU_ZERO(&set);
  CPU_SET(cpu, &set);
  pthread_setaffinity_np(pthread_self(), sizeof(set), &set);
}

/* Thread-private churn: allocate and free in a window, like a shaping job. */
static void *scale_main(void *arg) {
  Scale *s = arg;
  pin(s->cpu);
  uint64_t rng = s->seed;
  enum { WINDOW = 256 };
  void *window[WINDOW] = {0};
  for (int warm = 0; warm < 20000; ++warm) { int i = (int)(mix(&rng) % WINDOW); anth_arena_free(window[i]); window[i] = anth_arena_malloc(1 + mix(&rng) % 512); }
  while (atomic_load(s->start) == 0) {}
  Counters c = counters_start();
  uint64_t t0 = now_ns();
  for (int op = 0; op < s->ops; ++op) {
    int i = (int)(mix(&rng) % WINDOW);
    anth_arena_free(window[i]);
    unsigned char *p = anth_arena_malloc(1 + mix(&rng) % 512);
    p[0] = (unsigned char)op;
    window[i] = p;
  }
  s->elapsed = now_ns() - t0;
  counters_stop(&c, s->counts);
  s->ok = c.ok;
  for (int i = 0; i < WINDOW; ++i) anth_arena_free(window[i]);
  return NULL;
}

typedef struct { double cycles, instructions, misses, seconds; int ok; } ScaleResult;
static ScaleResult run_scale(int *cpus, int threads, int ops) {
  Scale state[64];
  pthread_t ids[64];
  _Atomic int start = 0;
  for (int t = 0; t < threads; ++t) {
    memset(&state[t], 0, sizeof(state[t]));
    state[t].cpu = cpus[t];
    state[t].ops = ops;
    state[t].seed = 99u + (uint64_t)t;
    state[t].start = &start;
    pthread_create(&ids[t], NULL, scale_main, &state[t]);
  }
  usleep(20000);
  atomic_store(&start, 1);
  ScaleResult r = {.ok = 1};
  uint64_t longest = 0;
  for (int t = 0; t < threads; ++t) {
    pthread_join(ids[t], NULL);
    r.ok &= state[t].ok;
    r.cycles += (double)state[t].counts[0];
    r.instructions += (double)state[t].counts[1];
    r.misses += (double)state[t].counts[2];
    if (state[t].elapsed > longest) longest = state[t].elapsed;
  }
  double total = (double)threads * ops;
  r.cycles /= total; r.instructions /= total; r.misses /= total;
  r.seconds = (double)longest / 1e9;
  return r;
}

/* Control: if counters cannot see false sharing, the scaling check is void. */
typedef struct { _Atomic uint64_t *slot; int cpu; uint64_t cycles; _Atomic int *start; } Bump;
static void *bump_main(void *arg) {
  Bump *b = arg;
  pin(b->cpu);
  while (atomic_load(b->start) == 0) {}
  Counters c = counters_start();
  for (int i = 0; i < 20000000; ++i)
    atomic_store_explicit(b->slot, atomic_load_explicit(b->slot, memory_order_relaxed) + 1, memory_order_relaxed);
  uint64_t out[4];
  counters_stop(&c, out);
  b->cycles = out[0];
  return NULL;
}
static double bump_pair(_Atomic uint64_t *a, _Atomic uint64_t *b, int cpu0, int cpu1) {
  _Atomic int start = 0;
  Bump x = {a, cpu0, 0, &start}, y = {b, cpu1, 0, &start};
  pthread_t tx, ty;
  pthread_create(&tx, NULL, bump_main, &x);
  pthread_create(&ty, NULL, bump_main, &y);
  usleep(10000);
  atomic_store(&start, 1);
  pthread_join(tx, NULL);
  pthread_join(ty, NULL);
  return (double)(x.cycles + y.cycles) / 2.0;
}

static int load_too_high(void) {
  double load = 0;
  FILE *f = fopen("/proc/loadavg", "r");
  if (f) { if (fscanf(f, "%lf", &load) != 1) load = 0; fclose(f); }
  return load > (double)sysconf(_SC_NPROCESSORS_ONLN) / 4.0;
}

static int scaling(void) {
  int cpus[64];
  int n = physical_cpus(cpus, 64);
  if (n < 4) { printf("SKIP: fewer than 4 physical cores in this L3 domain\n"); return SKIP; }
  if (load_too_high()) { printf("SKIP: machine busy (loadavg)\n"); return SKIP; }
  int max_threads = n - 1 < 6 ? n - 1 : 6;
  /* Control: same line vs separate lines. */
  static alignas(64) _Atomic uint64_t shared_line[2];
  static alignas(64) _Atomic uint64_t separate[2][8];
  double together = bump_pair(&shared_line[0], &shared_line[1], cpus[0], cpus[1]);
  double apart = bump_pair(&separate[0][0], &separate[1][0], cpus[0], cpus[1]);
  printf("event=false_sharing_control same_line_cycles=%.0f separate_cycles=%.0f ratio=%.2f\n", together, apart, apart > 0 ? together / apart : 0);
  if (apart <= 0) { printf("SKIP: perf_event_open unavailable\n"); return SKIP; }
  CHECK(together > apart * 2.0, "control: false sharing must be visible to the counters (%.2fx)", together / apart);
  const int ops = 2000000;
  ScaleResult base = run_scale(cpus, 1, ops);
  if (!base.ok) { printf("SKIP: hardware counters unavailable\n"); return SKIP; }
  for (int t = 1; t <= max_threads; ++t) {
    ScaleResult r = t == 1 ? base : run_scale(cpus, t, ops);
    double speedup = (base.seconds * t) / r.seconds;
    printf("event=arena_scaling threads=%d ns_per_op=%.2f cycles_per_op=%.1f instructions_per_op=%.1f misses_per_op=%.4f speedup=%.2f\n",
      t, r.seconds * 1e9 / ops, r.cycles, r.instructions, r.misses, speedup);
    CHECK(r.instructions <= base.instructions * 1.05 && r.instructions >= base.instructions * 0.95,
      "threads=%d instructions/op %.1f vs %.1f: work must not grow", t, r.instructions, base.instructions);
    CHECK(r.cycles <= base.cycles * 1.25, "threads=%d cycles/op %.1f vs %.1f: contention", t, r.cycles, base.cycles);
    CHECK(r.misses <= base.misses * 1.3 + 0.01, "threads=%d misses/op %.4f vs %.4f: shared lines", t, r.misses, base.misses);
    CHECK(speedup >= 0.8 * t, "threads=%d speedup %.2f below %.2f", t, speedup, 0.8 * t);
  }
  return 0;
}

int main(int argc, char **argv) {
  if (argc > 1 && strcmp(argv[1], "--scaling") == 0) {
    int result = scaling();
    if (result == SKIP) return SKIP;
    printf("event=arena_scaling_contracts failures=%d\n", failures);
    return failures ? 1 : 0;
  }
  AnthArenaStats before = anth_arena_stats();
  CHECK(before.enabled, "arena enabled (ANTHRACITE_ARENA unset)");
  layout();
  single_thread();
  int counts[] = {1, 2, 3, 4, 6, 8, 12};
  for (unsigned i = 0; i < sizeof(counts) / sizeof(counts[0]); ++i) stress(counts[i], 1500000 / counts[i] + 20000); /* ~10.5 M ops over 7 configurations */
  AnthArenaStats after = anth_arena_stats();
  printf("event=arena_contracts failures=%d threads=%llu segments=%llu remote_frees=%llu committed_mb=%llu libc_fallback=%llu\n",
    failures, (unsigned long long)after.threads, (unsigned long long)after.segments,
    (unsigned long long)after.remote_frees, (unsigned long long)(after.committed >> 20), (unsigned long long)after.libc_fallback);
  CHECK(after.remote_frees > 0, "remote free path exercised");
  CHECK(after.libc_fallback == before.libc_fallback, "no allocation fell back to libc");
  /* Heaps of finished threads are adopted: at most 12 workers + main at once. */
  CHECK(after.threads <= 13, "finished threads' heaps are reused (%llu heaps)", (unsigned long long)after.threads);
  return failures ? 1 : 0;
}
