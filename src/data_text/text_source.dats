#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "os/fs.sats"
staload "data_text/text_source.sats"

fun read_owned(fd: int, size: int): TextFileResult = let
  val b = buf_make(size)
  val count = fs_read_buf(fd, b, size)
  val () = fs_close(fd)
in
  if ieq(count, size) then let val () = buf_set_len(b, size) in TextFile(b) end
  else let val () = buf_free(b) in TextFileError(count) end
end

implement text_file_read(path) = let
  val size = fs_size(path)
  val fd = if ige(size, 0) then fs_open_read(path) else ~1
in
  if ilt(fd, 0) then TextFileError(fd) else read_owned(fd, size)
end

fun find_byte {n:nat} .<n>. (n: int(n), b: !Buf, p: int, ch: int): int =
  if n = 0 then p else if ieq(buf_get(b, p), ch) then p
  else find_byte(n - 1, b, iadd(p, 1), ch)

implement text_find_byte(b, p, endpos, value) =
  find_byte(airlock_nat(imax(0, isub(endpos, p))), b, p, value)

implement text_line_end(b, p, endpos) = text_find_byte(b, p, endpos, 10)

fun skip_space {n:nat} .<n>. (n: int(n), b: !Buf, p: int): int =
  if n = 0 then p else let val c = buf_get(b, p) in
    if ieq(c, 32) orelse ieq(c, 9) orelse ieq(c, 13)
    then skip_space(n - 1, b, iadd(p, 1)) else p
  end

implement text_skip_space(b, p, endpos) =
  skip_space(airlock_nat(imax(0, isub(endpos, p))), b, p)

fun hex_digit(c: int): int =
  if ige(c, 48) andalso ile(c, 57) then isub(c, 48)
  else if ige(c, 65) andalso ile(c, 70) then isub(c, 55)
  else if ige(c, 97) andalso ile(c, 102) then isub(c, 87) else ~1

fun read_hex {n:nat} .<n>. (n: int(n), b: !Buf, p: &int >> _, value: int): int =
  if n = 0 then value else let val digit = hex_digit(buf_get(b, p)) in
    if ilt(digit, 0) then value
    else if igt(value, 134217727) then ~1
    else let val () = p := iadd(p, 1) in
      read_hex(n - 1, b, p, iadd(imul(value, 16), digit))
    end
  end

implement text_hex(b, p, endpos) =
  read_hex(airlock_nat(imax(0, isub(endpos, p))), b, p, 0)

fun token_matches {n:nat} .<n>. (
  n: int(n), b: !Buf, p: int, token: string, at: int
): bool =
  if n = 0 then true
  else if ine(buf_get(b, p), c_str_byte(token, at)) then false
  else token_matches(n - 1, b, iadd(p, 1), token, iadd(at, 1))

fun token_delimiter(c: int): bool =
  ieq(c, 32) orelse ieq(c, 9) orelse ieq(c, 13) orelse ieq(c, 35) orelse ieq(c, 59)

implement text_token_is(b, start, endpos, token) = let
  val size = c_strlen(token)
  val finish = iadd(start, size)
in
  if igt(finish, endpos) then false
  else if ilt(finish, endpos) andalso not(token_delimiter(buf_get(b, finish))) then false
  else token_matches(airlock_nat(size), b, start, token, 0)
end
