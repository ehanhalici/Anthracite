#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/source/text_source.sats"
staload "data_text/unicode/unicode_db.sats"

implement grapheme_class_of(code) =
  case+ code of
  | 1 => GCR() | 2 => GLF() | 3 => GControl() | 4 => GExtend()
  | 5 => GZWJ() | 6 => GRegional() | 7 => GPrepend() | 8 => GSpacing()
  | 9 => GL() | 10 => GV() | 11 => GT() | 12 => GLV() | 13 => GLVT()
  | _ => GOther()

implement conjunct_class_of(code) =
  case+ code of
  | 1 => InConsonant() | 2 => InExtend() | 3 => InLinker() | _ => InNone()

fun ranges_valid {n:nat} .<n>. (
  n: int(n), b: !Buf, at: int, previous: int
): bool =
  if n = 0 then ieq(previous, UNICODE_MAX_SCALAR) else let
    val start = buf_get32(b, at)
    val finish = buf_get32(b, iadd(at, 1))
    val packed = buf_get32(b, iadd(at, 2))
  in
    if ine(start, iadd(previous, 1)) orelse ilt(finish, start) orelse igt(finish, UNICODE_MAX_SCALAR)
      orelse ilt(packed, 0) orelse igt(packed, 127)
      orelse igt(imod(packed, 16), 13) then false
    else ranges_valid(n - 1, b, iadd(at, 3), finish)
  end

fun accept_database(b: Buf): UnicodeLoad = let
  val length = buf_len(b)
  val count = buf_get32(b, 2)
  val header_ok = ige(length, 12) andalso ieq(buf_get32(b, 0), 1096106837)
    andalso ieq(buf_get32(b, 1), 180000) andalso igt(count, 0)
  val size_ok = header_ok andalso ieq(imod(isub(length, 12), 12), 0)
    andalso ieq(count, idiv(isub(length, 12), 12))
  val valid = size_ok andalso ranges_valid(airlock_nat(imax(0, count)), b, 3, ~1)
in
  if valid then UnicodeLoaded(UnicodeDb(b, count))
  else let val () = buf_free(b) in UnicodeDataError() end
end

implement unicode_load(path) =
  case+ text_file_read(path) of
  | ~TextFile(b) => accept_database(b)
  | ~TextFileError(code) => UnicodeDataError()

extern fun lookup_exhausted(): int = "mac#anth_die_int"

fun lookup {fuel:nat} .<fuel>. (
  fuel: int(fuel), b: !Buf, cp: int, lo: int, hi: int
): int =
  if ige(lo, hi) then 0 else if fuel = 0 then lookup_exhausted() else let
    val mid = iadd(lo, idiv(isub(hi, lo), 2))
    val at = iadd(3, imul(mid, 3))
    val start = buf_get32(b, at)
    val finish = buf_get32(b, iadd(at, 1))
  in
    if ilt(cp, start) then lookup(fuel - 1, b, cp, lo, mid)
    else if igt(cp, finish) then lookup(fuel - 1, b, cp, iadd(mid, 1), hi)
    else buf_get32(b, iadd(at, 2))
  end

fun properties(db: !UnicodeDb, cp: int): int = let
  val+ UnicodeDb(b, count) = db
in lookup(airlock_nat(iadd(count, 1)), b, cp, 0, count) end

implement unicode_grapheme(db, cp) = grapheme_class_of(imod(properties(db, cp), 16))
implement unicode_conjunct(db, cp) = conjunct_class_of(imod(idiv(properties(db, cp), 16), 4))
implement unicode_pictographic(db, cp) = ige(properties(db, cp), 64)
implement unicode_dispose(db) = let val+ ~UnicodeDb(b, count) = db in buf_free(b) end
