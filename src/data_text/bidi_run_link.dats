#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/bidi_types.sats"
staload "data_text/bidi_runs.sats"

fun adjacent_level(runs: !BidiRuns, work: !BidiWork, at: int, counts: RunCounts, base: int): int =
  if ilt(at,0) orelse ige(at,counts.active) then base
  else bidi_level(work,bidi_run_active(runs,at))

fun save_boundaries(runs: !BidiRuns, work: !BidiWork, i: int, counts: RunCounts, base: int): void = let
  val start = bidi_run_start(runs,i)
  val finish = bidi_run_end(runs,i)
  val level = bidi_run_level(runs,i)
  val last = bidi_run_active(runs,isub(finish,1))
  val before = adjacent_level(runs,work,isub(start,1),counts,base)
  val after = if bidi_class_is_isolate(bidi_original(work,last)) then base
    else adjacent_level(runs,work,finish,counts,base)
  val () = bidi_run_set_before(runs,i,imax(level,before))
in bidi_run_set_after(runs,i,imax(level,after)) end

fun link_isolate(runs: !BidiRuns, work: !BidiWork, run: int): void = let
  val cp = bidi_run_active(runs,isub(bidi_run_end(runs,run),1))
  val matching = bidi_match(work,cp)
in if not(bidi_class_is_isolate(bidi_original(work,cp))) orelse ilt(matching,0) then ()
  else let val next = bidi_run_map(runs,matching) in
    if ieq(next,run) then () else let
      val () = bidi_run_set_next(runs,run,next)
    in bidi_run_set_incoming(runs,next) end end end

fun link_all {n:nat} .<n>. (
  n: int(n), runs: !BidiRuns, work: !BidiWork, i: int, counts: RunCounts, base: int
): void = if n = 0 then () else let
  val () = save_boundaries(runs,work,i,counts,base)
  val () = link_isolate(runs,work,i)
in link_all(n-1,runs,work,iadd(i,1),counts,base) end

implement bidi_runs_link(runs,work,counts,base) =
  link_all(airlock_nat(counts.runs),runs,work,0,counts,base)

