#define _GNU_SOURCE
#include "core_runtime/performance.cats"
#include <signal.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/syscall.h>
#include <sys/time.h>
#include <time.h>
#include <ucontext.h>
#include <unistd.h>

#define ANTH_MAX_SAMPLES 32768
#define ANTH_MAX_STACK 64

typedef struct anth_sample {
  uintptr_t pcs[ANTH_MAX_STACK];
  int depth;
  int tag;
} anth_sample;

static anth_sample g_samples[ANTH_MAX_SAMPLES];
static volatile sig_atomic_t g_sample_count = 0;
static volatile sig_atomic_t g_sample_dropped = 0;
static uintptr_t g_stack_high = 0;
static int g_sampler_active = 0;
static timer_t g_sampler_timer;
static int g_sampler_timer_ok = 0;
static int g_runtime_inited = 0;
static int g_dumped = 0;
static char g_profile_path[512];
static char g_log_path[512];

static const char *g_counter_names[PERF_COUNTER_COUNT] = {
  "document_loads",
  "ast_parses",
  "fold_prepares",
  "layout_builds",
  "wrap_builds",
  "width_queries",
  "shape_calls",
  "shaped_bytes",
  "read_bytes",
  "paint_rows",
  "embed_hits",
  "embed_misses",
  "visual_index_builds",
  "fold_node_visits",
  "media_index_builds",
  "gl_flush_calls",
  "gl_mode_switches",
  "gl_quads",
  "font_atlas_uploads",
  "alloc_calls",
  "alloc_bytes",
  "wrap_lines",
  "layout_updates"
};

static const char *g_phase_names[PERF_PHASE_COUNT] = {
  "frame_total",
  "event_dispatch",
  "app_draw",
  "draw_panes",
  "visual_prepare",
  "doc_layout",
  "visual_paint",
  "rend_flush",
  "plat_swap",
  "draw_sidebar",
  "draw_overlays",
  "ast_reparse",
  "font_glyph"
};

#if defined(__x86_64__)
static void anth_sigprof_handler(int sig, siginfo_t *info, void *uctx) {
  (void)sig;
  (void)info;
  if (!g_sampler_active) return;
  int idx = g_sample_count;
  if (idx >= ANTH_MAX_SAMPLES) {
    g_sample_dropped += 1;
    return;
  }
  const ucontext_t *uc = (const ucontext_t *)uctx;
  uintptr_t rip = (uintptr_t)uc->uc_mcontext.gregs[REG_RIP];
  uintptr_t rbp = (uintptr_t)uc->uc_mcontext.gregs[REG_RBP];
  uintptr_t rsp = (uintptr_t)uc->uc_mcontext.gregs[REG_RSP];
  int depth = 0;
  g_samples[idx].pcs[depth++] = rip;
  while (depth < ANTH_MAX_STACK &&
         rbp >= rsp &&
         (g_stack_high == 0 || rbp < g_stack_high) &&
         (rbp & 7U) == 0U) {
    const uintptr_t *frame = (const uintptr_t *)rbp;
    uintptr_t next_rbp = frame[0];
    uintptr_t ret_pc = frame[1];
    if (ret_pc < 4096U) break;
    g_samples[idx].pcs[depth++] = ret_pc;
    if (next_rbp <= rbp || (next_rbp - rbp) > (1U << 20)) break;
    rbp = next_rbp;
  }
  g_samples[idx].depth = depth;
  g_samples[idx].tag = anth_perf_sample_tag;
  g_sample_count = idx + 1;
}
#else
static void anth_sigprof_handler(int sig, siginfo_t *info, void *uctx) {
  (void)sig;
  (void)info;
  (void)uctx;
}
#endif

static uintptr_t anth_find_exe_base(void) {
  FILE *fp = fopen("/proc/self/maps", "r");
  if (!fp) return 0;
  char line[512];
  uintptr_t base = 0;
  while (fgets(line, sizeof(line), fp)) {
    unsigned long start = 0, end = 0, off = 0;
    char perms[8] = {0};
    if (sscanf(line, "%lx-%lx %7s %lx", &start, &end, perms, &off) == 4) {
      if (off == 0 && strchr(perms, 'r')) {
        base = (uintptr_t)start;
        break;
      }
    }
  }
  fclose(fp);
  return base;
}

/* Upper bound of the main thread stack, so frame walks reach main(). */
static uintptr_t anth_find_stack_high(void) {
  FILE *fp = fopen("/proc/self/maps", "r");
  uintptr_t high = 0;
  if (fp) {
    char line[512];
    while (fgets(line, sizeof(line), fp)) {
      unsigned long start = 0, end = 0;
      if (strstr(line, "[stack]") && sscanf(line, "%lx-%lx", &start, &end) == 2) {
        high = (uintptr_t)end;
        break;
      }
    }
    fclose(fp);
  }
  if (high == 0) {
    volatile int stack_anchor = 0;
    high = (uintptr_t)&stack_anchor + 65536U;
  }
  return high;
}

static void anth_write_metrics(FILE *out, const char *tag) {
  fprintf(out, "# tag=%s\n", tag ? tag : "summary");
  for (int i = 0; i < PERF_PHASE_COUNT; ++i) {
    unsigned long long total = (unsigned long long)anth_perf_phase_ns[i];
    unsigned long long calls = (unsigned long long)anth_perf_phase_calls[i];
    unsigned long long mx = (unsigned long long)anth_perf_phase_max_ns[i];
    unsigned long long avg = calls > 0 ? total / calls : 0ULL;
    fprintf(out, "event=perf_phase name=%s calls=%llu total_ns=%llu avg_ns=%llu max_ns=%llu\n",
      g_phase_names[i], calls, total, avg, mx);
  }
  for (int i = 0; i < PERF_COUNTER_COUNT; ++i) {
    fprintf(out, "event=performance_counter name=%s value=%llu\n",
      g_counter_names[i], (unsigned long long)anth_performance_counters[i]);
  }
}

static void anth_write_maps(FILE *fp) {
  FILE *mfp = fopen("/proc/self/maps", "r");
  if (!mfp) return;
  char line[512];
  while (fgets(line, sizeof(line), mfp)) {
    unsigned long start = 0, end = 0, off = 0, inode = 0;
    char perms[8] = {0}, dev[16] = {0}, path[256] = {0};
    int n = sscanf(line, "%lx-%lx %7s %lx %15s %lu %255s",
      &start, &end, perms, &off, dev, &inode, path);
    if (n >= 6 && strchr(perms, 'x') && path[0] != '\0') {
      fprintf(fp, "# map=0x%lx-0x%lx %s\n", start, end, path);
    }
  }
  fclose(mfp);
}

static void anth_stop_sampler_and_dump(const char *tag) {
  if (g_sampler_active) {
    g_sampler_active = 0;
    if (g_sampler_timer_ok) {
      timer_delete(g_sampler_timer);
      g_sampler_timer_ok = 0;
    }
  }
  if (g_profile_path[0] != '\0') {
    FILE *fp = fopen(g_profile_path, "w");
    if (fp) {
      uintptr_t base = anth_find_exe_base();
      fprintf(fp, "# exe_base=0x%llx samples=%d dropped=%d\n",
        (unsigned long long)base, (int)g_sample_count, (int)g_sample_dropped);
      anth_write_maps(fp);
      anth_write_metrics(fp, tag);
      int n = (int)g_sample_count;
      for (int i = 0; i < n; ++i) {
        fprintf(fp, "S %d T %d", g_samples[i].depth, g_samples[i].tag);
        for (int j = 0; j < g_samples[i].depth; ++j) {
          fprintf(fp, " 0x%llx", (unsigned long long)g_samples[i].pcs[j]);
        }
        fputc('\n', fp);
      }
      fclose(fp);
    }
  }
  if (g_log_path[0] != '\0') {
    FILE *fp = strcmp(g_log_path, "stderr") == 0 ? stderr : fopen(g_log_path, "w");
    if (fp) {
      anth_write_metrics(fp, tag);
      if (fp != stderr) fclose(fp);
    }
  }
}

static void anth_perf_atexit(void) {
  if (!g_dumped && (g_profile_path[0] != '\0' || g_log_path[0] != '\0')) {
    g_dumped = 1;
    anth_stop_sampler_and_dump("exit");
  }
}

void anth_perf_runtime_init(void) {
  if (g_runtime_inited) return;
  g_runtime_inited = 1;
  g_stack_high = anth_find_stack_high();
  const char *prof = getenv("ANTHRACITE_PERF_PROFILE");
  const char *logp = getenv("ANTHRACITE_PERF_LOG");
  if (prof && prof[0] != '\0') {
    snprintf(g_profile_path, sizeof(g_profile_path), "%s", prof);
    anth_performance_enable(1);
    struct sigaction sa;
    memset(&sa, 0, sizeof(sa));
    sa.sa_sigaction = anth_sigprof_handler;
    sigemptyset(&sa.sa_mask);
    sa.sa_flags = SA_RESTART | SA_SIGINFO;
    if (sigaction(SIGPROF, &sa, NULL) == 0) {
      /* Main-thread CPU clock only: driver worker threads (e.g. NVIDIA threaded
         optimizations) must not contribute samples with unwalkable stacks. */
      struct sigevent sev;
      memset(&sev, 0, sizeof(sev));
      sev.sigev_notify = SIGEV_THREAD_ID;
      sev.sigev_signo = SIGPROF;
#ifdef sigev_notify_thread_id
      sev.sigev_notify_thread_id = (pid_t)syscall(SYS_gettid);
#else
      sev._sigev_un._tid = (pid_t)syscall(SYS_gettid);
#endif
      if (timer_create(CLOCK_THREAD_CPUTIME_ID, &sev, &g_sampler_timer) == 0) {
        struct itimerspec ts;
        ts.it_interval.tv_sec = 0;
        ts.it_interval.tv_nsec = 1000000;
        ts.it_value = ts.it_interval;
        if (timer_settime(g_sampler_timer, 0, &ts, NULL) == 0) {
          g_sampler_timer_ok = 1;
          g_sampler_active = 1;
        } else {
          timer_delete(g_sampler_timer);
        }
      }
    }
  }
  if (logp && logp[0] != '\0') {
    snprintf(g_log_path, sizeof(g_log_path), "%s", logp);
    anth_performance_enable(1);
  }
  if (g_profile_path[0] != '\0' || g_log_path[0] != '\0') {
    atexit(anth_perf_atexit);
  }
}

void anth_perf_runtime_dump(const char *tag) {
  if (g_profile_path[0] != '\0' || g_log_path[0] != '\0') {
    g_dumped = 1;
    anth_stop_sampler_and_dump(tag);
  } else if (anth_performance_enabled) {
    anth_write_metrics(stdout, tag);
  }
}
