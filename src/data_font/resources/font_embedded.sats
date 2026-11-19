staload "data_text/source/text_source.sats"

(* Faces linked into the executable. A face is addressed by its reference
   "embedded:<name>" wherever a font path is accepted, so worker threads reload
   it through the same loaders as a file. Indexes follow the case-insensitive
   name order fixed at build time. *)
fun embedded_font_count(): int
fun embedded_font_ref(index: int): string
fun embedded_font_name(index: int): string
fun embedded_font_default_ref(): string
fun embedded_font_is_ref(path: string): bool
fun embedded_font_find(face_ref: string): int
(* Copies the face image into an owned buffer. *)
fun embedded_font_read(face_ref: string): TextFileResult
