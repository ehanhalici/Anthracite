#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/bidi_types.sats"
staload "data_text/text_source.sats"
staload "data_text/bidi_mirror.sats"
staload "data_text/unicode_sort.sats"
extern fun mirror_source_exhausted(): int = "mac#anth_die_int"

fun scalar_valid(cp: int): bool =
  ige(cp,0) andalso ilt(cp,1114112) andalso not(ige(cp,55296) andalso ile(cp,57343))

fun row(source: !Buf, output: !Buf, start: int, finish: int, count: int): int = let
  var position: int = start
  val cp = text_hex(source,position,finish)
  val first_end = position
  val separator = text_skip_space(source,position,finish)
  val () = position := text_skip_space(source,iadd(separator,1),finish)
  val paired_start = position
  val mirror = text_hex(source,position,finish)
  val valid = scalar_valid(cp) andalso scalar_valid(mirror)
    andalso igt(first_end,start) andalso igt(position,paired_start)
    andalso ieq(buf_get(source,separator),59)
in if not(valid) then ~1 else let
    val () = buf_set32(output,imul(count,2),cp)
    val () = buf_set32(output,iadd(imul(count,2),1),mirror)
  in iadd(count,1) end end

fun rows {n:nat} .<n>. (n: int(n), source: !Buf, output: !Buf, p: int, count: int): int =
  if ige(p,buf_len(source)) then count else if n = 0 then mirror_source_exhausted() else let
    val finish = text_line_end(source,p,buf_len(source))
    val start = text_skip_space(source,p,finish)
    val comment = ige(start,finish) orelse ieq(buf_get(source,start),35)
    val next = if comment then count else row(source,output,start,finish,count)
  in if ilt(next,0) then ~1 else rows(n-1,source,output,iadd(finish,1),next) end

fun unique_rows {n:nat} .<n>. (n: int(n), output: !Buf, i: int, previous: int): bool =
  if n = 0 then true else let
    val cp = buf_get32(output,imul(i,2))
  in igt(cp,previous) andalso unique_rows(n-1,output,iadd(i,1),cp) end

fun accept(output: Buf, count: int): MirrorLoad =
  if ile(count,0) then let val () = buf_free(output) in MirrorsRejected(MirrorData()) end else let
    val () = unicode_rows_sort(output,count,2,0)
    val valid = unique_rows(airlock_nat(count),output,0,~1)
  in if valid then MirrorsLoaded(BidiMirrors(output,count)) else let
      val () = buf_free(output)
    in MirrorsRejected(MirrorData()) end end

implement bidi_mirrors_parse(source) = let
  val output = buf_make(imul(buf_len(source),8))
  val count = rows(airlock_nat(iadd(buf_len(source),1)),source,output,0,0)
in accept(output,count) end

implement bidi_mirrors_load(path) = case+ text_file_read(path) of
  | ~TextFileError(code) => MirrorsRejected(MirrorIo(code))
  | ~TextFile(source) => let
      val result = bidi_mirrors_parse(source)
      val () = buf_free(source)
    in result end
