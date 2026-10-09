#ifndef ANTH_GL_CATS
#define ANTH_GL_CATS

#define GL_GLEXT_PROTOTYPES 1
#include <GL/gl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static const char *anth_vs_src =
  "#version 330 core\n"
  "layout(location=0) in vec2 a_pos;\n"
  "layout(location=1) in vec4 a_col;\n"
  "layout(location=2) in vec2 a_uv;\n"
  "uniform vec2 u_view;\n"
  "out vec4 v_col;\n"
  "out vec2 v_uv;\n"
  "void main() {\n"
  "  float x = a_pos.x / u_view.x * 2.0 - 1.0;\n"
  "  float y = 1.0 - a_pos.y / u_view.y * 2.0;\n"
  "  gl_Position = vec4(x, y, 0.0, 1.0);\n"
  "  v_col = a_col;\n"
  "  v_uv = a_uv;\n"
  "}\n";

static const char *anth_fs_src =
  "#version 330 core\n"
  "in vec4 v_col;\n"
  "in vec2 v_uv;\n"
  "uniform sampler2D u_tex;\n"
  "uniform int u_mode;\n"
  "out vec4 frag;\n"
  "void main() {\n"
  "  if (u_mode == 1) {\n"
  "    float a = texture(u_tex, v_uv).r;\n"
  "    frag = vec4(v_col.rgb, v_col.a * a);\n"
  "  } else if (u_mode == 2) {\n"
  "    frag = v_col * texture(u_tex, v_uv);\n"
  "  } else {\n"
  "    frag = v_col;\n"
  "  }\n"
  "}\n";

static const char *anth_blur_fs_src =
  "#version 330 core\n"
  "in vec4 v_col;\n"
  "in vec2 v_uv;\n"
  "uniform sampler2D u_tex;\n"
  "uniform vec2 u_pixel;\n"
  "out vec4 frag;\n"
  "void main() {\n"
  "  vec4 sum = vec4(0.0);\n"
  "  for (int y = -4; y <= 4; ++y) {\n"
  "    for (int x = -4; x <= 4; ++x) {\n"
  "      sum += texture(u_tex, v_uv + vec2(x, y) * u_pixel);\n"
  "    }\n"
  "  }\n"
  "  frag = v_col * (sum / 81.0);\n"
  "}\n";

static unsigned anth_compile(GLenum type, const char *src) {
  GLuint s = glCreateShader(type);
  glShaderSource(s, 1, &src, 0);
  glCompileShader(s);
  GLint ok = 0;
  glGetShaderiv(s, GL_COMPILE_STATUS, &ok);
  if (!ok) {
    char log[1024];
    glGetShaderInfoLog(s, 1024, 0, log);
    fprintf(stderr, "event=shader_compile status=failed log=\"%s\"\n", log);
  }
  return s;
}

static inline unsigned anth_link_program(const char *fragment_src) {
  GLuint vs = anth_compile(GL_VERTEX_SHADER, anth_vs_src);
  GLuint fs = anth_compile(GL_FRAGMENT_SHADER, fragment_src);
  GLuint p = glCreateProgram();
  glAttachShader(p, vs);
  glAttachShader(p, fs);
  glLinkProgram(p);
  GLint ok = 0;
  glGetProgramiv(p, GL_LINK_STATUS, &ok);
  if (!ok) {
    char log[1024];
    glGetProgramInfoLog(p, 1024, 0, log);
    fprintf(stderr, "event=program_link status=failed log=\"%s\"\n", log);
  }
  glDeleteShader(vs);
  glDeleteShader(fs);
  return p;
}

static inline unsigned anth_make_program(void) {
  return anth_link_program(anth_fs_src);
}

static inline unsigned anth_make_blur_program(void) {
  return anth_link_program(anth_blur_fs_src);
}

static inline int anth_uloc(unsigned prog, const char *name) {
  return glGetUniformLocation(prog, name);
}

static inline void anth_attrib(unsigned index, int size, int stride, int off) {
  glVertexAttribPointer(index, size, GL_FLOAT, GL_FALSE, stride, (void *)(intptr_t)off);
}

static inline float anth_rf(unsigned c) { return ((c >> 24) & 255) / 255.f; }
static inline float anth_gf(unsigned c) { return ((c >> 16) & 255) / 255.f; }
static inline float anth_bf(unsigned c) { return ((c >> 8) & 255) / 255.f; }
static inline float anth_af(unsigned c) { return (c & 255) / 255.f; }

static inline unsigned col_rgba(int r, int g, int b, int a) {
  return (((unsigned)(r & 255) << 24) |
          ((unsigned)(g & 255) << 16) |
          ((unsigned)(b & 255) << 8) |
          (unsigned)(a & 255));
}

static inline unsigned col_bg(void) { return 0x141516FFu; }
static inline unsigned col_bar(void) { return 0x1E2024FFu; }
static inline unsigned col_side(void) { return 0x18191CFFu; }
static inline unsigned col_text(void) { return 0xE6E1D8FFu; }
static inline unsigned col_white(void) { return 0xFFFFFFFFu; }
static inline unsigned col_muted(void) { return 0x8E8A84FFu; }
static inline unsigned col_accent(void) { return 0xC4B8A5FFu; }
static inline unsigned col_heading(void) { return 0xF4F1EAFFu; }
static inline unsigned col_link(void) { return 0x58A6FFFFu; }
static inline unsigned col_code(void) { return 0xD7C4A3FFu; }
static inline unsigned col_codebg(void) { return 0x24262BFFu; }
static inline unsigned col_quote(void) { return 0xA8B39CFFu; }
static inline unsigned col_tag(void) { return 0xD7A36AFFu; }
static inline unsigned col_highbg(void) { return 0x4A4332FFu; }
static inline unsigned col_hightxt(void) { return 0xF0E6C8FFu; }
static inline unsigned col_math(void) { return 0xC9B6D9FFu; }
static inline unsigned col_caret(void) { return 0xF2EDE4FFu; }
static inline unsigned col_sel(void) { return 0x3A4A5CFFu; }
static inline unsigned col_line(void) { return 0x2C2E33FFu; }
static inline unsigned col_task(void) { return 0x9BB8A0FFu; }
static inline unsigned col_fm(void) { return 0x6E6A64FFu; }
static inline unsigned col_menu(void) { return 0x2A2C31FFu; }
static inline unsigned col_danger(void) { return 0xC47A6AFFu; }
static inline unsigned col_overlay(void) { return 0x0A0C10D8u; }

/* GNU Unifont 17.0.04, SIL Open Font License 1.1 and GPLv2+ with the font exception.
   Packed from the upstream BDF; glyphs are not redrawn here. */
typedef struct {
  uint32_t cp;
  uint8_t w, h, adv, pad;
  uint8_t bits[32];
} anth_uf;

static anth_uf *anth_uf_tab;
static int anth_uf_n;

static void anth_uf_load(void) {
  static int tried;
  const char *path;
  FILE *f;
  char magic[4];
  uint32_t ver = 0, n = 0;
  anth_uf *tab;
  if (tried) return;
  tried = 1;
#ifndef ANTHRACITE_UNIFONT
#define ANTHRACITE_UNIFONT "src/data_font/unifont.bin"
#endif
  path = ANTHRACITE_UNIFONT;
  f = fopen(path, "rb");
  if (!f) f = fopen("src/data_font/unifont.bin", "rb");
  if (!f) return;
  if (fread(magic, 1, 4, f) != 4 || memcmp(magic, "UFNT", 4) != 0) { fclose(f); return; }
  if (fread(&ver, 4, 1, f) != 1 || fread(&n, 4, 1, f) != 1 || ver != 1 || n > 200000) {
    fclose(f);
    return;
  }
  tab = (anth_uf *)calloc(n ? n : 1, sizeof(anth_uf));
  if (!tab) { fclose(f); return; }
  if (fread(tab, sizeof(anth_uf), n, f) != n) {
    free(tab);
    fclose(f);
    return;
  }
  fclose(f);
  anth_uf_tab = tab;
  anth_uf_n = (int)n;
}

static anth_uf *anth_uf_find(int cp) {
  int lo, hi;
  anth_uf_load();
  if (!anth_uf_tab || cp < 0) return 0;
  lo = 0;
  hi = anth_uf_n;
  while (lo < hi) {
    int mid = lo + (hi - lo) / 2;
    uint32_t c = anth_uf_tab[mid].cp;
    if (c == (uint32_t)cp) return &anth_uf_tab[mid];
    if (c < (uint32_t)cp) lo = mid + 1;
    else hi = mid;
  }
  return 0;
}

static inline int uf_wide(int cp) {
  anth_uf *g = anth_uf_find(cp);
  return g ? (int)g->w : 0;
}

static inline int uf_byte(int cp, int row, int colb) {
  anth_uf *g = anth_uf_find(cp);
  int i;
  if (!g || row < 0 || row >= (int)g->h || colb < 0 || colb > 1) return 0;
  i = row * 2 + colb;
  if (i < 0 || i >= 32) return 0;
  return g->bits[i];
}

#endif
