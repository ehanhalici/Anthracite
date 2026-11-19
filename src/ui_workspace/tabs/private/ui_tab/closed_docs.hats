(* Closed-tab document cache (see ClosedDocs in ui_tab.sats). Pure ATS2: the
   only boundary is the stat call, wrapped by os/file_stamp. *)
macdef CLOSED_DOCS_MAX_ENTRIES = 32
macdef CLOSED_DOCS_BUDGET_BYTES = 268435456
(* Rough resident size of a kept document: text plus rows, analyses, layout. *)
macdef CLOSED_DOC_BYTES_PER_TEXT_BYTE = 16
macdef CLOSED_DOC_TEXT_LIMIT_BYTES = 16777216

fun closed_stamp(path: !Buf): Option_vt(FileStamp) = file_stamp(buf_cstr(path))
fun same_stamp(a: FileStamp, b: FileStamp): bool = file_stamp_equal(a, b)

fun closed_disabled(): bool = let val v = c_getenv("ANTHRACITE_TAB_CACHE")
in igt(c_strlen(v), 0) andalso ieq(c_str_byte(v, 0), CHAR_ZERO) end

implement closed_docs_free(kept) = case+ kept of
  | ~ClosedNone() => ()
  | ~ClosedKept(path, stamp, bytes, doc, rest) => let
      val () = buf_free(path) val () = doc_free(doc) in closed_docs_free(rest) end

fun closed_count{n:nat} .<n>. (left: int(n), kept: !ClosedDocs): int =
  if left = 0 then 0 else case+ kept of
  | ClosedNone() => 0 | ClosedKept(path, stamp, bytes, doc, rest) => iadd(1, closed_count(left - 1, rest))
implement closed_docs_count(kept) = closed_count(airlock_nat(iadd(CLOSED_DOCS_MAX_ENTRIES, 1)), kept)

fun closed_drop_all(kept: ClosedDocs): ClosedDocs = let val () = closed_docs_free(kept) in ClosedNone() end
(* Keeps the first entries while both limits hold; frees the rest. *)
fun closed_trim{n:nat} .<n>. (left: int(n), kept: ClosedDocs, count: int, used: int): ClosedDocs =
  if left = 0 then closed_drop_all(kept) else case+ kept of
  | ~ClosedNone() => ClosedNone()
  | ~ClosedKept(path, stamp, bytes, doc, rest) =>
    if ige(count, CLOSED_DOCS_MAX_ENTRIES) orelse igt(iadd(used, bytes), CLOSED_DOCS_BUDGET_BYTES)
    then let val () = buf_free(path) val () = doc_free(doc) in closed_drop_all(rest) end
    else ClosedKept(path, stamp, bytes, doc, closed_trim(left - 1, rest, iadd(count, 1), iadd(used, bytes)))

(* Removes the entry for `path`; returns its document when the file is unchanged. *)
fun closed_take{n:nat} .<n>. (left: int(n), kept: &ClosedDocs >> _, path: !Buf, now: FileStamp): Option_vt(Doc) =
  if left = 0 then None_vt() else case+ kept of
  | ClosedNone() => None_vt()
  | @ClosedKept(p, stamp, bytes, doc, rest) =>
    if buffer_equal_from(p, path, 0) then let
      val same = same_stamp(stamp, now)
      val found = doc val tail = rest val () = buf_free(p) val () = free@(kept) val () = kept := tail
    in if same then Some_vt(found) else let val () = doc_free(found) in None_vt() end end
    else let val result = closed_take(left - 1, rest, path, now) prval () = fold@(kept) in result end

fun closed_keep(doc: Doc, path: !Buf, kept: &ClosedDocs >> _): void =
  case+ closed_stamp(path) of
  | ~None_vt() => doc_free(doc)
  | ~Some_vt(stamp) => let
      val bytes = imul(imin(doc_len(doc), CLOSED_DOC_TEXT_LIMIT_BYTES), CLOSED_DOC_BYTES_PER_TEXT_BYTE)
      val stale = closed_take(airlock_nat(iadd(CLOSED_DOCS_MAX_ENTRIES, 1)), kept, path, stamp)
      val () = case+ stale of | ~None_vt() => () | ~Some_vt(old) => doc_free(old)
      val () = kept := ClosedKept(buffer_clone(path), stamp, bytes, doc, kept)
    in kept := closed_trim(airlock_nat(iadd(CLOSED_DOCS_MAX_ENTRIES, 1)), kept, 0, 0) end

(* Tab closing as in drop_head: save first; a failed save keeps the tab. *)
fun drop_head_kept(doc: Doc, path: Buf, title: Buf, sc: int, rest: Tabs, kept: &ClosedDocs >> _): Tabs =
  if save_ok(doc, path) then let
    val () = if is_image_path(path) orelse closed_disabled() then doc_free(doc) else closed_keep(doc, path, kept)
    val () = buf_free(path) val () = buf_free(title) val () = seen_int(sc)
  in rest end
  else TCons(doc, path, title, sc, rest)

fun drop_kept{n:nat} .<n>. (left: int(n), ts: Tabs, i: int, kept: &ClosedDocs >> _): Tabs =
  if left = 0 then ts else case+ ts of
  | ~TNil() => TNil()
  | ~TCons(doc, path, title, sc, rest) =>
    if ieq(i, 0) then drop_head_kept(doc, path, title, sc, rest, kept)
    else TCons(doc, path, title, sc, drop_kept(left - 1, rest, isub(i, 1), kept))
implement tabs_drop_kept(ts, i, kept) = drop_kept(airlock_nat(iadd(imax(0, i), 1)), ts, i, kept)

fun kept_document(path: !Buf, kept: &ClosedDocs >> _): Option_vt(Doc) =
  case+ closed_stamp(path) of
  | ~None_vt() => None_vt()
  | ~Some_vt(now) => closed_take(airlock_nat(iadd(CLOSED_DOCS_MAX_ENTRIES, 1)), kept, path, now)
implement tabs_open_kept(ts, path, kept) =
  if is_image_path(path) orelse closed_disabled() then tabs_open(ts, path)
  else case+ kept_document(path, kept) of
  | ~Some_vt(doc) => open_loaded(ts, doc, path)
  | ~None_vt() => tabs_open(ts, path)
