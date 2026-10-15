#ifndef ANTH_EMBED_FSM_CATS
#define ANTH_EMBED_FSM_CATS

#include <string.h>
#include <sys/stat.h>

#define ANTH_EMBED_STATE_UNLOADED 0
#define ANTH_EMBED_STATE_RESOLVING 1
#define ANTH_EMBED_STATE_CACHED 2
#define ANTH_EMBED_STATE_FAILED 3

#define ANTH_EMBED_TABLE_CAP 64

typedef struct {
    char path[256];
    int mtime;
    int colw;
    int lh;
    int height;
    int state;
} anth_embed_slot_t;

static anth_embed_slot_t anth_embed_table[ANTH_EMBED_TABLE_CAP];
static int anth_embed_count = 0;

static inline int anth_embed_file_mtime(const char *p) {
    if (!p || !p[0]) return 0;
    struct stat st;
    if (stat(p, &st) != 0) return 0;
    return (int)st.st_mtime;
}

static inline int anth_embed_fsm_query(const char *path, int colw, int lh, int *out_h) {
    if (!path || !path[0]) return ANTH_EMBED_STATE_FAILED;
    int mt = anth_embed_file_mtime(path);
    if (mt == 0) return ANTH_EMBED_STATE_FAILED;

    for (int i = 0; i < anth_embed_count; ++i) {
        anth_embed_slot_t *s = &anth_embed_table[i];
        if (s->colw == colw && s->lh == lh && strncmp(s->path, path, sizeof(s->path)) == 0) {
            if (s->mtime == mt) {
                if (s->state == ANTH_EMBED_STATE_CACHED) {
                    if (out_h) *out_h = s->height;
                    return ANTH_EMBED_STATE_CACHED;
                }
                if (s->state == ANTH_EMBED_STATE_FAILED) {
                    if (out_h) *out_h = lh + 8;
                    return ANTH_EMBED_STATE_FAILED;
                }
            }
            return ANTH_EMBED_STATE_UNLOADED;
        }
    }
    return ANTH_EMBED_STATE_UNLOADED;
}

static inline void anth_embed_fsm_store(const char *path, int colw, int lh, int height) {
    if (!path || !path[0]) return;
    int mt = anth_embed_file_mtime(path);

    for (int i = 0; i < anth_embed_count; ++i) {
        anth_embed_slot_t *s = &anth_embed_table[i];
        if (s->colw == colw && s->lh == lh && strncmp(s->path, path, sizeof(s->path)) == 0) {
            s->mtime = mt;
            s->height = height;
            s->state = ANTH_EMBED_STATE_CACHED;
            return;
        }
    }

    int idx = (anth_embed_count < ANTH_EMBED_TABLE_CAP) ? (anth_embed_count++) : 0;
    anth_embed_slot_t *s = &anth_embed_table[idx];
    strncpy(s->path, path, sizeof(s->path) - 1);
    s->path[sizeof(s->path) - 1] = '\0';
    s->mtime = mt;
    s->colw = colw;
    s->lh = lh;
    s->height = height;
    s->state = ANTH_EMBED_STATE_CACHED;
}

static inline void anth_embed_fsm_fail(const char *path, int colw, int lh) {
    if (!path || !path[0]) return;
    int mt = anth_embed_file_mtime(path);

    for (int i = 0; i < anth_embed_count; ++i) {
        anth_embed_slot_t *s = &anth_embed_table[i];
        if (s->colw == colw && s->lh == lh && strncmp(s->path, path, sizeof(s->path)) == 0) {
            s->mtime = mt;
            s->state = ANTH_EMBED_STATE_FAILED;
            return;
        }
    }

    int idx = (anth_embed_count < ANTH_EMBED_TABLE_CAP) ? (anth_embed_count++) : 0;
    anth_embed_slot_t *s = &anth_embed_table[idx];
    strncpy(s->path, path, sizeof(s->path) - 1);
    s->path[sizeof(s->path) - 1] = '\0';
    s->mtime = mt;
    s->colw = colw;
    s->lh = lh;
    s->height = lh + 8;
    s->state = ANTH_EMBED_STATE_FAILED;
}

static inline void anth_embed_fsm_clear(void) {
    anth_embed_count = 0;
}

#endif /* ANTH_EMBED_FSM_CATS */
