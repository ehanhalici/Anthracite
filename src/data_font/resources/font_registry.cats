#ifndef ANTH_FONT_REGISTRY_CATS
#define ANTH_FONT_REGISTRY_CATS

static int anth_font_registry_value = 0;

static inline int anth_font_registry_load(void) {
  return anth_font_registry_value;
}

static inline void anth_font_registry_store(int v) {
  anth_font_registry_value = v;
}

#endif
