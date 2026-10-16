#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/bidi/bidi_types.sats"
staload "data_text/bidi/bidi_runs.sats"

fun new_run(runs: !BidiRuns, count: int, at: int, level: int): int = let
  val () = bidi_run_set_start(runs,count,at)
  val () = bidi_run_set_next(runs,count,~1)
  val () = bidi_run_set_level(runs,count,level)
in iadd(count,1) end

fun add_active(runs: !BidiRuns, work: !BidiWork, cp: int, counts: RunCounts): RunCounts = let
  val level = bidi_level(work,cp)
  val previous = isub(counts.runs,1)
  val different = ieq(counts.runs,0) orelse ine(bidi_run_level(runs,previous),level)
  val total = if different then new_run(runs,counts.runs,counts.active,level) else counts.runs
  val run = isub(total,1)
  val () = bidi_run_set_active(runs,counts.active,cp)
  val () = bidi_run_set_map(runs,cp,run)
  val () = bidi_run_set_end(runs,run,iadd(counts.active,1))
in @{active=iadd(counts.active,1),runs=total} end

fun build {n:nat} .<n>. (n: int(n), runs: !BidiRuns, work: !BidiWork, cp: int, counts: RunCounts): RunCounts =
  if n = 0 then counts else let
    val () = bidi_run_set_map(runs,cp,~1)
    val next = if bidi_class_is_removed(bidi_original(work,cp)) then counts else add_active(runs,work,cp,counts)
  in build(n-1,runs,work,iadd(cp,1),next) end

implement bidi_runs_build(runs,work) =
  build(airlock_nat(bidi_count(work)),runs,work,0,@{active=0,runs=0})
