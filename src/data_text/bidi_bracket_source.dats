#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/bidi_types.sats"
staload "data_text/text_source.sats"
staload "data_text/bidi_bracket_data.sats"

extern fun bracket_source_exhausted(): int = "mac#anth_die_int"

fun kind_at(source: !Buf, p: int): int = case+ buf_get(source,p) of
  | 111 => 1 | 99 => 2 | _ => ~1

fun scalar_valid(cp: int): bool =
  ige(cp,0) andalso ilt(cp,1114112) andalso not(ige(cp,55296) andalso ile(cp,57343))

typedef ParsedRow = @{cp=int, paired=int, kind=int, valid=bool}

fun parse_row(source: !Buf, p: int, en: int): ParsedRow = let
  var next: int = p
  val cp = text_hex(source,next,en)
  val first_end = next
  val sep1 = text_skip_space(source,next,en)
  val () = next := text_skip_space(source,iadd(sep1,1),en)
  val paired_start = next
  val paired = text_hex(source,next,en)
  val paired_end = next
  val sep2 = text_skip_space(source,next,en)
  val kind = kind_at(source,text_skip_space(source,iadd(sep2,1),en))
  val valid = ieq(buf_get(source,sep1),59) andalso ieq(buf_get(source,sep2),59)
    andalso igt(first_end,p) andalso igt(paired_end,paired_start)
    andalso scalar_valid(cp) andalso scalar_valid(paired) andalso igt(kind,0)
in @{cp=cp,paired=paired,kind=kind,valid=valid} end

fun row(source: !Buf, rows: !Buf, p: int, en: int, count: int): int = let
  val parsed = parse_row(source,p,en)
  val previous = if ieq(count,0) then ~1 else buf_get32(rows,imul(isub(count,1),3))
in if not(parsed.valid) orelse ile(parsed.cp,previous) then ~1 else let
    val at = imul(count,3)
    val () = buf_set32(rows,at,parsed.cp)
    val () = buf_set32(rows,iadd(at,1),parsed.paired)
    val () = buf_set32(rows,iadd(at,2),parsed.kind)
  in iadd(count,1) end end

fun rows {n:nat} .<n>. (n: int(n), source: !Buf, output: !Buf, p: int, count: int): int =
  if ige(p,buf_len(source)) then count else if n = 0 then bracket_source_exhausted() else let
    val finish = text_line_end(source,p,buf_len(source))
    val start = text_skip_space(source,p,finish)
    val comment = ige(start,finish) orelse ieq(buf_get(source,start),35)
    val next = if comment then count else row(source,output,start,finish,count)
  in if ilt(next,0) then ~1 else rows(n-1,source,output,iadd(finish,1),next) end

fun pair_valid(data: !BidiBrackets, cp: int): bool = let
  val first = bidi_bracket_info(data,cp)
  val second = bidi_bracket_info(data,first.paired)
in ieq(second.paired,cp) andalso
  (bidi_bracket_is_open(first.kind) andalso bidi_bracket_is_close(second.kind)
    orelse bidi_bracket_is_close(first.kind) andalso bidi_bracket_is_open(second.kind)) end

fun pairs_valid {n:nat} .<n>. (n: int(n), data: !BidiBrackets, i: int): bool =
  if n = 0 then true else let
    val+ BidiBrackets(output,count) = data
    val cp = buf_get32(output,imul(i,3))
  in pair_valid(data,cp) andalso pairs_valid(n-1,data,iadd(i,1)) end

fun accept(output: Buf, count: int): BracketLoad =
  if ile(count,0) then let val () = buf_free(output) in BracketsRejected(BracketData()) end
  else let
    val data = BidiBrackets(output,count)
    val valid = pairs_valid(airlock_nat(count),data,0)
  in if valid then BracketsLoaded(data) else let
      val () = bidi_brackets_dispose(data)
    in BracketsRejected(BracketData()) end end

implement bidi_brackets_parse(source) = let
  val output = buf_make(imul(buf_len(source),12))
  val count = rows(airlock_nat(iadd(buf_len(source),1)),source,output,0,0)
in accept(output,count) end

implement bidi_brackets_load(path) = case+ text_file_read(path) of
  | ~TextFileError(code) => BracketsRejected(BracketIo(code))
  | ~TextFile(source) => let
      val result = bidi_brackets_parse(source)
      val () = buf_free(source)
    in result end
