#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "os/fs.sats"
staload "data_text/bidi/bidi_types.sats"
staload "data_text/utf8/utf8.sats"
staload "data_text/source/text_source.sats"
staload "data_text/unicode/unicode_property.sats"
staload "data_text/bidi/bidi_bracket_data.sats"
staload "data_text/bidi/bidi_resolution.sats"
staload "data_text/bidi/bidi_line.sats"
staload "text/bidi/bidi_fixture.sats"
typedef Scores = @{cases=int, errors=int}
extern fun conformance_exhausted(): int = "mac#anth_die_int"

fun check_case(source: !Buf, start: int, finish: int, map: !PropertyMap(2), brackets: !BidiBrackets): int = let
  val fields = bidi_fixture_fields(source,start,finish)
  val text = bidi_fixture_text(source,start,isub(fields.direction,1))
  val work = bidi_make(map,text)
  var position: int = fields.direction
  val direction = bidi_direction_of(bidi_fixture_decimal(source,position,finish))
  val base = bidi_resolve(work,text,brackets,direction)
  val () = position := fields.base
  val expected = bidi_fixture_decimal(source,position,finish)
  val () = bidi_line_reset(work,0,bidi_count(work),base)
  val order = bidi_line_order(work,0,bidi_count(work))
  val base_error: int = if ieq(base,expected) then 0 else 1
  val level_errors = bidi_fixture_check_levels(source,fields.levels,isub(fields.order,1),work)
  val order_errors = bidi_fixture_check_order(source,fields.order,finish,order)
  val errors = iadd(base_error,iadd(level_errors,order_errors))
  val () = bidi_order_dispose(order)
  val () = bidi_dispose(work)
  val () = scalar_dispose(text)
in errors end

fun run_case(source: !Buf, start: int, finish: int, map: !PropertyMap(2), brackets: !BidiBrackets, scores: Scores): Scores = let
  val before = mem_live()
  val errors = check_case(source,start,finish,map,brackets)
  val balanced = ieq(before,mem_live())
  val bad = igt(errors,0) orelse not(balanced)
  val () = if bad andalso ilt(scores.errors,8) then
    println!("event=bidi_character_failure case=",scores.cases," source_offset=",start," errors=",errors," balanced=",balanced) else ()
in @{cases=iadd(scores.cases,1),errors=iadd(scores.errors,if bad then 1 else 0)} end

fun lines {n:nat} .<n>. (
  n: int(n), source: !Buf, map: !PropertyMap(2), brackets: !BidiBrackets, p: int, scores: Scores
): Scores = if ige(p,buf_len(source)) then scores else if n = 0 then let
    val stop = conformance_exhausted()
  in scores end else let
    val finish = text_line_end(source,p,buf_len(source))
    val start = text_skip_space(source,p,finish)
    val comment = ige(start,finish) orelse ieq(buf_get(source,start),35)
    val next = if comment then scores else run_case(source,start,finish,map,brackets,scores)
  in lines(n-1,source,map,brackets,iadd(finish,1),next) end

fun test_file(map: !PropertyMap(2), brackets: !BidiBrackets): int = case+ text_file_read(c_argv(3)) of
  | ~TextFileError(code) => 1
  | ~TextFile(source) => let
      val scores = lines(airlock_nat(iadd(buf_len(source),1)),source,map,brackets,0,@{cases=0,errors=0})
      val () = buf_free(source)
      val () = println!("event=bidi_character_conformance cases=",scores.cases," errors=",scores.errors)
    in iadd(scores.errors,if ieq(scores.cases,91707) then 0 else 1) end

fun test_brackets(map: !PropertyMap(2)): int = case+ bidi_brackets_load(c_argv(2)) of
  | ~BracketsRejected(error) => 1
  | ~BracketsLoaded(brackets) => let
      val errors = test_file(map,brackets)
      val () = bidi_brackets_dispose(brackets)
    in errors end

fun run(): int = case+ property_load(c_argv(1),BidiProperty()) of
  | ~PropertyRejected(error) => 1
  | ~PropertyLoaded(map) => let
      val errors = test_brackets(map)
      val () = property_dispose(map)
    in errors end

implement main0() = if ine(c_argc(),4) then exit(2) else if igt(run(),0) then exit(1) else ()
