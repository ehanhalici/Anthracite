#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"

%{^
#include <string.h>
#include "anthracite_embedded_fonts.h"
static inline int anth_embedded_font_total(void) { return ANTHRACITE_EMBEDDED_FONT_COUNT; }
static inline const char *anth_embedded_font_ref_at(int i) { return anth_embedded_fonts[i].ref; }
static inline const char *anth_embedded_font_name_at(int i) { return anth_embedded_fonts[i].name; }
static inline const void *anth_embedded_font_begin_at(int i) { return anth_embedded_fonts[i].begin; }
static inline int anth_embedded_font_bytes_at(int i) {
  return (int)(anth_embedded_fonts[i].end - anth_embedded_fonts[i].begin);
}
static inline const char *anth_embedded_font_default(void) { return ANTHRACITE_EMBEDDED_DEFAULT_FONT; }
static inline int anth_embedded_font_has_prefix(const char *path) {
  return strncmp(path, ANTHRACITE_EMBEDDED_FONT_PREFIX, sizeof(ANTHRACITE_EMBEDDED_FONT_PREFIX) - 1) == 0;
}
%}

staload "mem.sats"
staload "airlock.sats"
staload "os/fs.sats"
staload "data_text/source/text_source.sats"
staload "data_font/resources/font_embedded.sats"

extern fun total_c(): int = "mac#anth_embedded_font_total"
extern fun ref_at_c(index: int): string = "mac#anth_embedded_font_ref_at"
extern fun name_at_c(index: int): string = "mac#anth_embedded_font_name_at"
extern fun begin_at_c(index: int): ptr = "mac#anth_embedded_font_begin_at"
extern fun bytes_at_c(index: int): int = "mac#anth_embedded_font_bytes_at"
extern fun default_c(): string = "mac#anth_embedded_font_default"
extern fun has_prefix_c(path: string): bool = "mac#anth_embedded_font_has_prefix"

implement embedded_font_count() = total_c()
implement embedded_font_ref(index) = ref_at_c(index)
implement embedded_font_name(index) = name_at_c(index)
implement embedded_font_default_ref() = default_c()
implement embedded_font_is_ref(path) = has_prefix_c(path)

fun find_from {n:nat} .<n>. (rem: int(n), face_ref: string, index: int): int =
  if rem = 0 then ~1
  else if ieq(c_strcmp(ref_at_c(index), face_ref), 0) then index
  else find_from(rem - 1, face_ref, iadd(index, 1))

implement embedded_font_find(face_ref) = find_from(airlock_nat(total_c()), face_ref, 0)

fun copy_face(index: int): TextFileResult = let
  val size = bytes_at_c(index)
  var image = buf_make(size)
  val () = buf_append(image, begin_at_c(index), size)
in TextFile(image) end

implement embedded_font_read(face_ref) = let
  val index = embedded_font_find(face_ref)
in
  if ilt(index, 0) then TextFileError(index) else copy_face(index)
end
