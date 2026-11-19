#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
(* Initial allocation policy; capacities are measured in bytes. *)
macdef LIST_EMBEDDED_PATH_INITIAL_BYTES = 1024
macdef LOAD_FONTCONFIG_DEFAULT_BUFFER_INITIAL_BYTES = 512
macdef META_RECORD_BYTES = 16
macdef META_RECORD_WORDS = 4

staload "mem.sats"
staload "airlock.sats"
staload "flag.sats"
staload "os/fs.sats"
staload "core_render/gl.sats"
staload "core_render/render.sats"
staload "data_font/resources/font.sats"
staload "data_font/resources/font_embedded.sats"
staload "data_font/sfnt/sfnt.sats"
staload "data_font/glyph/core/glyph_component.sats"
staload "data_text/source/text_source.sats"

(* Embedded face listing and default selection. *)
staload "data_font/resources/private/font_catalog.sats"

fun buf_append_str(b: &Buf >> _, s: string): void =
  buf_append(b, c_str_ptr(s), c_strlen(s))

(* Record i of meta: path offset, path bytes, name offset, name bytes. *)
fun meta_put(meta: &Buf >> _, idx: int, poff: int, plen: int, noff: int, nlen: int): void = let
  val () = buf_ensure(meta, imul(iadd(idx, 1), META_RECORD_BYTES))
  val base = imul(idx, META_RECORD_WORDS)
  val () = buf_set32(meta, base, poff)
  val () = buf_set32(meta, iadd(base, 1), plen)
  val () = buf_set32(meta, iadd(base, 2), noff)
  val () = buf_set32(meta, iadd(base, 3), nlen)
in
end

fun list_one(index: int, paths: &Buf >> _, names: &Buf >> _, meta: &Buf >> _): void = let
  val face_ref = embedded_font_ref(index)
  val name = embedded_font_name(index)
  val poff = buf_len(paths)
  val noff = buf_len(names)
  val () = buf_append_str(paths, face_ref)
  val () = buf_append_str(names, name)
in
  meta_put(meta, index, poff, c_strlen(face_ref), noff, c_strlen(name))
end

fun list_from {n:nat} .<n>. (rem: int(n), index: int, paths: &Buf >> _, names: &Buf >> _, meta: &Buf >> _): void =
  if rem = 0 then ()
  else let
    val () = list_one(index, paths, names, meta)
  in
    list_from(rem - 1, iadd(index, 1), paths, names, meta)
  end

implement font_list_embedded(paths, names, meta, cnt) = let
  val () = buf_set_len(paths, 0)
  val () = buf_set_len(names, 0)
  val () = buf_set_len(meta, 0)
  val total = embedded_font_count()
  val () = list_from(airlock_nat(total), 0, paths, names, meta)
in
  cnt := total
end

fun load_embedded_from {n:nat} .<n>. (rem: int(n), f: !Font, index: int): bool =
  if rem = 0 then false
  else if font_use_file(f, embedded_font_ref(index)) then true
  else load_embedded_from(rem - 1, f, iadd(index, 1))

(* The build-time default face first, then any other embedded face. *)
fun load_embedded_default(f: !Font): bool =
  font_use_file(f, embedded_font_default_ref())
  orelse load_embedded_from(airlock_nat(embedded_font_count()), f, 0)

(* System default font via fontconfig: the last resort when no face is embedded. *)
fun load_fontconfig_default(f: !Font): bool = let
  var b = buf_make(LOAD_FONTCONFIG_DEFAULT_BUFFER_INITIAL_BYTES)
  val n = c_fc_font_buf(b, 511)
  val s = buf_cstr(b)
  val hit = ieq(n, 1) andalso igt(c_strlen(s), 0) andalso font_use_file(f, s)
  val () = buf_free(b)
in
  hit
end

implement load_default(f) = let
  val env = c_getenv("ANTHRACITE_FONT")
  val env_prim = c_getenv("ANTHRACITE_PRIMARY_FONT")
in
  if igt(c_strlen(env), 0) andalso font_use_file(f, env) then true
  else if igt(c_strlen(env_prim), 0) andalso font_use_file(f, env_prim) then true
  else load_embedded_default(f) orelse load_fontconfig_default(f)
end

implement font_load_default(f) = load_default(f)
