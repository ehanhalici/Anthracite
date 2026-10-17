#include "core_render/gl.cats"

int main(int argc, char **argv) {
  if (argc != 2 || (strcmp(argv[1], "0") && strcmp(argv[1], "1"))) return 2;
  int expected = strcmp(argv[1], "1") == 0;
  int width = uf_wide('A');
  int loaded = anth_uf_tab != NULL && anth_uf_n > 0 && width > 0;
  int missing = anth_uf_tab == NULL && anth_uf_n == 0 && width == 0;
  int ok = expected ? loaded : missing;
  printf("event=unifont_path_contracts expected=%d loaded=%d ok=%d\n", expected, loaded, ok);
  free(anth_uf_tab);
  anth_uf_tab = NULL;
  anth_uf_n = 0;
  return ok ? 0 : 1;
}
