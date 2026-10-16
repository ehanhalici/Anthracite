#ifndef ANTH_IMG_JPG_PROG_CATS
#define ANTH_IMG_JPG_PROG_CATS

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-function"
#pragma clang diagnostic ignored "-Wsign-compare"
#pragma clang diagnostic ignored "-Wmissing-field-initializers"

#define STBI_NO_STDIO
#define STBI_ONLY_JPEG
#define STB_IMAGE_STATIC
#define STB_IMAGE_IMPLEMENTATION

#include "stb/stb_image.h"

#pragma clang diagnostic pop

static inline void *anth_decode_jpg_fallback(
    const void *buf, int len, int *out_w, int *out_h
) {
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

static inline void anth_free_jpg_fallback(void *p) {
    if (p) stbi_image_free(p);
}

static inline int anth_jpg_ptr_is_null(const void *p) {
    return p == NULL ? 1 : 0;
}

#endif /* ANTH_IMG_JPG_PROG_CATS */
