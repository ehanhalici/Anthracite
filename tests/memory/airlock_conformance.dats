#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "airlock.sats"
staload "os/fs.sats"

datatype BoundaryTest = ValidSpans | OverflowSpan | OverflowNarrow | UnderflowNarrow | InvalidArguments

fun mode_of(): BoundaryTest =
  if ieq(c_argc(),1) then ValidSpans()
  else if ieq(c_argc(),2) andalso ieq(c_strcmp(c_argv(1),"--overflow"),0) then OverflowSpan()
  else if ieq(c_argc(),2) andalso ieq(c_strcmp(c_argv(1),"--narrow-overflow"),0) then OverflowNarrow()
  else if ieq(c_argc(),2) andalso ieq(c_strcmp(c_argv(1),"--narrow-underflow"),0) then UnderflowNarrow()
  else InvalidArguments()

fun valid_spans(): int = let
  val empty = airlock_span(0,0)
  val maximum = airlock_span(0,SIGNED_INT_MAX_VALUE)
  val mixed = airlock_span(~10,10)
  val negative = airlock_span(isub(~SIGNED_INT_MAX_VALUE,1),~1)
  val maximum32=airlock_i32(2147483647LL) and minimum32=airlock_i32(~2147483648LL)
  val ok = ieq(empty,0) andalso ieq(maximum,SIGNED_INT_MAX_VALUE)
    andalso ieq(mixed,20) andalso ieq(negative,SIGNED_INT_MAX_VALUE)
    andalso ieq(maximum32,SIGNED_INT_MAX_VALUE) andalso ieq(minimum32,isub(~SIGNED_INT_MAX_VALUE,1))
in if ok then 0 else 1 end

fun overflow_span(): int = let
  val forbidden = airlock_span(isub(~SIGNED_INT_MAX_VALUE,1),0)
in if ige(forbidden,0) then 1 else 1 end

implement main0() = case+ mode_of() of
  | InvalidArguments() => exit(2)
  | ValidSpans() => if igt(valid_spans(),0) then exit(1) else ()
  | OverflowSpan() => exit(overflow_span())
  | OverflowNarrow() => exit(airlock_i32(2147483648LL))
  | UnderflowNarrow() => exit(airlock_i32(~2147483649LL))
