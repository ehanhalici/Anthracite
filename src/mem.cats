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

static inline int anth_mem_live(void) { return anth_live; }

static inline int anth_mem_byte(const void *p, int n, int i) {
  if (!p || i < 0 || i >= n) return 0;
  return ((const unsigned char *)p)[i];
}

static inline void anth_mem_set_byte(void *p, int n, int i, int v) {
  if (!p || i < 0 || i >= n) return;
  ((unsigned char *)p)[i] = (unsigned char)v;
}

enum { ANTH_WORD_BYTES = 4 };

static inline int anth_word_index_valid(int capacity_bytes, int index) {
  return index >= 0 && capacity_bytes >= ANTH_WORD_BYTES &&
    index <= (capacity_bytes - ANTH_WORD_BYTES) / ANTH_WORD_BYTES;
}

static inline int anth_mem_i32(const void *p, int n, int i) {
  int v = 0;
  if (!p || !anth_word_index_valid(n, i)) return 0;
  int nb = i * ANTH_WORD_BYTES;
  memcpy(&v, (const unsigned char *)p + nb, ANTH_WORD_BYTES);
  return v;
}

static inline void anth_mem_set_i32(void *p, int n, int i, int v) {
  if (!p || !anth_word_index_valid(n, i)) return;
  int nb = i * ANTH_WORD_BYTES;
  memcpy((unsigned char *)p + nb, &v, ANTH_WORD_BYTES);
}

static inline void anth_mem_set_f32(void *p, int n, int i, float v) {
  if (!p || !anth_word_index_valid(n, i)) return;
  int nb = i * ANTH_WORD_BYTES;
  memcpy((unsigned char *)p + nb, &v, ANTH_WORD_BYTES);
}

static inline void *anth_ptr_at(void *p, int n, int i) {
  if (!p || i < 0 || i >= n) return 0;
  return (unsigned char *)p + i;
}

static inline char *anth_ptr_string(void *p) {
  return p ? (char *)p : (char *)"";
}

static inline void anth_buf_copy(void *dst, int dst_cap, int dst_off, const void *src, int src_cap, int src_off, int n) {
  if (!dst || !src || n <= 0) return;
  if (dst_off < 0 || dst_off + n > dst_cap) return;
  if (src_off < 0 || src_off + n > src_cap) return;
  memmove((unsigned char *)dst + dst_off, (const unsigned char *)src + src_off, (size_t)n);
}

static inline void anth_copy_to_ptr(const void *src, int src_cap, int src_off, void *dst, int dst_cap, int dst_off, int n) {
  if (!src || !dst || n <= 0) return;
  if (src_off < 0 || src_off + n > src_cap) return;
  if (dst_off < 0 || dst_off + n > dst_cap) return;
  memcpy((unsigned char *)dst + dst_off, (const unsigned char *)src + src_off, (size_t)n);
}

#endif
