#ifndef ANTH_DIAG_CATS
#define ANTH_DIAG_CATS

#include <stdio.h>
#include <unistd.h>
#include <string.h>

#define ANTH_LOG_LEVEL_DEBUG 0
#define ANTH_LOG_LEVEL_INFO 1
#define ANTH_LOG_LEVEL_WARN 2
#define ANTH_LOG_LEVEL_ERROR 3
#define ANTH_LOG_LEVEL_SILENT 4

#define ANTH_LOG_RING_SIZE 128

typedef struct {
    char level[8];
    char file[64];
    int line;
    char tag[16];
    char msg[128];
    char detail[256];
} anth_log_entry_t;

static int anth_log_level = ANTH_LOG_LEVEL_INFO;
static anth_log_entry_t anth_log_ring[ANTH_LOG_RING_SIZE];
static int anth_log_ring_head = 0;
static int anth_log_ring_count = 0;

static inline void anth_diag_set_level(int lvl) {
    if (lvl >= ANTH_LOG_LEVEL_DEBUG && lvl <= ANTH_LOG_LEVEL_SILENT) {
        anth_log_level = lvl;
    }
}

static inline int anth_diag_get_level(void) {
    return anth_log_level;
}

static inline int anth_level_priority(const char *level) {
    if (!level) return ANTH_LOG_LEVEL_INFO;
    if (level[0] == 'D') return ANTH_LOG_LEVEL_DEBUG;
    if (level[0] == 'I') return ANTH_LOG_LEVEL_INFO;
    if (level[0] == 'W') return ANTH_LOG_LEVEL_WARN;
    if (level[0] == 'E') return ANTH_LOG_LEVEL_ERROR;
    return ANTH_LOG_LEVEL_INFO;
}

static inline void anth_diag_log(
    const char *level,
    const char *file,
    int line,
    const char *tag,
    const char *msg,
    const char *detail
) {
    int prio = anth_level_priority(level);

    /* Record in ring buffer for diagnostics */
    int idx = (anth_log_ring_head + anth_log_ring_count) % ANTH_LOG_RING_SIZE;
    if (anth_log_ring_count < ANTH_LOG_RING_SIZE) {
        anth_log_ring_count++;
    } else {
        anth_log_ring_head = (anth_log_ring_head + 1) % ANTH_LOG_RING_SIZE;
    }
    anth_log_entry_t *e = &anth_log_ring[idx];
    strncpy(e->level, level ? level : "LOG", sizeof(e->level) - 1);
    e->level[sizeof(e->level) - 1] = '\0';
    strncpy(e->file, file ? file : "?", sizeof(e->file) - 1);
    e->file[sizeof(e->file) - 1] = '\0';
    e->line = line;
    strncpy(e->tag, tag ? tag : "SYS", sizeof(e->tag) - 1);
    e->tag[sizeof(e->tag) - 1] = '\0';
    strncpy(e->msg, msg ? msg : "", sizeof(e->msg) - 1);
    e->msg[sizeof(e->msg) - 1] = '\0';
    strncpy(e->detail, detail ? detail : "", sizeof(e->detail) - 1);
    e->detail[sizeof(e->detail) - 1] = '\0';

    /* Level filter: swallow if lower than current threshold or silent */
    if (anth_log_level == ANTH_LOG_LEVEL_SILENT || prio < anth_log_level) {
        return;
    }

    int is_term = isatty(fileno(stderr));
    const char *col_lvl = "";
    const char *col_reset = is_term ? "\033[0m" : "";
    if (is_term) {
        if (prio == ANTH_LOG_LEVEL_ERROR) col_lvl = "\033[1;31m";       /* Red */
        else if (prio == ANTH_LOG_LEVEL_WARN) col_lvl = "\033[1;33m";  /* Yellow */
        else if (prio == ANTH_LOG_LEVEL_INFO) col_lvl = "\033[1;36m";  /* Cyan */
        else col_lvl = "\033[1;30m";                                    /* Dark Gray for DEBUG */
    }

    if (detail && detail[0]) {
        fprintf(stderr, "%s[%s]%s [%s:%d] [%s] %s: %s\n",
                col_lvl, level ? level : "LOG", col_reset,
                file ? file : "?", line,
                tag ? tag : "SYS", msg ? msg : "", detail);
    } else {
        fprintf(stderr, "%s[%s]%s [%s:%d] [%s] %s\n",
                col_lvl, level ? level : "LOG", col_reset,
                file ? file : "?", line,
                tag ? tag : "SYS", msg ? msg : "");
    }
    fflush(stderr);
}

#endif
