#ifndef ANTH_FS_CATS
#define ANTH_FS_CATS

#define _DEFAULT_SOURCE 1
#define _POSIX_C_SOURCE 200809L

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <errno.h>
#include <math.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/stat.h>
#include <dirent.h>

static inline int anth_open_read(const char *p) { return open(p, O_RDONLY); }
static inline int anth_read(int fd, void *b, int n) {
  if (fd < 0 || !b || n <= 0) return -1;
  return (int)read(fd, b, (size_t)n);
}
static inline int anth_write(int fd, const void *b, int n) {
  if (fd < 0 || !b || n <= 0) return -1;
  return (int)write(fd, b, (size_t)n);
}
static inline void anth_close(int fd) { if (fd >= 0) close(fd); }
static inline int anth_fsync(int fd) { return (fd >= 0) ? fsync(fd) : -1; }
static inline int anth_atomic_write(const char *path, const void *buf, int len) {
  if (!path || len < 0) return 0;
  char tmppath[1024];
  int n = snprintf(tmppath, sizeof(tmppath), "%s.tmp", path);
  if (n <= 0 || (size_t)n >= sizeof(tmppath)) return 0;
  int fd = open(tmppath, O_WRONLY | O_CREAT | O_TRUNC, 0644);
  if (fd < 0) return 0;
  if (len > 0) {
    int w = anth_write(fd, buf, len);
    if (w != len) {
      close(fd);
      unlink(tmppath);
      return 0;
    }
  }
  anth_fsync(fd);
  close(fd);
  if (rename(tmppath, path) != 0) {
    unlink(tmppath);
    return 0;
  }
  return 1;
}

static inline int anth_size(const char *p) {
  struct stat st;
  if (stat(p, &st) != 0) return -1;
  if (st.st_size > 0x7fffffff) return -1;
  return (int)st.st_size;
}
static inline int anth_isdir(const char *p) {
  struct stat st;
  if (stat(p, &st) != 0) return 0;
  return S_ISDIR(st.st_mode) ? 1 : 0;
}
static inline int anth_exists(const char *p) {
  return access(p, F_OK) == 0 ? 1 : 0;
}
static inline int anth_mkdir(const char *p) { return mkdir(p, 0755); }

static inline void anth_dirclose(void *d) { if (d) closedir((DIR *)d); }
static inline int anth_dirnext(void *d, char *name, int namemax, int *isdir) {
  if (!d) return 0;
  struct dirent *e = readdir((DIR *)d);
  if (!e) return 0;
  int i = 0;
  for (; e->d_name[i] && i + 1 < namemax; i++) name[i] = e->d_name[i];
  name[i] = 0;
  *isdir = (e->d_type == DT_DIR) ? 1 : (e->d_type == DT_UNKNOWN ? -1 : 0);
  return 1;
}

static inline long anth_now_ns(void) {
  struct timespec ts;
  clock_gettime(CLOCK_MONOTONIC, &ts);
  return (long)ts.tv_sec * 1000000000L + (long)ts.tv_nsec;
}

static inline int anth_rss_kb(void) {
  FILE *f = fopen("/proc/self/status", "r");
  if (!f) return 0;
  char line[256];
  int kb = 0;
  while (fgets(line, sizeof line, f)) {
    if (strncmp(line, "VmRSS:", 6) == 0) {
      sscanf(line + 6, "%d", &kb);
      break;
    }
  }
  fclose(f);
  return kb;
}

static inline int anth_str_byte(const char *s, int i) {
  int k;
  if (!s || i < 0) return 0;
  for (k = 0; k < i; k++) if (!s[k]) return 0;
  if (!s[i]) return 0;
  return (unsigned char)s[i];
}
static inline void *anth_str_ptr(const char *s) { return (void *)(s ? s : ""); }
static inline void *anth_getenv(const char *k) {
  const char *v = getenv(k);
  return (void *)(v ? v : "");
}

static char anth_cmd[8192];
static int anth_cmd_ready;
static int anth_cmd_argc;
static int anth_cmd_off[64];

static inline void anth_cmd_load(void) {
  if (anth_cmd_ready) return;
  anth_cmd_ready = 1;
  anth_cmd_argc = 0;
  int fd = open("/proc/self/cmdline", O_RDONLY);
  if (fd < 0) return;
  int n = (int)read(fd, anth_cmd, sizeof anth_cmd - 1);
  close(fd);
  if (n < 0) n = 0;
  anth_cmd[n] = 0;
  int i, a = 0;
  anth_cmd_off[0] = 0;
  for (i = 0; i < n && a < 63; i++) {
    if (anth_cmd[i] == 0) {
      a++;
      anth_cmd_off[a] = i + 1;
    }
  }
  anth_cmd_argc = a;
}
static inline int anth_argc(void) { anth_cmd_load(); return anth_cmd_argc; }
static inline void *anth_argv(int i) {
  anth_cmd_load();
  if (i < 0 || i >= anth_cmd_argc) return (void *)"";
  return (void *)(anth_cmd + anth_cmd_off[i]);
}
static inline int anth_cwd(char *dst, int n) {
  if (!dst || n < 2) return 0;
  return getcwd(dst, (size_t)n) ? 1 : 0;
}

static inline int anth_fc_font(char *dst, int n) {
  if (!dst || n < 2) return 0;
  const char *cmds[] = {
    "fc-list \"DejaVu Sans Mono:style=Book\" file 2>/dev/null",
    "fc-list \"Ubuntu Mono:style=Regular\" file 2>/dev/null",
    "fc-list :mono file 2>/dev/null",
    0
  };
  int k;
  for (k = 0; cmds[k]; k++) {
    FILE *f = popen(cmds[k], "r");
    if (!f) continue;
    if (!fgets(dst, n, f)) { pclose(f); continue; }
    pclose(f);
    char *c = strchr(dst, ':');
    if (c) *c = 0;
    c = strchr(dst, '\n');
    if (c) *c = 0;
    if (dst[0]) return 1;
  }
  dst[0] = 0;
  return 0;
}

static inline double anth_i2d(int i) { return (double)i; }
static inline int anth_d2i(double d) {
  if (d >= 2147483647.0) return 2147483647;
  if (d <= -2147483648.0) return (int)(-2147483647 - 1);
  return (int)d;
}

static inline unsigned int anth_hash_str(const char *s) {
  unsigned int h = 2166136261u;
  if (!s) return h;
  while (*s) {
    h ^= (unsigned char)(*s++);
    h *= 16777619u;
  }
  return h;
}

static inline void anth_vfs_path(const char *p, char *dst, int dstmax) {
  if (!dst || dstmax < 32) return;
  dst[0] = 0;
  if (!p || !p[0]) return;

  const char *vdir = "/dev/shm/anthracite";
  struct stat st;
  if (stat(vdir, &st) != 0) {
    mkdir(vdir, 0755);
  }

  unsigned int h = anth_hash_str(p);
  const char *base = strrchr(p, '/');
  base = base ? base + 1 : p;

  snprintf(dst, (size_t)dstmax, "%s/%08x_%s", vdir, h, base);
}

#endif
