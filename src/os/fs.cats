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
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/stat.h>
#include <sys/file.h>
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
/* Size and mtime from one stat call (-1 size when missing or too large). */
static inline int anth_size_mtime(const char *p, int *mtime) {
  struct stat st;
  if (stat(p, &st) != 0) { *mtime = -1; return -1; }
  *mtime = (int)st.st_mtime;
  return st.st_size > 0x7fffffff ? -1 : (int)st.st_size;
}
static inline int anth_mtime(const char *p) {
  struct stat st;
  if (stat(p, &st) != 0) return -1;
  return (int)st.st_mtime;
}
/* OS metadata only: the ATS caller owns comparison and cache policy. */
static inline int anth_stat_stamp(const char *path, long *seconds, int *nanoseconds,
                                 long *length, unsigned long long *device,
                                 unsigned long long *inode) {
  struct stat value;
  if (stat(path, &value) != 0) return 0;
  *seconds = (long)value.st_mtim.tv_sec;
  *nanoseconds = (int)value.st_mtim.tv_nsec;
  *length = (long)value.st_size;
  *device = (unsigned long long)value.st_dev;
  *inode = (unsigned long long)value.st_ino;
  return 1;
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

/* Removes a directory tree created by anth_make_temp_dir; never follows symlinks. */
static inline void anth_remove_tree(const char *path) {
  DIR *d = opendir(path);
  if (d) {
    struct dirent *e;
    while ((e = readdir(d)) != NULL) {
      if (strcmp(e->d_name, ".") == 0 || strcmp(e->d_name, "..") == 0) continue;
      char child[4096];
      if (snprintf(child, sizeof child, "%s/%s", path, e->d_name) >= (int)sizeof child) continue;
      struct stat st;
      if (lstat(child, &st) == 0 && S_ISDIR(st.st_mode)) anth_remove_tree(child);
      else unlink(child);
    }
    closedir(d);
  }
  rmdir(path);
}

static inline int anth_copy_file(const char *src, const char *dst) {
  if (!src || !dst) return -1;
  struct stat st;
  if (lstat(src, &st) != 0 || !S_ISREG(st.st_mode)) return -1;
  int rfd = open(src, O_RDONLY);
  if (rfd < 0) return -1;
  int wfd = open(dst, O_WRONLY | O_CREAT | O_EXCL, (mode_t)(st.st_mode & 0777) | 0600);
  if (wfd < 0) { close(rfd); return -1; }
  char buf[4096];
  int ok = 0;
  for (;;) {
    ssize_t nr = read(rfd, buf, sizeof(buf));
    if (nr == 0) break;
    if (nr < 0) {
      if (errno == EINTR) continue;
      ok = -1;
      break;
    }
    ssize_t off = 0;
    while (off < nr) {
      ssize_t nw = write(wfd, buf + off, (size_t)(nr - off));
      if (nw < 0) {
        if (errno == EINTR) continue;
        ok = -1;
        break;
      }
      off += nw;
    }
    if (ok < 0) break;
  }
  close(rfd);
  if (ok == 0 && fsync(wfd) != 0) ok = -1;
  if (close(wfd) != 0) ok = -1;
  if (ok != 0) unlink(dst);
  return ok;
}

static char anth_selftest_temp_dir[64];
static inline void anth_selftest_temp_cleanup(void) {
  const char *keep = getenv("ANTHRACITE_KEEP_SELFTEST_DIR");
  if (anth_selftest_temp_dir[0] && !(keep && keep[0]))
    anth_remove_tree(anth_selftest_temp_dir);
}

/* mkdtemp creates an exclusive mode-0700 directory; no existing target is used.
   The directory is removed at process exit unless ANTHRACITE_KEEP_SELFTEST_DIR is set. */
static inline int anth_make_temp_dir(char *dst, int capacity_bytes) {
  static const char fixture_template[] = "/tmp/anthracite-selftest-XXXXXX";
  if (!dst || capacity_bytes < (int)sizeof(fixture_template)) return 0;
  memcpy(dst, fixture_template, sizeof(fixture_template));
  if (mkdtemp(dst)) {
    setenv("ANTHRACITE_CONFIG_DIR", dst, 0);
    if (!anth_selftest_temp_dir[0]) {
      memcpy(anth_selftest_temp_dir, dst, sizeof(fixture_template));
      atexit(anth_selftest_temp_cleanup);
    }
    return 1;
  }
  dst[0] = '\0';
  return 0;
}

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

/* Font discovery is an OS boundary; parsing and owning the face are ATS2. */
static inline int anth_fc_arabic_font(char *dst, int n) {
  if (!dst || n < 2) return 0;
  dst[0] = 0;
  FILE *stream = popen("fc-match ':lang=ar' -f '%{file}' 2>/dev/null", "r");
  if (!stream) return 0;
  char *line = fgets(dst, n, stream);
  int status = pclose(stream);
  if (!line || status != 0) { dst[0] = 0; return 0; }
  return dst[0] && access(dst, F_OK) == 0;
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

static inline void anth_open_url(const char *url) {
  if (!url || !url[0]) return;
  pid_t pid = fork();
  if (pid == 0) {
    if (fork() == 0) {
      int devnull = open("/dev/null", O_RDWR);
      if (devnull >= 0) {
        dup2(devnull, STDIN_FILENO);
        dup2(devnull, STDOUT_FILENO);
        dup2(devnull, STDERR_FILENO);
        close(devnull);
      }
      execlp("xdg-open", "xdg-open", url, (char *)NULL);
      _exit(127);
    }
    _exit(0);
  }
  if (pid > 0) {
    waitpid(pid, NULL, 0);
  }
}

/* Exclusive non-blocking advisory lock so only one Anthracite instance runs per config dir. */
static inline int anth_instance_lock(const char *path, int *owner_pid) {
  if (owner_pid) *owner_pid = 0;
  if (!path || !path[0]) return -2;
  int fd = open(path, O_CREAT | O_RDWR | O_CLOEXEC, 0644);
  if (fd < 0) return -2;
  if (flock(fd, LOCK_EX | LOCK_NB) != 0) {
    int err = errno;
    if (err == EWOULDBLOCK || err == EAGAIN) {
      if (owner_pid) {
        char buf[32];
        ssize_t n = pread(fd, buf, sizeof(buf) - 1, 0);
        if (n > 0) {
          buf[n] = '\0';
          *owner_pid = atoi(buf);
        }
      }
      close(fd);
      return -1;
    }
    close(fd);
    return -2;
  }
  if (ftruncate(fd, 0) == 0) {
    char pidbuf[32];
    int n = snprintf(pidbuf, sizeof(pidbuf), "%ld\n", (long)getpid());
    if (n > 0) {
      ssize_t w = pwrite(fd, pidbuf, (size_t)n, 0);
      (void)w;
    }
  }
  return fd;
}

static inline void anth_instance_unlock(int fd) {
  if (fd >= 0) {
    flock(fd, LOCK_UN);
    close(fd);
  }
}

#endif
