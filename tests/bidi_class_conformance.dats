#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/bidi_types.sats"
staload "os/fs.sats"
staload "data_text/text_source.sats"
staload "data_text/bidi_bracket_data.sats"
staload "bidi_fixture.sats"
staload "bidi_class_fixture.sats"
datatype TestLine = LevelLine | OrderLine | DataLine | IgnoredLine
typedef Scores = @{cases=int, errors=int}
typedef TestState = @{expected=BidiExpect, scores=Scores}
extern fun class_conformance_exhausted(): int = "mac#anth_die_int"

fun line_kind_of(source: !Buf, start: int, finish: int): TestLine =
  if ige(start,finish) orelse ieq(buf_get(source,start),35) then IgnoredLine()
  else if ine(buf_get(source,start),64) then DataLine() else let
    val colon = text_find_byte(source,start,finish,58)
  in if text_token_is(source,start,colon,"@Levels") then LevelLine()
    else if text_token_is(source,start,colon,"@Reorder") then OrderLine() else IgnoredLine() end

fun record_failure(scores: Scores, errors: int, before: int, source_offset: int, direction: ParagraphDirection): Scores = let
  val balanced = ieq(before,mem_live())
  val bad = igt(errors,0) orelse not(balanced)
  val () = if bad andalso ilt(scores.errors,8) then
    println!("event=bidi_class_failure case=",scores.cases," source_offset=",source_offset," errors=",errors," balanced=",balanced) else ()
in @{cases=iadd(scores.cases,1),errors=iadd(scores.errors,if bad then 1 else 0)} end

fun test_direction(
  source: !Buf, start: int, finish: int, brackets: !BidiBrackets,
  direction: ParagraphDirection, state: TestState
): TestState = let
  val before = mem_live()
  val errors = bidi_class_test(source,start,finish,brackets,direction,state.expected)
  val scores = record_failure(state.scores,errors,before,start,direction)
in @{expected=state.expected,scores=scores} end

fun test_data(source: !Buf, start: int, finish: int, brackets: !BidiBrackets, state: TestState): TestState = let
  val semicolon = text_find_byte(source,start,finish,59)
  var position: int = text_skip_space(source,iadd(semicolon,1),finish)
  val bitset = text_hex(source,position,finish)
  val auto = if igt(anth_bit(bitset,1),0) then test_direction(source,start,semicolon,brackets,AutoLtr(),state) else state
  val left = if igt(anth_bit(bitset,2),0) then test_direction(source,start,semicolon,brackets,ForceLtr(),auto) else auto
in if igt(anth_bit(bitset,4),0) then test_direction(source,start,semicolon,brackets,ForceRtl(),left) else left end

fun update_expected(state: TestState, kind: TestLine, start: int, finish: int): TestState =
  case+ kind of
  | LevelLine() => @{expected= @{level_start=start,level_end=finish,order_start=state.expected.order_start,order_end=state.expected.order_end},scores=state.scores}
  | OrderLine() => @{expected= @{level_start=state.expected.level_start,level_end=state.expected.level_end,order_start=start,order_end=finish},scores=state.scores}
  | DataLine() => state | IgnoredLine() => state

fun process_line(source: !Buf, start: int, finish: int, brackets: !BidiBrackets, state: TestState): TestState =
  case+ line_kind_of(source,start,finish) of
  | DataLine() => test_data(source,start,finish,brackets,state)
  | IgnoredLine() => state
  | LevelLine() => update_expected(state,LevelLine(),iadd(text_find_byte(source,start,finish,58),1),finish)
  | OrderLine() => update_expected(state,OrderLine(),iadd(text_find_byte(source,start,finish,58),1),finish)

fun lines {n:nat} .<n>. (
  n: int(n), source: !Buf, brackets: !BidiBrackets, p: int, state: TestState
): TestState = if ige(p,buf_len(source)) then state else if n = 0 then let
    val stop = class_conformance_exhausted()
  in state end else let
    val finish = text_line_end(source,p,buf_len(source))
    val start = text_skip_space(source,p,finish)
    val next = process_line(source,start,finish,brackets,state)
  in lines(n-1,source,brackets,iadd(finish,1),next) end

fun test_file(brackets: !BidiBrackets): int = case+ text_file_read(c_argv(2)) of
  | ~TextFileError(code) => 1
  | ~TextFile(source) => let
      val expected = @{level_start=0,level_end=0,order_start=0,order_end=0}
      val state = lines(airlock_nat(iadd(buf_len(source),1)),source,brackets,0,@{expected=expected,scores= @{cases=0,errors=0}})
      val () = buf_free(source)
      val () = println!("event=bidi_class_conformance cases=",state.scores.cases," errors=",state.scores.errors)
    in iadd(state.scores.errors,if ieq(state.scores.cases,770241) then 0 else 1) end

fun run(): int = case+ bidi_brackets_load(c_argv(1)) of
  | ~BracketsRejected(error) => 1
  | ~BracketsLoaded(brackets) => let
      val errors = test_file(brackets)
      val () = bidi_brackets_dispose(brackets)
    in errors end

implement main0() = if ine(c_argc(),3) then exit(2) else if igt(run(),0) then exit(1) else ()
