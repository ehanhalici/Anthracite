#ifndef ANTH_ARABIC_CATS
#define ANTH_ARABIC_CATS

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <strings.h>
#include <dirent.h>
#include <unistd.h>
#include <time.h>
#include <ctype.h>
#include "data_font/legacy/text_layout.h"

static inline int anth_is_arabic(int cp) {
    return ((cp >= 0x0600 && cp <= 0x06FF) ||
            (cp >= 0x0750 && cp <= 0x077F) ||
            (cp >= 0x08A0 && cp <= 0x08FF) ||
            (cp >= 0xFB50 && cp <= 0xFDFF) ||
            (cp >= 0xFE70 && cp <= 0xFEFF));
}

static inline int anth_has_arabic(const char *p, int n) {
    if (!p || n <= 0) return 0;
    for (int i = 0; i < n; i++) {
        unsigned char c = (unsigned char)p[i];
        if (c >= 0xD8 && c <= 0xDB) return 1;
        if (c == 0xEF && i + 2 < n) {
            unsigned char c1 = (unsigned char)p[i + 1];
            if (c1 >= 0xAD && c1 <= 0xBF) return 1;
        }
    }
    return 0;
}

static inline int anth_is_transparent(int cp) {
    return ((cp >= 0x064B && cp <= 0x0652) || cp == 0x0670);
}

typedef struct {
    uint8_t grp; /* 0=non, 1=right, 2=dual */
    uint16_t iso, fin, ini, med;
} anth_ar_form;

static const anth_ar_form anth_ar_table[42] = {
    /* 0x0621 */ { 0, 0xFE80, 0, 0, 0 },
    /* 0x0622 */ { 1, 0xFE81, 0xFE82, 0, 0 },
    /* 0x0623 */ { 1, 0xFE83, 0xFE84, 0, 0 },
    /* 0x0624 */ { 1, 0xFE85, 0xFE86, 0, 0 },
    /* 0x0625 */ { 1, 0xFE87, 0xFE88, 0, 0 },
    /* 0x0626 */ { 2, 0xFE89, 0xFE8A, 0xFE8B, 0xFE8C },
    /* 0x0627 */ { 1, 0xFE8D, 0xFE8E, 0, 0 },
    /* 0x0628 */ { 2, 0xFE8F, 0xFE90, 0xFE91, 0xFE92 },
    /* 0x0629 */ { 1, 0xFE93, 0xFE94, 0, 0 },
    /* 0x062A */ { 2, 0xFE95, 0xFE96, 0xFE97, 0xFE98 },
    /* 0x062B */ { 2, 0xFE99, 0xFE9A, 0xFE9B, 0xFE9C },
    /* 0x062C */ { 2, 0xFE9D, 0xFE9E, 0xFE9F, 0xFEA0 },
    /* 0x062D */ { 2, 0xFEA1, 0xFEA2, 0xFEA3, 0xFEA4 },
    /* 0x062E */ { 2, 0xFEA5, 0xFEA6, 0xFEA7, 0xFEA8 },
    /* 0x062F */ { 1, 0xFEA9, 0xFEAA, 0, 0 },
    /* 0x0630 */ { 1, 0xFEAB, 0xFEAC, 0, 0 },
    /* 0x0631 */ { 1, 0xFEAD, 0xFEAE, 0, 0 },
    /* 0x0632 */ { 1, 0xFEAF, 0xFEB0, 0, 0 },
    /* 0x0633 */ { 2, 0xFEB1, 0xFEB2, 0xFEB3, 0xFEB4 },
    /* 0x0634 */ { 2, 0xFEB5, 0xFEB6, 0xFEB7, 0xFEB8 },
    /* 0x0635 */ { 2, 0xFEB9, 0xFEBA, 0xFEBB, 0xFEBC },
    /* 0x0636 */ { 2, 0xFEBD, 0xFEBE, 0xFEBF, 0xFEC0 },
    /* 0x0637 */ { 2, 0xFEC1, 0xFEC2, 0xFEC3, 0xFEC4 },
    /* 0x0638 */ { 2, 0xFEC5, 0xFEC6, 0xFEC7, 0xFEC8 },
    /* 0x0639 */ { 2, 0xFEC9, 0xFECA, 0xFECB, 0xFECC },
    /* 0x063A */ { 2, 0xFECD, 0xFECE, 0xFECF, 0xFED0 },
    /* 0x063B */ { 0, 0, 0, 0, 0 },
    /* 0x063C */ { 0, 0, 0, 0, 0 },
    /* 0x063D */ { 0, 0, 0, 0, 0 },
    /* 0x063E */ { 0, 0, 0, 0, 0 },
    /* 0x063F */ { 0, 0, 0, 0, 0 },
    /* 0x0640 */ { 0, 0, 0, 0, 0 },
    /* 0x0641 */ { 2, 0xFED1, 0xFED2, 0xFED3, 0xFED4 },
    /* 0x0642 */ { 2, 0xFED5, 0xFED6, 0xFED7, 0xFED8 },
    /* 0x0643 */ { 2, 0xFED9, 0xFEDA, 0xFEDB, 0xFEDC },
    /* 0x0644 */ { 2, 0xFEDD, 0xFEDE, 0xFEDF, 0xFEE0 },
    /* 0x0645 */ { 2, 0xFEE1, 0xFEE2, 0xFEE3, 0xFEE4 },
    /* 0x0646 */ { 2, 0xFEE5, 0xFEE6, 0xFEE7, 0xFEE8 },
    /* 0x0647 */ { 2, 0xFEE9, 0xFEEA, 0xFEEB, 0xFEEC },
    /* 0x0648 */ { 1, 0xFEED, 0xFEEE, 0, 0 },
    /* 0x0649 */ { 1, 0xFEEF, 0xFEF0, 0, 0 },
    /* 0x064A */ { 2, 0xFEF1, 0xFEF2, 0xFEF3, 0xFEF4 }
};

static inline const anth_ar_form *anth_ar_get(int cp) {
    if (cp >= 0x0621 && cp <= 0x064A) return &anth_ar_table[cp - 0x0621];
    return NULL;
}

static inline int anth_utf8_decode_cp(const char *s, int len, int *idx) {
    int i = *idx;
    if (i >= len) return 0;
    unsigned char b0 = (unsigned char)s[i];
    if (b0 < 0x80) {
        *idx = i + 1;
        return b0;
    }
    if ((b0 & 0xE0) == 0xC0 && i + 1 < len) {
        unsigned char b1 = (unsigned char)s[i + 1];
        *idx = i + 2;
        return ((b0 & 0x1F) << 6) | (b1 & 0x3F);
    }
    if ((b0 & 0xF0) == 0xE0 && i + 2 < len) {
        unsigned char b1 = (unsigned char)s[i + 1];
        unsigned char b2 = (unsigned char)s[i + 2];
        *idx = i + 3;
        return ((b0 & 0x0F) << 12) | ((b1 & 0x3F) << 6) | (b2 & 0x3F);
    }
    if ((b0 & 0xF8) == 0xF0 && i + 3 < len) {
        unsigned char b1 = (unsigned char)s[i + 1];
        unsigned char b2 = (unsigned char)s[i + 2];
        unsigned char b3 = (unsigned char)s[i + 3];
        *idx = i + 4;
        return ((b0 & 0x07) << 18) | ((b1 & 0x3F) << 12) | ((b2 & 0x3F) << 6) | (b3 & 0x3F);
    }
    *idx = i + 1;
    return b0;
}

static inline int anth_utf8_encode_cp(int cp, char *dst, int max, int out_pos) {
    if (cp < 0x80) {
        if (out_pos + 1 > max) return out_pos;
        dst[out_pos++] = (char)cp;
    } else if (cp < 0x800) {
        if (out_pos + 2 > max) return out_pos;
        dst[out_pos++] = (char)(0xC0 | (cp >> 6));
        dst[out_pos++] = (char)(0x80 | (cp & 0x3F));
    } else if (cp < 0x10000) {
        if (out_pos + 3 > max) return out_pos;
        dst[out_pos++] = (char)(0xE0 | (cp >> 12));
        dst[out_pos++] = (char)(0x80 | ((cp >> 6) & 0x3F));
        dst[out_pos++] = (char)(0x80 | (cp & 0x3F));
    } else {
        if (out_pos + 4 > max) return out_pos;
        dst[out_pos++] = (char)(0xF0 | (cp >> 18));
        dst[out_pos++] = (char)(0x80 | ((cp >> 12) & 0x3F));
        dst[out_pos++] = (char)(0x80 | ((cp >> 6) & 0x3F));
        dst[out_pos++] = (char)(0x80 | (cp & 0x3F));
    }
    return out_pos;
}

static inline int anth_ar_shape_word(const int *cps, int n, int *dst) {
    int out_cnt = 0;
    int i = 0;
    while (i < n) {
        int cp = cps[i];
        if (anth_is_transparent(cp)) {
            dst[out_cnt++] = cp;
            i++;
            continue;
        }

        /* Lam-Alif Ligatures */
        if (cp == 0x0644 && i + 1 < n) {
            int nxt = cps[i + 1];
            int iso_la = 0, fin_la = 0;
            if (nxt == 0x0622) { iso_la = 0xFEF5; fin_la = 0xFEF6; }
            else if (nxt == 0x0623) { iso_la = 0xFEF7; fin_la = 0xFEF8; }
            else if (nxt == 0x0625) { iso_la = 0xFEF9; fin_la = 0xFEFA; }
            else if (nxt == 0x0627) { iso_la = 0xFEFB; fin_la = 0xFEFC; }

            if (iso_la) {
                int prev_join = 0;
                int p = i - 1;
                while (p >= 0 && anth_is_transparent(cps[p])) p--;
                if (p >= 0) {
                    const anth_ar_form *pf = anth_ar_get(cps[p]);
                    if (pf && pf->grp == 2) prev_join = 1;
                }
                dst[out_cnt++] = prev_join ? fin_la : iso_la;
                i += 2;
                continue;
            }
        }

        const anth_ar_form *f = anth_ar_get(cp);
        if (!f || f->iso == 0) {
            dst[out_cnt++] = cp;
            i++;
            continue;
        }

        int prev_join = 0;
        int p = i - 1;
        while (p >= 0 && anth_is_transparent(cps[p])) p--;
        if (p >= 0) {
            const anth_ar_form *pf = anth_ar_get(cps[p]);
            if (pf && pf->grp == 2) prev_join = 1;
        }

        int next_join = 0;
        int nx = i + 1;
        while (nx < n && anth_is_transparent(cps[nx])) nx++;
        if (nx < n) {
            const anth_ar_form *nf = anth_ar_get(cps[nx]);
            if (nf && (nf->grp == 1 || nf->grp == 2)) next_join = 1;
        }

        if (f->grp == 2) {
            if (prev_join && next_join) dst[out_cnt++] = f->med ? f->med : f->iso;
            else if (prev_join) dst[out_cnt++] = f->fin ? f->fin : f->iso;
            else if (next_join) dst[out_cnt++] = f->ini ? f->ini : f->iso;
            else dst[out_cnt++] = f->iso;
        } else if (f->grp == 1) {
            if (prev_join) dst[out_cnt++] = f->fin ? f->fin : f->iso;
            else dst[out_cnt++] = f->iso;
        } else {
            dst[out_cnt++] = f->iso;
        }
        i++;
    }
    return out_cnt;
}

static inline int anth_arabic_process_utf8(const char *src, int src_len, char *dst, int dst_max) {
    if (!src || src_len <= 0 || !dst || dst_max <= 0) return 0;
    if (!anth_has_arabic(src, src_len)) {
        int n = src_len < dst_max - 1 ? src_len : dst_max - 1;
        memcpy(dst, src, (size_t)n);
        dst[n] = 0;
        return n;
    }

    int in_cps[2048];
    int n_cps = 0;
    int idx = 0;
    while (idx < src_len && n_cps < 2040) {
        in_cps[n_cps++] = anth_utf8_decode_cp(src, src_len, &idx);
    }

    int out_pos = 0;
    int i = 0;
    while (i < n_cps && out_pos < dst_max - 4) {
        if (anth_is_arabic(in_cps[i])) {
            int run_st = i;
            while (i < n_cps && (anth_is_arabic(in_cps[i]) || (in_cps[i] == ' ' && i + 1 < n_cps && anth_is_arabic(in_cps[i+1])))) {
                i++;
            }
            int run_en = i;

            int words_st[128];
            int words_len[128];
            int n_words = 0;

            int shaped[2048];
            int n_shaped = 0;

            int w_start = run_st;
            while (w_start < run_en && n_words < 120) {
                while (w_start < run_en && in_cps[w_start] == ' ') {
                    words_st[n_words] = n_shaped;
                    words_len[n_words] = 1;
                    shaped[n_shaped++] = ' ';
                    n_words++;
                    w_start++;
                }
                if (w_start >= run_en) break;
                int w_end = w_start;
                while (w_end < run_en && in_cps[w_end] != ' ') w_end++;

                int word_buf[256];
                int wn = w_end - w_start;
                if (wn > 250) wn = 250;
                for (int k = 0; k < wn; k++) word_buf[k] = in_cps[w_start + k];

                words_st[n_words] = n_shaped;
                int sn = anth_ar_shape_word(word_buf, wn, &shaped[n_shaped]);
                words_len[n_words] = sn;
                n_shaped += sn;
                n_words++;
                w_start = w_end;
            }

            /* Visual RTL order: reverse word sequence and characters in each word */
            for (int w = n_words - 1; w >= 0; w--) {
                int st = words_st[w];
                int len = words_len[w];
                if (len == 1 && shaped[st] == ' ') {
                    out_pos = anth_utf8_encode_cp(' ', dst, dst_max - 1, out_pos);
                } else {
                    for (int ch = st + len - 1; ch >= st; ch--) {
                        out_pos = anth_utf8_encode_cp(shaped[ch], dst, dst_max - 1, out_pos);
                    }
                }
            }
        } else {
            out_pos = anth_utf8_encode_cp(in_cps[i], dst, dst_max - 1, out_pos);
            i++;
        }
    }
    dst[out_pos] = 0;
    return out_pos;
}

typedef int (*anth_width_fn)(void *f, void *r, const char *p, int n);

static inline int anth_line_visual_adv(
    const char *line, int line_len, int off,
    void *f, void *r, anth_width_fn wfn
) {
    if (!line || line_len <= 0) return 0;
    if (off < 0) off = 0;
    if (off > line_len) off = line_len;
    if (!anth_has_arabic(line, line_len)) {
        if (off == 0) return 0;
        return wfn(f, r, line, off);
    }

    int pos = 0;
    int cur_x = 0;
    while (pos < line_len) {
        int idx = pos;
        int cp = anth_utf8_decode_cp(line, line_len, &idx);
        int is_ar = anth_is_arabic(cp);
        int run_st = pos;
        int run_en = idx;
        while (run_en < line_len) {
            int nxt_idx = run_en;
            int nxt_cp = anth_utf8_decode_cp(line, line_len, &nxt_idx);
            if (anth_is_arabic(nxt_cp) != is_ar) {
                if (nxt_cp == ' ' && is_ar) {
                    int look = nxt_idx;
                    int lcp = anth_utf8_decode_cp(line, line_len, &look);
                    if (anth_is_arabic(lcp)) {
                        run_en = nxt_idx;
                        continue;
                    }
                }
                break;
            }
            run_en = nxt_idx;
        }

        int run_len = run_en - run_st;
        int run_w = wfn(f, r, line + run_st, run_len);

        if (off >= run_st && off <= run_en) {
            if (!is_ar) {
                int pre_len = off - run_st;
                int pre_w = pre_len > 0 ? wfn(f, r, line + run_st, pre_len) : 0;
                return cur_x + pre_w;
            } else {
                int pre_len = off - run_st;
                int pre_w = pre_len > 0 ? wfn(f, r, line + run_st, pre_len) : 0;
                return cur_x + (run_w - pre_w);
            }
        }

        cur_x += run_w;
        pos = run_en;
    }
    return cur_x;
}

static inline int anth_line_click_offset(
    const char *line, int line_len, int target_x,
    void *f, void *r, anth_width_fn wfn
) {
    if (!line || line_len <= 0) return 0;
    if (target_x < 0) target_x = 0;
    if (!anth_has_arabic(line, line_len)) {
        int pos = 0;
        int best_pos = 0;
        int min_diff = target_x > 0 ? target_x : -target_x;
        while (pos < line_len) {
            int w = wfn(f, r, line, pos);
            int diff = abs(w - target_x);
            if (diff < min_diff) {
                min_diff = diff;
                best_pos = pos;
            }
            if (w >= target_x) break;
            int idx = pos;
            anth_utf8_decode_cp(line, line_len, &idx);
            pos = idx;
        }
        int w_end = wfn(f, r, line, line_len);
        if (abs(w_end - target_x) < min_diff) best_pos = line_len;
        return best_pos;
    }

    int pos = 0;
    int best_pos = 0;
    int min_diff = 1000000;
    while (pos <= line_len) {
        int adv = anth_line_visual_adv(line, line_len, pos, f, r, wfn);
        int diff = abs(adv - target_x);
        if (diff < min_diff) {
            min_diff = diff;
            best_pos = pos;
        }
        if (pos >= line_len) break;
        int idx = pos;
        anth_utf8_decode_cp(line, line_len, &idx);
        pos = idx;
    }
    return best_pos;
}

static inline int anth_is_arabic_at(const char *data, int len, int pos) {
    if (!data || len <= 0 || pos < 0) return 0;
    if (pos < len) {
        int idx = pos;
        int cp = anth_utf8_decode_cp(data, len, &idx);
        if (anth_is_arabic(cp)) return 1;
    }
    if (pos > 0) {
        int prev = pos - 1;
        while (prev > 0 && ((unsigned char)data[prev] & 0xC0) == 0x80) prev--;
        int pidx = prev;
        int pcp = anth_utf8_decode_cp(data, len, &pidx);
        if (anth_is_arabic(pcp)) return 1;
    }
    return 0;
}

static inline int anth_is_strong_rtl(int cp) {
    return ((cp >= 0x0590 && cp <= 0x08FF) ||
            (cp >= 0xFB1D && cp <= 0xFDFF) ||
            (cp >= 0xFE70 && cp <= 0xFEFC));
}

static inline int anth_line_is_rtl(const char *line, int len) {
    return anth_bidi_line_direction(line, len);
}

static inline void anth_draw_wrap_arrow(void *f, void *r, int x, int y, unsigned int col) {
    extern void anth_ui_wrap_marker(void *r, int x, int y, unsigned int col);
    (void)f;
    anth_ui_wrap_marker(r, x, y, col);
}

static inline int anth_font_draw_buf(void *f, void *r, int x, int y, const char *p, int n, unsigned int c) {
    if (!p || n <= 0) return 0;
    extern int anth_font_draw(void *f, void *r, int x, int y, void *p, int n, unsigned int c);
    extern int anth_font_text_active(void *f);
    if (anth_font_text_active(f)) return anth_font_draw(f, r, x, y, (void *)p, n, c);
    if (!anth_has_arabic_text(p, n)) {
        return anth_font_draw(f, r, x, y, (void *)p, n, c);
    }
    char buf[2048];
    int sn = anth_arabic_process_utf8(p, n, buf, sizeof(buf));
    return anth_font_draw(f, r, x, y, buf, sn, c);
}

static inline int anth_font_width_buf(void *f, void *r, const char *p, int n) {
    if (!p || n <= 0) return 0;
    extern int anth_font_width(void *f, void *r, void *p, int n);
    extern int anth_font_text_active(void *f);
    if (anth_font_text_active(f)) return anth_font_width(f, r, (void *)p, n);
    if (!anth_has_arabic_text(p, n)) {
        return anth_font_width(f, r, (void *)p, n);
    }
    char buf[2048];
    int sn = anth_arabic_process_utf8(p, n, buf, sizeof(buf));
    return anth_font_width(f, r, buf, sn);
}

extern int anth_font_width(void *f, void *r, void *p, int n);

static inline int anth_ui_caret_adv(void *f, void *r, const char *line, int line_len, int off) {
    return anth_layout_visual_adv(line, line_len, off, f, r, (anth_width_fn)anth_font_width_buf);
}

static inline int anth_ui_click_off(void *f, void *r, const char *line, int line_len, int target_x) {
    return anth_layout_click_offset(line, line_len, target_x, f, r, (anth_width_fn)anth_font_width_buf);
}

static inline void anth_ui_sel_span(void *f, void *r, const char *line, int line_len, int sa, int sb, int at_eol, int *out_sx, int *out_sw) {
    anth_layout_sel_span(line, line_len, sa, sb, at_eol, f, r, (anth_width_fn)anth_font_width_buf, out_sx, out_sw);
}

static int anth_flash_line = -1;
static int64_t anth_flash_until_ns = 0;

static inline int64_t anth_mono_ns_now(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (int64_t)ts.tv_sec * 1000000000LL + (int64_t)ts.tv_nsec;
}

static inline void anth_set_flash_line(int line) {
    anth_flash_line = line;
    anth_flash_until_ns = anth_mono_ns_now() + 1000000000LL;
}

static inline int anth_get_flash_line(void) {
    if (anth_flash_line >= 0 && anth_mono_ns_now() < anth_flash_until_ns) {
        return anth_flash_line;
    }
    return -1;
}

static inline int anth_vault_find_rec(const char *dir, const char *target, char *out, int max_len, int depth) {
    if (depth > 12 || !dir) return 0;
    DIR *dp = opendir(dir);
    if (!dp) return 0;
    struct dirent *de;
    int found = 0;
    char subdirs[64][256];
    int n_subdirs = 0;

    while ((de = readdir(dp)) != NULL) {
        if (de->d_name[0] == '.') continue;
        if (strcasecmp(de->d_name, target) == 0) {
            snprintf(out, (size_t)max_len, "%s/%s", dir, de->d_name);
            found = 1;
            break;
        }
        char target_md[256];
        snprintf(target_md, sizeof(target_md), "%s.md", target);
        if (strcasecmp(de->d_name, target_md) == 0) {
            snprintf(out, (size_t)max_len, "%s/%s", dir, de->d_name);
            found = 1;
            break;
        }
        if (de->d_type == DT_DIR && n_subdirs < 64) {
            snprintf(subdirs[n_subdirs], sizeof(subdirs[n_subdirs]), "%s/%s", dir, de->d_name);
            n_subdirs++;
        }
    }
    closedir(dp);
    if (found) return 1;

    for (int i = 0; i < n_subdirs; i++) {
        if (anth_vault_find_rec(subdirs[i], target, out, max_len, depth + 1)) {
            return 1;
        }
    }
    return 0;
}

static inline int anth_read_active_vault_fallback(char *out_vault, int max_len) {
    if (!out_vault || max_len < 2) return 0;
    out_vault[0] = '\0';
    const char *home = getenv("HOME");
    if (!home) return 0;
    char path[1024];
    snprintf(path, sizeof(path), "%s/.config/anthracite/vaults.json", home);
    FILE *fp = fopen(path, "rb");
    if (!fp) return 0;
    char buf[4096];
    size_t nr = fread(buf, 1, sizeof(buf) - 1, fp);
    fclose(fp);
    if (nr <= 0) return 0;
    buf[nr] = '\0';
    const char *key = "\"active_vault\":";
    char *p = strstr(buf, key);
    if (!p) {
        key = "\"active\":";
        p = strstr(buf, key);
    }
    if (!p) return 0;
    p += strlen(key);
    while (*p && (*p == ' ' || *p == '\t' || *p == '\r' || *p == '\n')) p++;
    if (*p != '\"') return 0;
    p++;
    char *q = strchr(p, '\"');
    if (!q) return 0;
    int len = (int)(q - p);
    if (len <= 0 || len >= max_len) return 0;
    memcpy(out_vault, p, (size_t)len);
    out_vault[len] = '\0';
    return 1;
}

static inline int anth_vault_check_in_dir(const char *vault, const char *rel, char *out, int max_len) {
    if (!vault || !vault[0] || !rel || !rel[0]) return 0;
    const char *r = (rel[0] == '/') ? rel + 1 : rel;
    char combined[1024];
    snprintf(combined, sizeof(combined), "%s/%s", vault, r);
    if (access(combined, F_OK) == 0) {
        snprintf(out, (size_t)max_len, "%s", combined);
        return 1;
    }
    char combined_md[1024];
    snprintf(combined_md, sizeof(combined_md), "%s.md", combined);
    if (access(combined_md, F_OK) == 0) {
        snprintf(out, (size_t)max_len, "%s", combined_md);
        return 1;
    }
    const char *base = strrchr(rel, '/');
    const char *target = base ? base + 1 : rel;
    if (target[0] && anth_vault_find_rec(vault, target, out, max_len, 0)) {
        return 1;
    }
    return 0;
}

static inline int anth_vault_find_file(const char *vault, const char *rel, char *out, int max_len) {
    if (!rel || !rel[0] || !out || max_len < 2) return 0;
    if (access(rel, F_OK) == 0) {
        snprintf(out, (size_t)max_len, "%s", rel);
        return 1;
    }
    if (vault && vault[0] && anth_vault_check_in_dir(vault, rel, out, max_len)) {
        return 1;
    }
    char act_v[1024];
    if (anth_read_active_vault_fallback(act_v, sizeof(act_v))) {
        if (!vault || strcmp(vault, act_v) != 0) {
            if (anth_vault_check_in_dir(act_v, rel, out, max_len)) {
                return 1;
            }
        }
    }
    const char *home = getenv("HOME");
    if (home) {
        char def_v[1024];
        snprintf(def_v, sizeof(def_v), "%s/notes/obsidian_notlar", home);
        if (access(def_v, F_OK) == 0 && (!vault || strcmp(vault, def_v) != 0)) {
            if (anth_vault_check_in_dir(def_v, rel, out, max_len)) {
                return 1;
            }
        }
    }
    return 0;
}

static inline int anth_buf_advance_cps(const char *p, int n, int start, int k) {
    if (!p || start >= n || k <= 0) return start;
    int cur = start;
    int count = 0;
    while (cur < n && count < k) {
        anth_utf8_decode_safe(p, n, &cur);
        count++;
    }
    return cur;
}

static inline int anth_buf_count_cps(const char *p, int n, int start, int end) {
    if (!p || start >= end || start >= n) return 0;
    int limit = (end < n) ? end : n;
    int cur = start;
    int count = 0;
    while (cur < limit) {
        anth_utf8_decode_safe(p, limit, &cur);
        count++;
    }
    return count;
}

#define ANTH_COL_TEXT    0xE6E1D8FFu
#define ANTH_COL_HEADING 0xF4F1EAFFu
#define ANTH_COL_LINK    0x58A6FFFFu
#define ANTH_COL_WHITE   0xFFFFFFFFu
#define ANTH_COL_ACCENT  0xC4B8A5FFu
#define ANTH_COL_MUTED   0x8E8A84FFu
#define ANTH_COL_CODE    0xD7C4A3FFu
#define ANTH_COL_TAG     0xD7A36AFFu
#define ANTH_COL_TASK    0x9BB8A0FFu

typedef struct {
    const char *text;
    int len;
    unsigned int color;
} anth_span_t;

static inline int anth_parse_line_spans(const char *buf, int n, int ls, int le, anth_span_t *spans, int max_spans) {
    if (!buf || ls >= le || max_spans < 1) return 0;
    while (ls < le && (buf[ls] == ' ' || buf[ls] == '\t')) ls++;
    int nspans = 0;
    const char *p = buf + ls;
    const char *end = buf + le;

    unsigned int def_col = ANTH_COL_TEXT;
    if (p < end && *p == '#') {
        const char *h = p;
        while (h < end && *h == '#') h++;
        if (h < end && *h == ' ') {
            p = h + 1;
            def_col = ANTH_COL_HEADING;
        }
    }

    if (p + 5 < end && (p[0] == '-' || p[0] == '*') && p[1] == ' ' && p[2] == '[' && (p[3] == ' ' || p[3] == 'x' || p[3] == 'X') && p[4] == ']' && p[5] == ' ') {
        spans[nspans++] = (anth_span_t){ (p[3] == ' ' ? "[ ] " : "[x] "), 4, ANTH_COL_TASK };
        p += 6;
    } else if (p + 1 < end && (p[0] == '-' || p[0] == '*') && p[1] == ' ') {
        static const char bullet[] = "\xe2\x80\xa2 ";
        spans[nspans++] = (anth_span_t){ bullet, 3, ANTH_COL_MUTED };
        p += 2;
    }

    while (p < end && nspans < max_spans) {
        if (*p == '^' && (p == buf + ls || p[-1] == ' ' || p[-1] == '\t')) {
            const char *q = p + 1;
            while (q < end && (isalnum((unsigned char)*q) || *q == '_' || *q == '-')) q++;
            if (q == end || *q == ' ' || *q == '\t' || *q == '\r' || *q == '\n') {
                p = q;
                continue;
            }
        }

        if (p + 1 < end && p[0] == '[' && p[1] == '[') {
            const char *close = NULL;
            for (const char *c = p + 2; c + 1 < end; c++) {
                if (c[0] == ']' && c[1] == ']') { close = c; break; }
            }
            if (close) {
                const char *inner = p + 2;
                int inner_len = (int)(close - inner);
                const char *pipe = (const char *)memchr(inner, '|', (size_t)inner_len);
                const char *show_txt = pipe ? pipe + 1 : inner;
                int show_len = (int)(close - show_txt);
                if (show_len > 0) {
                    spans[nspans++] = (anth_span_t){ show_txt, show_len, ANTH_COL_LINK };
                }
                p = close + 2;
                continue;
            }
        }

        if (*p == '[') {
            const char *close_b = (const char *)memchr(p + 1, ']', (size_t)(end - (p + 1)));
            if (close_b && close_b + 1 < end && close_b[1] == '(') {
                const char *close_p = (const char *)memchr(close_b + 2, ')', (size_t)(end - (close_b + 2)));
                if (close_p) {
                    const char *lbl = p + 1;
                    int lbl_len = (int)(close_b - lbl);
                    if (lbl_len >= 4 && lbl[0] == '*' && lbl[1] == '*' && lbl[lbl_len-2] == '*' && lbl[lbl_len-1] == '*') {
                        spans[nspans++] = (anth_span_t){ lbl + 2, lbl_len - 4, ANTH_COL_LINK };
                    } else if (lbl_len >= 2 && lbl[0] == '*' && lbl[lbl_len-1] == '*') {
                        spans[nspans++] = (anth_span_t){ lbl + 1, lbl_len - 2, ANTH_COL_LINK };
                    } else if (lbl_len > 0) {
                        spans[nspans++] = (anth_span_t){ lbl, lbl_len, ANTH_COL_LINK };
                    }
                    p = close_p + 1;
                    continue;
                }
            }
        }

        if (p + 1 < end && p[0] == '*' && p[1] == '*') {
            const char *close_b = NULL;
            for (const char *c = p + 2; c + 1 < end; c++) {
                if (c[0] == '*' && c[1] == '*') { close_b = c; break; }
            }
            if (close_b) {
                int b_len = (int)(close_b - (p + 2));
                if (b_len > 0) {
                    spans[nspans++] = (anth_span_t){ p + 2, b_len, ANTH_COL_WHITE };
                }
                p = close_b + 2;
                continue;
            }
        }

        if (*p == '*' && (p + 1 == end || p[1] != '*')) {
            const char *close_i = (const char *)memchr(p + 1, '*', (size_t)(end - (p + 1)));
            if (close_i) {
                int i_len = (int)(close_i - (p + 1));
                if (i_len > 0) {
                    spans[nspans++] = (anth_span_t){ p + 1, i_len, ANTH_COL_ACCENT };
                }
                p = close_i + 1;
                continue;
            }
        }

        if (*p == '`') {
            const char *close_c = (const char *)memchr(p + 1, '`', (size_t)(end - (p + 1)));
            if (close_c) {
                int c_len = (int)(close_c - (p + 1));
                if (c_len > 0) {
                    spans[nspans++] = (anth_span_t){ p + 1, c_len, ANTH_COL_CODE };
                }
                p = close_c + 1;
                continue;
            }
        }

        const char *t_start = p;
        while (p < end) {
            if (*p == '[' || *p == '*' || *p == '`' || *p == '^') break;
            p++;
        }
        if (p > t_start) {
            spans[nspans++] = (anth_span_t){ t_start, (int)(p - t_start), def_col };
        }
    }
    return nspans;
}

static inline int anth_render_spans(void *f, void *r, const anth_span_t *spans, int nspans,
                                    int left_x, int start_y, int lh, int wc,
                                    unsigned int arrow_col, int draw) {
    if (nspans <= 0) return 1;
    int cur_col = 0;
    int pen_x = left_x;
    int cur_y = start_y;
    int rows = 1;

    for (int s = 0; s < nspans; s++) {
        const char *txt = spans[s].text;
        int tlen = spans[s].len;
        if (tlen <= 0) continue;
        unsigned int col = spans[s].color;

        int byte_off = 0;
        while (byte_off < tlen) {
            int rem_cols = (wc > 0) ? (wc - cur_col) : 1000000;
            if (rem_cols <= 0) {
                if (draw) {
                    anth_draw_wrap_arrow(f, r, pen_x, cur_y, arrow_col);
                }
                cur_y += lh;
                pen_x = left_x;
                cur_col = 0;
                rows++;
                rem_cols = (wc > 0) ? wc : 1000000;
            }

            int chunk_start = byte_off;
            int chunk_end = anth_buf_advance_cps(txt, tlen, chunk_start, rem_cols);
            int chunk_cps = anth_buf_count_cps(txt, tlen, chunk_start, chunk_end);
            int chunk_bytes = chunk_end - chunk_start;

            if (chunk_bytes > 0) {
                if (draw) {
                    anth_font_draw_buf(f, r, pen_x, cur_y, txt + chunk_start, chunk_bytes, col);
                }
                int tw = 0;
                if (draw) {
                    tw = anth_font_width_buf(f, r, txt + chunk_start, chunk_bytes);
                } else {
                    tw = chunk_cps * 9;
                }
                pen_x += tw;
                cur_col += chunk_cps;
                byte_off = chunk_end;
            }

            if (wc > 0 && cur_col >= wc && (byte_off < tlen || s + 1 < nspans)) {
                if (draw) {
                    anth_draw_wrap_arrow(f, r, pen_x, cur_y, arrow_col);
                }
                cur_y += lh;
                pen_x = left_x;
                cur_col = 0;
                rows++;
            }
        }
    }
    return (rows > 0 ? rows : 1);
}

static inline int anth_draw_wrapped_slice(void *f, void *r, const char *buf, int n, int ls, int le,
                                          int x, int y, int lh, int wc, unsigned int col, unsigned int arrow_col) {
    if (!buf || ls >= n || le > n) return 0;
    anth_span_t spans[128];
    int nspans = anth_parse_line_spans(buf, n, ls, le, spans, 128);
    if (nspans <= 0) return 1;
    return anth_render_spans(f, r, spans, nspans, x, y, lh, wc, arrow_col, 1);
}

static inline int anth_draw_wrapped_lines(void *f, void *r, const char *buf, int n, int max_lines,
                                          int x, int y, int lh, int wc, unsigned int col, unsigned int arrow_col) {
    if (!buf || n <= 0) return 0;
    int cur_i = 0;
    int cur_y = y;
    int total_rows = 0;
    for (int l = 0; l < max_lines && cur_i < n; l++) {
        int eol = cur_i;
        while (eol < n && buf[eol] != '\n') eol++;
        if (eol > cur_i) {
            int rows = anth_draw_wrapped_slice(f, r, buf, n, cur_i, eol, x, cur_y, lh, wc, col, arrow_col);
            int safe_r = (rows > 0) ? rows : 1;
            cur_y += safe_r * lh;
            total_rows += safe_r;
        } else {
            cur_y += lh;
            total_rows += 1;
        }
        cur_i = (eol < n && buf[eol] == '\n') ? eol + 1 : eol;
    }
    return (total_rows > 0 ? total_rows : 1);
}

static inline int anth_embed_calc_height_buf(const char *buf, int n, const char *anchor, int wrap_cols, int lh) {
    if (!buf || n <= 0 || lh <= 0) return (lh > 0 ? lh : 18);

    int total_rows = 1;
    if (anchor && anchor[0]) {
        char *pos = strstr(buf, anchor);
        if (pos) {
            int p_idx = (int)(pos - buf);
            int ls = p_idx;
            while (ls > 0 && buf[ls - 1] != '\n') ls--;
            int le = p_idx;
            while (le > ls && (buf[le - 1] == ' ' || buf[le - 1] == '\t' || buf[le - 1] == '#' || buf[le - 1] == '^')) {
                le--;
            }
            anth_span_t spans[128];
            int nspans = anth_parse_line_spans(buf, n, ls, le, spans, 128);
            total_rows = anth_render_spans(NULL, NULL, spans, nspans, 0, 0, lh, wrap_cols, 0, 0);
        } else {
            total_rows = 1;
        }
    } else {
        int cur_i = 0;
        int sum_r = 0;
        for (int l = 0; l < 4 && cur_i < n; l++) {
            int eol = cur_i;
            while (eol < n && buf[eol] != '\n') eol++;
            if (eol > cur_i) {
                anth_span_t spans[128];
                int nspans = anth_parse_line_spans(buf, n, cur_i, eol, spans, 128);
                int r = anth_render_spans(NULL, NULL, spans, nspans, 0, 0, lh, wrap_cols, 0, 0);
                sum_r += (r > 0 ? r : 1);
            } else {
                sum_r += 1;
            }
            cur_i = (eol < n && buf[eol] == '\n') ? eol + 1 : eol;
        }
        total_rows = (sum_r > 0) ? sum_r : 1;
    }
    if (total_rows < 1) total_rows = 1;
    return total_rows * lh;
}

static inline const char *anth_resolve_vault_path(const char *vault, const char *rel) {
    static char buf[1024];
    if (!rel) return "";
    if (anth_vault_find_file(vault, rel, buf, sizeof(buf))) {
        return buf;
    }
    if (rel[0] == '/') {
        snprintf(buf, sizeof(buf), "%s/%s", (vault && vault[0]) ? vault : ".", rel + 1);
        return buf;
    }
    snprintf(buf, sizeof(buf), "%s/%s", (vault && vault[0]) ? vault : ".", rel);
    return buf;
}

static inline const char *anth_check_media_folder(const char *vault, const char *sub, const char *rel) {
    static char path[1024];
    if (!vault || !rel || !sub) return "";
    int slash = (rel[0] == '/');
    const char *r = slash ? rel + 1 : rel;
    snprintf(path, sizeof(path), "%s/%s%s", vault, sub, r);
    FILE *f = fopen(path, "rb");
    if (f) {
        fclose(f);
        return path;
    }
    return "";
}

#endif /* ANTH_ARABIC_CATS */
