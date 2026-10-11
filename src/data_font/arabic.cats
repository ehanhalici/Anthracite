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

static inline int anth_fc_arabic_font(char *dst, int n) {
    if (!dst || n < 2) return 0;
    const char *candidates[] = {
        "/nix/store/v3n8r3sy38l5f1sj76azj1n4n0ndd6a7-dejavu-fonts-2.37/share/fonts/truetype/DejaVuSans.ttf",
        "/nix/store/ba8rnmi3ha6p3j8xc85hdq1p9dq3mr6q-dejavu-fonts-minimal-2.37/share/fonts/truetype/DejaVuSans.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        "/usr/share/fonts/truetype/freefont/FreeSerif.ttf",
        0
    };
    for (int i = 0; candidates[i]; i++) {
        FILE *f = fopen(candidates[i], "rb");
        if (f) {
            fclose(f);
            snprintf(dst, (size_t)n, "%s", candidates[i]);
            return 1;
        }
    }
    /* Try fontconfig */
    FILE *p = popen("fc-match :lang=ar file 2>/dev/null", "r");
    if (p) {
        char buf[512];
        if (fgets(buf, sizeof(buf), p)) {
            char *c = strstr(buf, "file=");
            if (c) {
                c += 5;
                char *nl = strchr(c, '\n');
                if (nl) *nl = 0;
                char *sp = strchr(c, ' ');
                if (sp) *sp = 0;
                snprintf(dst, (size_t)n, "%s", c);
                pclose(p);
                return 1;
            }
        }
        pclose(p);
    }
    dst[0] = 0;
    return 0;
}

static uint8_t *anth_fb_data = NULL;
static int anth_fb_size = 0;
static int anth_fb_is_active = 0;

static inline int anth_fb_active(void) {
    return anth_fb_is_active;
}

static inline void anth_fb_set_active(int a) {
    anth_fb_is_active = a;
}

static inline int anth_fb_load(const char *path) {
    if (anth_fb_data) return 1;
    if (!path || !path[0]) return 0;
    FILE *f = fopen(path, "rb");
    if (!f) return 0;
    fseek(f, 0, SEEK_END);
    long sz = ftell(f);
    fseek(f, 0, SEEK_SET);
    if (sz <= 12 || sz > 20000000) {
        fclose(f);
        return 0;
    }
    anth_fb_data = (uint8_t *)malloc((size_t)sz);
    if (!anth_fb_data) {
        fclose(f);
        return 0;
    }
    size_t nr = fread(anth_fb_data, 1, (size_t)sz, f);
    fclose(f);
    anth_fb_size = (int)nr;
    return 1;
}

static inline int anth_fb_u8(int o) {
    if (!anth_fb_data || o < 0 || o >= anth_fb_size) return 0;
    return anth_fb_data[o];
}

static inline int anth_fb_u16(int o) {
    return anth_fb_u8(o) * 256 + anth_fb_u8(o + 1);
}

static inline int anth_fb_i16(int o) {
    int v = anth_fb_u16(o);
    return (v >= 32768) ? v - 65536 : v;
}

static inline int anth_fb_u32(int o) {
    int hi = anth_fb_u16(o);
    int lo = anth_fb_u16(o + 2);
    return (hi << 16) | (lo & 0xFFFF);
}

typedef int (*anth_width_fn)(void *f, void *r, const char *p, int n);

static inline int anth_line_visual_adv(
    const char *line, int line_len, int off,
    void *f, void *r, anth_width_fn wfn
) {
    if (!line || line_len <= 0 || off <= 0) return 0;
    if (off > line_len) off = line_len;
    if (!anth_has_arabic(line, line_len)) {
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
    if (!line || line_len <= 0 || target_x <= 0) return 0;
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

extern int anth_font_width(void *f, void *r, void *p, int n);

static inline int anth_ui_caret_adv(void *f, void *r, const char *line, int line_len, int off) {
    return anth_line_visual_adv(line, line_len, off, f, r, (anth_width_fn)anth_font_width);
}

static inline int anth_ui_click_off(void *f, void *r, const char *line, int line_len, int target_x) {
    return anth_line_click_offset(line, line_len, target_x, f, r, (anth_width_fn)anth_font_width);
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

static inline int anth_vault_find_file(const char *vault, const char *rel, char *out, int max_len) {
    if (!rel || !rel[0] || !out || max_len < 2) return 0;
    if (access(rel, F_OK) == 0) {
        snprintf(out, (size_t)max_len, "%s", rel);
        return 1;
    }
    if (vault && vault[0]) {
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
    }
    return 0;
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
