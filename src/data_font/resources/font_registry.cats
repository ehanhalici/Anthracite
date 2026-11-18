#ifndef ANTH_FONT_REGISTRY_CATS
#define ANTH_FONT_REGISTRY_CATS

/* Face identities only need to be unique per Font, and a Font never leaves
   its thread, so each thread numbers its own faces. */
static _Thread_local int anth_font_registry_value = 0;

static inline int anth_font_registry_load(void) {
  return anth_font_registry_value;
}

static inline void anth_font_registry_store(int v) {
  anth_font_registry_value = v;
}

/* Source ids are compared across threads, so they come from one atomic counter. */
static _Atomic int anth_font_source_counter;
static inline int anth_font_source_next(void) { return __atomic_add_fetch((int *)&anth_font_source_counter, 1, __ATOMIC_RELAXED); }

#endif
