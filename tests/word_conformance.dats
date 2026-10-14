#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "os/fs.sats"
staload "data_text/text_source.sats"
staload "data_text/utf8.sats"
staload "data_text/unicode_db.sats"
staload "data_text/unicode_property.sats"
staload "data_text/word_types.sats"

typedef test_summary = @{cases=int,errors=int}
extern fun test_exhausted(): int = "mac#anth_die_int"

fun parse_sequence {fuel:nat} .<fuel>. (
  fuel: int(fuel), source: !Buf, pos: int, en: int, cps: !Buf,
  starts: !Buf, ends: !Buf, expected: !Buf, count: int
): int =
  if fuel = 0 then test_exhausted() else let
    val p = text_skip_space(source,pos,en)
    val marker = buf_get(source,iadd(p,1))
    val valid = ieq(buf_get(source,p),195) andalso (ieq(marker,183) orelse ieq(marker,151))
    val () = buf_set(expected,count,if ieq(marker,183) then 1 else 0)
    var next: int = text_skip_space(source,iadd(p,2),en)
    val token_start = next
  in if not(valid) then ~1 else if ige(next,en) orelse ieq(buf_get(source,next),35) then count else let
      val cp = text_hex(source,next,en)
      val () = buf_set32(cps,count,cp)
      val () = buf_set32(starts,count,token_start)
      val () = buf_set32(ends,count,next)
    in parse_sequence(fuel-1,source,next,en,cps,starts,ends,expected,iadd(count,1)) end end

fun differences {n:nat} .<n>. (n: int(n), actual: !Buf, expected: !Buf, i: int, errors: int): int =
  if n = 0 then errors else differences(n-1,actual,expected,iadd(i,1),
    iadd(errors,if ieq(buf_get(actual,i),buf_get(expected,i)) then 0 else 1))

fun check_result(map: !PropertyMap(1), db: !UnicodeDb, cps: Buf, starts: Buf, ends: Buf, expected: !Buf, n: int): int =
  if ilt(n,0) then let val () = buf_free(cps) val () = buf_free(starts) val () = buf_free(ends) in 1 end
  else let
    val text = ScalarText(cps,starts,ends,n,0)
    val actual = word_boundaries(map,db,text)
    val errors = differences(airlock_nat(iadd(n,1)),actual,expected,0,0)
    val () = buf_free(actual)
    val () = scalar_dispose(text)
  in errors end

fun check_line(map: !PropertyMap(1), db: !UnicodeDb, source: !Buf, pos: int, en: int): int = let
  val capacity = iadd(isub(en,pos),1)
  val cps = buf_make(imul(capacity,4))
  val starts = buf_make(imul(capacity,4))
  val ends = buf_make(imul(capacity,4))
  val expected = buf_make(capacity)
  val count = parse_sequence(airlock_nat(capacity),source,pos,en,cps,starts,ends,expected,0)
  val errors = check_result(map,db,cps,starts,ends,expected,count)
  val () = buf_free(expected)
in errors end

fun report_mismatch(line: int, errors: int): void =
  if igt(errors,0) then println!("event=word_mismatch line=",line," errors=",errors) else ()

fun check_lines {fuel:nat} .<fuel>. (
  fuel: int(fuel), map: !PropertyMap(1), db: !UnicodeDb, source: !Buf,
  pos: int, en: int, line: int, summary: test_summary
): test_summary =
  if ige(pos,en) then summary else if fuel = 0 then @{cases=0,errors=test_exhausted()} else let
    val finish = text_line_end(source,pos,en)
    val p = text_skip_space(source,pos,finish)
    val valid_case = ilt(p,finish) andalso ine(buf_get(source,p),35)
    val errors: int = if valid_case then check_line(map,db,source,p,finish) else 0
    val () = report_mismatch(line,errors)
    val next = @{cases=iadd(summary.cases,if valid_case then 1 else 0),errors=iadd(summary.errors,errors)}
  in check_lines(fuel-1,map,db,source,iadd(finish,1),en,iadd(line,1),next) end

fun check_file(map: !PropertyMap(1), db: !UnicodeDb, path: string): test_summary =
  case+ text_file_read(path) of
  | ~TextFileError(code) => @{cases=0,errors=1}
  | ~TextFile(source) => let
      val n = buf_len(source)
      val summary = check_lines(airlock_nat(n),map,db,source,0,n,1,@{cases=0,errors=0})
      val () = buf_free(source)
    in summary end

fun with_graphemes(map: !PropertyMap(1)): int = case+ unicode_load(c_argv(2)) of
  | ~UnicodeDataError() => 1
  | ~UnicodeLoaded(db) => let
      val summary = check_file(map,db,c_argv(3))
      val () = unicode_dispose(db)
      val () = println!("event=word_conformance cases=",summary.cases," errors=",summary.errors)
    in iadd(summary.errors,if ieq(summary.cases,1944) then 0 else 1) end

fun run(): int = case+ property_load(c_argv(1),WordProperty()) of
  | ~PropertyRejected(error) => 1
  | ~PropertyLoaded(map) => let val errors = with_graphemes(map) val () = property_dispose(map) in errors end

implement main0() = if ine(c_argc(),4) then exit(2) else if igt(run(),0) then exit(1) else ()
