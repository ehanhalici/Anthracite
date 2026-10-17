#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "os/fs.sats"
staload "data_text/source/text_source.sats"
staload "data_text/utf8/utf8.sats"
staload "data_text/unicode/unicode_db.sats"
staload "data_text/grapheme/grapheme.sats"

extern fun test_exhausted(): int = "mac#anth_die_int"

fun sample(a: int,b: int,c: int,d: int): Buf = let
  val source = buf_make(4)
  val () = buf_set(source,0,a)
  val () = buf_set(source,1,b)
  val () = buf_set(source,2,c)
  val () = buf_set(source,3,d)
in source end

fun expect_scalar(a: int,b: int,c: int,d: int,n: int,cp: int): int = let
  val source = sample(a,b,c,d)
  val step = utf8_step(source,n,0)
  val ok = case+ step.kind of
    | Utf8Scalar() => ieq(step.value,cp) andalso ieq(step.next,n)
    | Utf8Malformed() => false | Utf8End() => false
  val () = buf_free(source)
in if ok then 0 else 1 end

fun expect_invalid(a: int,b: int,c: int,d: int,n: int,consumed: int): int = let
  val source = sample(a,b,c,d)
  val step = utf8_step(source,n,0)
  val ok = case+ step.kind of
    | Utf8Malformed() => ieq(step.next,consumed)
    | Utf8Scalar() => false | Utf8End() => false
  val () = buf_free(source)
in if ok then 0 else 1 end

fun utf8_cases(): int =
  expect_scalar(0,0,0,0,1,0) + expect_scalar(196,176,0,0,2,304)
  + expect_scalar(216,168,0,0,2,1576) + expect_scalar(239,180,190,0,3,64830)
  + expect_scalar(240,159,152,128,4,128512)
  + expect_scalar(244,143,191,191,4,UNICODE_MAX_SCALAR)
  + expect_invalid(192,128,0,0,2,1) + expect_invalid(237,160,128,0,3,1)
  + expect_invalid(244,144,128,128,4,1) + expect_invalid(128,0,0,0,1,1)
  + expect_invalid(240,159,152,0,3,3) + expect_invalid(226,130,65,0,3,2)
  + expect_invalid(224,128,128,0,3,1) + expect_invalid(245,128,128,128,4,1)

fun span_case(): int = let
  val b = sample(226,130,65,0)
  val errors = case+ text_decode(b,4) of
    | ~InvalidTextSpan() => 1
    | ~DecodedText(text) => let
        val ok = ieq(scalar_count(text),3) andalso ieq(scalar_errors(text),1)
          andalso ieq(scalar_value(text,0),UNICODE_REPLACEMENT_SCALAR) andalso ieq(scalar_start(text,0),0)
          andalso ieq(scalar_end(text,0),2) andalso ieq(scalar_start(text,1),2)
          andalso ieq(scalar_value(text,1),65) andalso ieq(scalar_value(text,2),0)
          andalso ieq(scalar_start(text,2),3) andalso ieq(scalar_end(text,2),4)
        val () = scalar_dispose(text)
      in if ok then 0 else 1 end
  val () = buf_free(b)
in errors end

fun fill_long {n:nat} .<n>. (n: int(n), b: !Buf, p: int): void =
  if n = 0 then () else let
    val () = buf_set(b,p,196)
    val () = buf_set(b,iadd(p,1),176)
    val () = buf_set(b,iadd(p,2),216)
    val () = buf_set(b,iadd(p,3),168)
  in fill_long(n-1,b,iadd(p,4)) end

fun long_case(): int = let
  val b = buf_make(WORD16_MODULUS)
  val () = fill_long(16384,b,0)
  val errors = case+ text_decode(b,WORD16_MODULUS) of
    | ~InvalidTextSpan() => 1
    | ~DecodedText(text) => let
        val ok = ieq(scalar_count(text),WORD16_SIGN_BIT) andalso ieq(scalar_errors(text),0)
          andalso ieq(scalar_value(text,32766),304) andalso ieq(scalar_start(text,32766),65532)
          andalso ieq(scalar_value(text,32767),1576) andalso ieq(scalar_end(text,32767),WORD16_MODULUS)
        val () = scalar_dispose(text)
      in if ok then 0 else 1 end
  val () = buf_free(b)
in errors end

fun source_cases(): int = let
  val before = mem_live()
  val errors = iadd(span_case(),long_case())
in iadd(errors,if ieq(before,mem_live()) then 0 else 1) end

typedef conformance_summary = @{errors=int,cases=int}

fun check_sequence {fuel:nat} .<fuel>. (
  fuel: int(fuel), db: !UnicodeDb, source: !Buf, pos: int, en: int,
  state: GraphemeState, errors: int
): int =
  if fuel = 0 then test_exhausted() else let
    val marker = text_skip_space(source,pos,en)
    val expected = ieq(buf_get(source,iadd(marker,1)),183)
    var p: int = text_skip_space(source,iadd(marker,2),en)
  in
    if ige(p,en) orelse ieq(buf_get(source,p),35) then iadd(errors,if expected then 0 else 1)
    else let
      val cp = text_hex(source,p,en)
      val step = grapheme_step(db,state,cp)
      val mismatch = if step.boundary = expected then 0 else 1
    in check_sequence(fuel-1,db,source,p,en,step.state,iadd(errors,mismatch)) end
  end

fun check_line(db: !UnicodeDb, source: !Buf, pos: int, en: int, line: int): int =
  if ige(pos,en) orelse ieq(buf_get(source,pos),35) then 0 else let
    val errors = check_sequence(airlock_nat(iadd(isub(en,pos),1)),db,source,pos,en,grapheme_initial(),0)
    val () = if igt(errors,0) then println!("event=grapheme_mismatch line=",line," count=",errors) else ()
  in errors end

fun check_lines {fuel:nat} .<fuel>. (
  fuel: int(fuel), db: !UnicodeDb, source: !Buf, pos: int, en: int, line: int, summary: conformance_summary
): conformance_summary =
  if ige(pos,en) then summary else if fuel > 0 then let
    val finish = text_line_end(source,pos,en)
    val start = text_skip_space(source,pos,finish)
    val failed = check_line(db,source,start,finish,line)
    val cases = if ilt(start,finish) andalso ine(buf_get(source,start),35) then 1 else 0
    val next = @{errors=iadd(summary.errors,failed),cases=iadd(summary.cases,cases)}
  in check_lines(fuel-1,db,source,iadd(finish,1),en,iadd(line,1),next) end
  else @{errors=test_exhausted(),cases=0}

fun check_file(db: !UnicodeDb, path: string): conformance_summary =
  case+ text_file_read(path) of
  | ~TextFileError(code) => @{errors=1,cases=0}
  | ~TextFile(source) => let
      val n = buf_len(source)
      val summary = check_lines(airlock_nat(n),db,source,0,n,1,@{errors=0,cases=0})
      val () = buf_free(source)
    in summary end

fun run(): int = case+ unicode_load(c_argv(1)) of
  | ~UnicodeDataError() => 1
  | ~UnicodeLoaded(db) => let
      val summary = check_file(db,c_argv(2))
      val () = unicode_dispose(db)
      val malformed = utf8_cases()
      val spans = source_cases()
      val count_error = if ieq(summary.cases,853) then 0 else 1
      val () = println!("event=text_conformance grapheme_cases=",summary.cases,
        " grapheme_errors=",summary.errors," utf8_errors=",malformed," source_errors=",spans)
    in iadd(iadd(summary.errors,malformed),iadd(spans,count_error)) end

implement main0() =
  if ine(c_argc(),3) then exit(2) else if igt(run(),0) then exit(1) else ()
