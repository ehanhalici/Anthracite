#ifndef ANTH_TEXT_LAYOUT_H
#define ANTH_TEXT_LAYOUT_H

#include <stdint.h>
#include <stddef.h>
#include <string.h>
#include <stdlib.h>
#include "ucd_data.cats"

/* --- 1. UTF-8 Validation and Decoding --- */

static inline int anth_utf8_decode_safe(const char *s, int len, int *idx) {
    int i = *idx;
    if (i >= len || i < 0) return 0;
    unsigned char b0 = (unsigned char)s[i];

    if (b0 < 0x80) {
        *idx = i + 1;
        return b0;
    }
    /* 2-byte: 0xC2..0xDF */
    if (b0 >= 0xC2 && b0 <= 0xDF) {
        if (i + 1 < len) {
            unsigned char b1 = (unsigned char)s[i + 1];
            if ((b1 & 0xC0) == 0x80) {
                *idx = i + 2;
                return ((b0 & 0x1F) << 6) | (b1 & 0x3F);
            }
        }
        *idx = i + 1;
        return 0xFFFD;
    }
    /* 3-byte: 0xE0..0xEF */
    if (b0 >= 0xE0 && b0 <= 0xEF) {
        if (i + 2 < len) {
            unsigned char b1 = (unsigned char)s[i + 1];
            unsigned char b2 = (unsigned char)s[i + 2];
            if ((b1 & 0xC0) == 0x80 && (b2 & 0xC0) == 0x80) {
                /* check overlong and surrogate */
                if ((b0 == 0xE0 && b1 < 0xA0) || (b0 == 0xED && b1 >= 0xA0)) {
                    *idx = i + 1;
                    return 0xFFFD;
                }
                *idx = i + 3;
                return ((b0 & 0x0F) << 12) | ((b1 & 0x3F) << 6) | (b2 & 0x3F);
            }
        }
        *idx = i + 1;
        return 0xFFFD;
    }
    /* 4-byte: 0xF0..0xF4 */
    if (b0 >= 0xF0 && b0 <= 0xF4) {
        if (i + 3 < len) {
            unsigned char b1 = (unsigned char)s[i + 1];
            unsigned char b2 = (unsigned char)s[i + 2];
            unsigned char b3 = (unsigned char)s[i + 3];
            if ((b1 & 0xC0) == 0x80 && (b2 & 0xC0) == 0x80 && (b3 & 0xC0) == 0x80) {
                /* check overlong and range > 0x10FFFF */
                if ((b0 == 0xF0 && b1 < 0x90) || (b0 == 0xF4 && b1 >= 0x90)) {
                    *idx = i + 1;
                    return 0xFFFD;
                }
                *idx = i + 4;
                return ((b0 & 0x07) << 18) | ((b1 & 0x3F) << 12) | ((b2 & 0x3F) << 6) | (b3 & 0x3F);
            }
        }
        *idx = i + 1;
        return 0xFFFD;
    }

    *idx = i + 1;
    return 0xFFFD;
}

static inline int anth_utf8_encode(int cp, char *dst, int max_len, int pos) {
    if (pos >= max_len) return pos;
    if (cp < 0x80) {
        if (pos + 1 > max_len) return pos;
        dst[pos++] = (char)cp;
    } else if (cp < 0x800) {
        if (pos + 2 > max_len) return pos;
        dst[pos++] = (char)(0xC0 | (cp >> 6));
        dst[pos++] = (char)(0x80 | (cp & 0x3F));
    } else if (cp < 0x10000) {
        if (pos + 3 > max_len) return pos;
        dst[pos++] = (char)(0xE0 | (cp >> 12));
        dst[pos++] = (char)(0x80 | ((cp >> 6) & 0x3F));
        dst[pos++] = (char)(0x80 | (cp & 0x3F));
    } else {
        if (pos + 4 > max_len) return pos;
        dst[pos++] = (char)(0xF0 | (cp >> 18));
        dst[pos++] = (char)(0x80 | ((cp >> 12) & 0x3F));
        dst[pos++] = (char)(0x80 | ((cp >> 6) & 0x3F));
        dst[pos++] = (char)(0x80 | (cp & 0x3F));
    }
    return pos;
}

static inline int anth_utf8_prev_boundary(const char *s, int pos) {
    if (pos <= 0) return 0;
    pos--;
    while (pos > 0 && ((unsigned char)s[pos] & 0xC0) == 0x80) {
        pos--;
    }
    return pos;
}

static inline int anth_utf8_next_boundary(const char *s, int len, int pos) {
    if (pos >= len) return len;
    int idx = pos;
    anth_utf8_decode_safe(s, len, &idx);
    return idx;
}

/* --- 2. UAX#9 Bidi Paragraph Direction --- */

static inline int anth_bidi_line_direction(const char *s, int len) {
    if (!s || len <= 0) return 0; /* LTR default */
    int idx = 0;
    while (idx < len) {
        int cp = anth_utf8_decode_safe(s, len, &idx);
        int cls = anth_bidi_class(cp);
        if (cls == ANTH_BIDI_L) return 0; /* LTR */
        if (cls == ANTH_BIDI_R || cls == ANTH_BIDI_AL) return 1; /* RTL */
    }
    return 0; /* LTR default */
}

/* --- 3. Arabic Identification --- */

static inline int anth_is_arabic_cp(int cp) {
    return ((cp >= 0x0600 && cp <= 0x06FF) ||
            (cp >= 0x0750 && cp <= 0x077F) ||
            (cp >= 0x08A0 && cp <= 0x08FF) ||
            (cp >= 0xFB50 && cp <= 0xFDFF) ||
            (cp >= 0xFE70 && cp <= 0xFEFF));
}

static inline int anth_has_arabic_text(const char *p, int n) {
    if (!p || n <= 0) return 0;
    int idx = 0;
    while (idx < n) {
        int cp = anth_utf8_decode_safe(p, n, &idx);
        if (anth_is_arabic_cp(cp)) return 1;
    }
    return 0;
}

/* --- 4. Arabic Shaping with Source Mapping --- */

typedef struct {
    int visual_cp;
    int src_byte_start;
    int src_byte_end;
} anth_shaped_glyph;

static inline int anth_arabic_shape_word(
    const int *in_cps, const int *in_byte_starts, const int *in_byte_ends,
    int n, anth_shaped_glyph *out_glyphs, int max_out
) {
    int out_cnt = 0;
    int i = 0;
    while (i < n && out_cnt < max_out) {
        int cp = in_cps[i];
        if (anth_is_ar_transparent(cp)) {
            out_glyphs[out_cnt].visual_cp = cp;
            out_glyphs[out_cnt].src_byte_start = in_byte_starts[i];
            out_glyphs[out_cnt].src_byte_end = in_byte_ends[i];
            out_cnt++;
            i++;
            continue;
        }

        /* Check Lam-Alif Ligatures */
        if (cp == 0x0644 && i + 1 < n) {
            int nxt = in_cps[i + 1];
            int iso_la = 0, fin_la = 0;
            if (nxt == 0x0622) { iso_la = 0xFEF5; fin_la = 0xFEF6; }
            else if (nxt == 0x0623) { iso_la = 0xFEF7; fin_la = 0xFEF8; }
            else if (nxt == 0x0625) { iso_la = 0xFEF9; fin_la = 0xFEFA; }
            else if (nxt == 0x0627) { iso_la = 0xFEFB; fin_la = 0xFEFC; }

            if (iso_la) {
                int prev_join = 0;
                int p = i - 1;
                while (p >= 0 && anth_is_ar_transparent(in_cps[p])) p--;
                if (p >= 0) {
                    const anth_ar_entry *pe = anth_get_ar_entry(in_cps[p]);
                    if (pe && pe->grp == 2) prev_join = 1;
                }
                out_glyphs[out_cnt].visual_cp = prev_join ? fin_la : iso_la;
                out_glyphs[out_cnt].src_byte_start = in_byte_starts[i];
                out_glyphs[out_cnt].src_byte_end = in_byte_ends[i + 1];
                out_cnt++;
                i += 2;
                continue;
            }
        }

        const anth_ar_entry *e = anth_get_ar_entry(cp);
        if (!e || e->iso == 0) {
            out_glyphs[out_cnt].visual_cp = cp;
            out_glyphs[out_cnt].src_byte_start = in_byte_starts[i];
            out_glyphs[out_cnt].src_byte_end = in_byte_ends[i];
            out_cnt++;
            i++;
            continue;
        }

        int prev_join = 0;
        int p = i - 1;
        while (p >= 0 && anth_is_ar_transparent(in_cps[p])) p--;
        if (p >= 0) {
            const anth_ar_entry *pe = anth_get_ar_entry(in_cps[p]);
            if (pe && pe->grp == 2) prev_join = 1;
        }

        int next_join = 0;
        int nx = i + 1;
        while (nx < n && anth_is_ar_transparent(in_cps[nx])) nx++;
        if (nx < n) {
            const anth_ar_entry *ne = anth_get_ar_entry(in_cps[nx]);
            if (ne && (ne->grp == 1 || ne->grp == 2)) next_join = 1;
        }

        int shaped = e->iso;
        if (e->grp == 2) {
            if (prev_join && next_join) shaped = e->med ? e->med : e->iso;
            else if (prev_join) shaped = e->fin ? e->fin : e->iso;
            else if (next_join) shaped = e->ini ? e->ini : e->iso;
        } else if (e->grp == 1) {
            if (prev_join) shaped = e->fin ? e->fin : e->iso;
        }

        out_glyphs[out_cnt].visual_cp = shaped;
        out_glyphs[out_cnt].src_byte_start = in_byte_starts[i];
        out_glyphs[out_cnt].src_byte_end = in_byte_ends[i];
        out_cnt++;
        i++;
    }
    return out_cnt;
}

/* --- 5. Visual Cluster Layout --- */

typedef struct {
    int src_byte_start;
    int src_byte_end;
    int visual_x;
    int visual_w;
    int is_rtl;
} anth_cluster;

typedef int (*anth_width_fn)(void *f, void *r, const char *p, int n);

#define ANTH_MAX_CLUSTERS 2048

static inline int anth_layout_build_clusters(
    const char *line, int line_len,
    void *f, void *r, anth_width_fn wfn,
    anth_cluster *out_clusters, int max_clusters
) {
    if (!line || line_len <= 0) return 0;
    int cluster_cnt = 0;
    int pen_x = 0;

    int pos = 0;
    while (pos < line_len && cluster_cnt < max_clusters) {
        int idx = pos;
        int cp = anth_utf8_decode_safe(line, line_len, &idx);
        int is_ar = anth_is_arabic_cp(cp);

        int run_st = pos;
        int run_en = idx;

        while (run_en < line_len) {
            int nxt_idx = run_en;
            int nxt_cp = anth_utf8_decode_safe(line, line_len, &nxt_idx);
            int nxt_is_ar = anth_is_arabic_cp(nxt_cp);
            if (nxt_is_ar != is_ar) {
                if (nxt_cp == ' ' && is_ar) {
                    int look = nxt_idx;
                    int lcp = anth_utf8_decode_safe(line, line_len, &look);
                    if (anth_is_arabic_cp(lcp)) {
                        run_en = nxt_idx;
                        continue;
                    }
                }
                break;
            }
            run_en = nxt_idx;
        }

        if (!is_ar) {
            /* LTR segment: character by character */
            int p = run_st;
            while (p < run_en && cluster_cnt < max_clusters) {
                int next_p = p;
                anth_utf8_decode_safe(line, line_len, &next_p);
                int clen = next_p - p;
                int cw = wfn(f, r, line + p, clen);
                out_clusters[cluster_cnt].src_byte_start = p;
                out_clusters[cluster_cnt].src_byte_end = next_p;
                out_clusters[cluster_cnt].visual_x = pen_x;
                out_clusters[cluster_cnt].visual_w = cw;
                out_clusters[cluster_cnt].is_rtl = 0;
                cluster_cnt++;
                pen_x += cw;
                p = next_p;
            }
        } else {
            /* Arabic segment: shape words and order right-to-left */
            int in_cps[ANTH_MAX_CLUSTERS];
            int in_starts[ANTH_MAX_CLUSTERS];
            int in_ends[ANTH_MAX_CLUSTERS];
            int n_cps = 0;
            int p = run_st;
            while (p < run_en && n_cps < ANTH_MAX_CLUSTERS - 4) {
                int st = p;
                int c = anth_utf8_decode_safe(line, line_len, &p);
                in_cps[n_cps] = c;
                in_starts[n_cps] = st;
                in_ends[n_cps] = p;
                n_cps++;
            }

            anth_shaped_glyph shaped[ANTH_MAX_CLUSTERS];
            int sn = anth_arabic_shape_word(in_cps, in_starts, in_ends, n_cps, shaped, ANTH_MAX_CLUSTERS);

            int glyph_widths[ANTH_MAX_CLUSTERS];
            int seg_total_w = 0;
            for (int k = 0; k < sn; k++) {
                char buf[8];
                int blen = anth_utf8_encode(shaped[k].visual_cp, buf, sizeof(buf), 0);
                int gw = wfn(f, r, buf, blen);
                glyph_widths[k] = gw;
                seg_total_w += gw;
            }

            /* Display visual glyphs in reverse order (RTL) */
            int cur_gx = pen_x;
            for (int k = sn - 1; k >= 0 && cluster_cnt < max_clusters; k--) {
                out_clusters[cluster_cnt].src_byte_start = shaped[k].src_byte_start;
                out_clusters[cluster_cnt].src_byte_end = shaped[k].src_byte_end;
                out_clusters[cluster_cnt].visual_x = cur_gx;
                out_clusters[cluster_cnt].visual_w = glyph_widths[k];
                out_clusters[cluster_cnt].is_rtl = 1;
                cluster_cnt++;
                cur_gx += glyph_widths[k];
            }
            pen_x += seg_total_w;
        }

        pos = run_en;
    }

    return cluster_cnt;
}

/* --- 6. Unified Operations (Visual Advance, Selection Span, Click Offset) --- */

static inline int anth_layout_visual_adv(
    const char *line, int line_len, int off,
    void *f, void *r, anth_width_fn wfn
) {
    if (!line || line_len <= 0) return 0;
    if (off < 0) off = 0;
    if (off > line_len) off = line_len;

    anth_cluster clusters[ANTH_MAX_CLUSTERS];
    int n = anth_layout_build_clusters(line, line_len, f, r, wfn, clusters, ANTH_MAX_CLUSTERS);
    if (n <= 0) return 0;

    int total_w = clusters[n - 1].visual_x + clusters[n - 1].visual_w;
    int is_para_rtl = anth_bidi_line_direction(line, line_len);

    if (off == 0) {
        return is_para_rtl ? total_w : 0;
    }
    if (off == line_len) {
        return is_para_rtl ? 0 : total_w;
    }

    /* Find cluster */
    for (int i = 0; i < n; i++) {
        if (off >= clusters[i].src_byte_start && off <= clusters[i].src_byte_end) {
            if (clusters[i].is_rtl) {
                if (off == clusters[i].src_byte_start) {
                    return clusters[i].visual_x + clusters[i].visual_w;
                }
                return clusters[i].visual_x;
            } else {
                if (off == clusters[i].src_byte_end) {
                    return clusters[i].visual_x + clusters[i].visual_w;
                }
                return clusters[i].visual_x;
            }
        }
    }

    /* Fallback */
    return is_para_rtl ? total_w : 0;
}

static inline void anth_layout_sel_span(
    const char *line, int line_len, int sa, int sb, int at_eol,
    void *f, void *r, anth_width_fn wfn,
    int *out_sx, int *out_sw
) {
    if (!line || line_len <= 0 || sa >= sb) {
        *out_sx = 0;
        *out_sw = 4;
        return;
    }

    anth_cluster clusters[ANTH_MAX_CLUSTERS];
    int n = anth_layout_build_clusters(line, line_len, f, r, wfn, clusters, ANTH_MAX_CLUSTERS);
    if (n <= 0) {
        *out_sx = 0;
        *out_sw = 4;
        return;
    }

    int is_para_rtl = anth_bidi_line_direction(line, line_len);
    int min_x = 1000000;
    int max_x = -1000000;

    for (int i = 0; i < n; i++) {
        if (clusters[i].src_byte_end > sa && clusters[i].src_byte_start < sb) {
            int gx1 = clusters[i].visual_x;
            int gx2 = clusters[i].visual_x + clusters[i].visual_w;
            if (gx1 < min_x) min_x = gx1;
            if (gx2 > max_x) max_x = gx2;
        }
    }

    if (min_x > max_x) {
        int x = anth_layout_visual_adv(line, line_len, sa, f, r, wfn);
        min_x = x;
        max_x = x;
    }

    if (at_eol) {
        int sp_w = wfn(f, r, " ", 1);
        if (sp_w <= 0) sp_w = 8;
        if (is_para_rtl) {
            min_x -= sp_w;
        } else {
            max_x += sp_w;
        }
    }

    int sw = max_x - min_x;
    if (sw < 4) sw = 4;
    *out_sx = min_x;
    *out_sw = sw;
}

static inline int anth_layout_click_offset(
    const char *line, int line_len, int target_x,
    void *f, void *r, anth_width_fn wfn
) {
    if (!line || line_len <= 0) return 0;
    anth_cluster clusters[ANTH_MAX_CLUSTERS];
    int n = anth_layout_build_clusters(line, line_len, f, r, wfn, clusters, ANTH_MAX_CLUSTERS);
    if (n <= 0) return 0;

    int total_w = clusters[n - 1].visual_x + clusters[n - 1].visual_w;
    int is_para_rtl = anth_bidi_line_direction(line, line_len);

    if (target_x <= 0) {
        return is_para_rtl ? line_len : 0;
    }
    if (target_x >= total_w) {
        return is_para_rtl ? 0 : line_len;
    }

    int best_pos = 0;
    int min_diff = 1000000;

    for (int i = 0; i < n; i++) {
        int gx = clusters[i].visual_x;
        int gw = clusters[i].visual_w;
        int mid = gx + gw / 2;

        int diff = abs(target_x - (gx + gw / 2));
        if (diff < min_diff) {
            min_diff = diff;
            if (clusters[i].is_rtl) {
                best_pos = (target_x >= mid) ? clusters[i].src_byte_start : clusters[i].src_byte_end;
            } else {
                best_pos = (target_x <= mid) ? clusters[i].src_byte_start : clusters[i].src_byte_end;
            }
        }
    }

    return best_pos;
}

#endif /* ANTH_TEXT_LAYOUT_H */
