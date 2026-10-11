#ifndef ANTH_DIAG_CATS
#define ANTH_DIAG_CATS

#include <stdio.h>
#include <unistd.h>

static inline void anth_diag_log(
    const char *level,
    const char *file,
    int line,
    const char *tag,
    const char *msg,
    const char *detail
) {
    int is_term = isatty(fileno(stderr));
    const char *col_lvl = "";
    const char *col_reset = is_term ? "\033[0m" : "";
    if (is_term) {
        if (level && level[0] == 'E') col_lvl = "\033[1;31m";       /* Red for ERROR */
        else if (level && level[0] == 'W') col_lvl = "\033[1;33m";  /* Yellow for WARN */
        else if (level && level[0] == 'I') col_lvl = "\033[1;36m";  /* Cyan for INFO */
        else col_lvl = "\033[1;32m";                                /* Green for OK */
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
