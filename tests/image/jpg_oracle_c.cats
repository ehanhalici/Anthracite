#ifndef ANTH_JPG_ORACLE_C_CATS
#define ANTH_JPG_ORACLE_C_CATS

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-function"
#pragma clang diagnostic ignored "-Wsign-compare"
#pragma clang diagnostic ignored "-Wmissing-field-initializers"

#define STBI_NO_SIMD
#define STBI_NO_STDIO
#define STBI_ONLY_JPEG
#define STB_IMAGE_STATIC
#define STB_IMAGE_IMPLEMENTATION

#include "stb/stb_image.h"

#pragma clang diagnostic pop

static inline void *oracle_c_decode(const void *buf, int len, int *out_w, int *out_h) {
    if (!buf || len <= 0) {
        *out_w = 0;
        *out_h = 0;
        return NULL;
    }
    int w = 0, h = 0, ch = 0;
    unsigned char *data = stbi_load_from_memory((const unsigned char *)buf, len, &w, &h, &ch, 4);
    if (!data) {
        *out_w = 0;
        *out_h = 0;
        return NULL;
    }
    *out_w = w;
    *out_h = h;
    return (void *)data;
}

static inline void oracle_c_free(void *p) {
    if (p) stbi_image_free(p);
}

static inline int oracle_c_is_null(const void *p) {
    return p == NULL;
}

static inline int oracle_c_byte_at(const void *p, int i) {
    return ((const unsigned char *)p)[i];
}

static inline void oracle_c_print_result(const char *name, int ok) {
    printf("%s=%d\n", name, ok);
}

static inline void oracle_c_print_fixture(const char *path, int errors) {
    printf("event=jpeg_fixture path=%s errors=%d\n", path, errors);
}

#endif
