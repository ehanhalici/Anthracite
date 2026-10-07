#ifndef ANTH_MEM_CATS
#define ANTH_MEM_CATS

#include <string.h>

static int anth_allocs = 0;
static int anth_frees = 0;
static int anth_live = 0;

static inline void anth_mem_alloc(int n) {
  anth_allocs += 1;
  anth_live += n;
}

static inline void anth_mem_free(int n) {
  anth_frees += 1;
  anth_live -= n;
}

static inline int anth_mem_allocs(void) { return anth_allocs; }
static inline int anth_mem_frees(void) { return anth_frees; }
static inline int anth_mem_live(void) { return anth_live; }

static inline int anth_mem_byte(const void *p, int n, int i) {
  if (!p || i < 0 || i >= n) return 0;
  return ((const unsigned char *)p)[i];
}

static inline void anth_mem_set_byte(void *p, int n, int i, int v) {
  if (!p || i < 0 || i >= n) return;
  ((unsigned char *)p)[i] = (unsigned char)v;
}

static inline int anth_mem_i32(const void *p, int n, int i) {
  int nb = i * 4;
  int v = 0;
  if (!p || i < 0 || nb < 0 || nb + 4 > n) return 0;
  memcpy(&v, (const unsigned char *)p + nb, 4);
  return v;
}

static inline void anth_mem_set_i32(void *p, int n, int i, int v) {
  int nb = i * 4;
  if (!p || i < 0 || nb < 0 || nb + 4 > n) return;
  memcpy((unsigned char *)p + nb, &v, 4);
}

static inline void anth_mem_set_f32(void *p, int n, int i, float v) {
  int nb = i * 4;
  if (!p || i < 0 || nb < 0 || nb + 4 > n) return;
  memcpy((unsigned char *)p + nb, &v, 4);
}

static inline void *anth_ptr_at(void *p, int n, int i) {
  if (!p || i < 0 || i >= n) return 0;
  return (unsigned char *)p + i;
}

static inline char *anth_ptr_string(void *p) {
  return p ? (char *)p : (char *)"";
}

static inline unsigned anth_u_zero(void) { return 0; }

static inline unsigned anth_u_of(int n) {
  if (n < 0) return 0;
  return (unsigned)n;
}

static inline int anth_iand(int a, int n) {
  return (int)((unsigned)a & (unsigned)n);
}

static inline int anth_bit(int a, int m) {
  return (((unsigned)a & (unsigned)m) != 0) ? 1 : 0;
}

static inline int anth_u32(int hi, int lo) {
  unsigned v = ((unsigned)(hi & 65535) << 16) | (unsigned)(lo & 65535);
  if (v > 0x7fffffffu) return 0;
  return (int)v;
}

static inline int anth_ms(long a, long b) {
  long d = b - a;
  if (d < 0) d = 0;
  d /= 1000000L;
  if (d > 2147483647L) return 2147483647;
  return (int)d;
}

static inline long anth_i2lint(int n) { return (long)n; }

static inline size_t anth_i2sz(int n) {
  if (n < 0) return 0;
  return (size_t)n;
}

static inline float anth_d2f(double d) { return (float)d; }

static inline int anth_u2i(unsigned v) {
  if (v > 0x7fffffffu) return 0;
  return (int)v;
}

#endif
