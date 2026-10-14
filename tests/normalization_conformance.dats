#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "os/fs.sats"
staload "data_text/text_source.sats"
staload "data_text/normalization_types.sats"
staload "normalization_fixture.sats"
staload "data_text/normalization_load.sats"
staload "data_text/normalization_data.sats"
extern fun normalization_test_exhausted(): int = "mac#anth_die_int"
extern fun normalization_part_invalid(): NormalizationTestPart = "mac#anth_die_box"

fun part_of(code: int): NormalizationTestPart = case+ code of
  | 48 => SpecificPart() | 49 => CharacterPart() | 50 => CanonicalPart() | 51 => CompatibilityPart()
  | 52 => ClosurePart() | 53 => CompositePart()
  | _ => normalization_part_invalid()

fun test_case(
  data: !NormalizationData, source: !Buf, mask: !Buf, start: int, finish: int, state: NormalizationTestState
): NormalizationTestState = let
  val before = mem_live()
  val columns = normalization_fixture_columns(source,start,finish)
  val errors = normalization_fixture_test(data,columns)
  val () = normalization_fixture_mark(columns,mask,state.part)
  val () = normalization_fixture_dispose(columns)
  val balanced = ieq(before,mem_live())
  val bad = igt(errors,0) orelse not(balanced)
  val () = if bad andalso ilt(state.scores.errors,8) then
    println!("event=normalization_failure case=",state.scores.cases," source_offset=",start," errors=",errors," balanced=",balanced) else ()
  val scores = @{cases=iadd(state.scores.cases,1),errors=iadd(state.scores.errors,if bad then 1 else 0)}
in @{part=state.part,scores=scores} end

fun process_line(
  data: !NormalizationData, source: !Buf, mask: !Buf, start: int, finish: int, state: NormalizationTestState
): NormalizationTestState =
  if ige(start,finish) orelse ieq(buf_get(source,start),35) then state
  else if ieq(buf_get(source,start),64) then @{part=part_of(buf_get(source,iadd(start,5))),scores=state.scores}
  else test_case(data,source,mask,start,finish,state)

fun lines {n:nat} .<n>. (
  n: int(n), data: !NormalizationData, source: !Buf, mask: !Buf, p: int, state: NormalizationTestState
): NormalizationTestState = if ige(p,buf_len(source)) then state else if n = 0 then let
    val stop = normalization_test_exhausted()
  in state end else let
    val finish = text_line_end(source,p,buf_len(source))
    val start = text_skip_space(source,p,finish)
    val next = process_line(data,source,mask,start,finish,state)
  in lines(n-1,data,source,mask,iadd(finish,1),next) end

fun test_source(data: !NormalizationData, source: !Buf): int = let
  val mask = buf_make(1114112)
  val initial = @{part=SpecificPart(),scores= @{cases=0,errors=0}}
  val state = lines(airlock_nat(iadd(buf_len(source),1)),data,source,mask,0,initial)
  val () = println!("event=normalization_conformance cases=",state.scores.cases," checks=",imul(state.scores.cases,20)," errors=",state.scores.errors)
  val stable_errors = normalization_fixture_stable(data,mask)
  val () = buf_free(mask)
in iadd(stable_errors,iadd(state.scores.errors,if ieq(state.scores.cases,20171) then 0 else 1)) end

fun test_file(data: !NormalizationData): int = case+ text_file_read(c_argv(2)) of
  | ~TextFileError(code) => 1
  | ~TextFile(source) => let
      val errors = test_source(data,source)
      val () = buf_free(source)
    in errors end

fun run(): int = case+ normalization_load(c_argv(1)) of
  | ~NormalizationRejected(error) => let val () = println!("event=normalization_load_failed") in 1 end
  | ~NormalizationLoaded(data) => let
      val errors = test_file(data)
      val () = normalization_dispose(data)
    in errors end

implement main0() = if ine(c_argc(),3) then exit(2) else if igt(run(),0) then exit(1) else ()
