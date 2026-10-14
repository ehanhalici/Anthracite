#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/bidi_types.sats"
staload "data_text/bidi_runs.sats"
staload "data_text/bidi_sequence.sats"
staload "data_text/bidi_predicates.sats"
extern fun sequence_exhausted(): int = "mac#anth_die_int"

fun sequence_size {n:nat} .<n>. (n: int(n), runs: !BidiRuns, run: int, total: int): int =
  if n = 0 then sequence_exhausted() else if ilt(run,0) then sequence_exhausted() else let
    val size = isub(bidi_run_end(runs,run),bidi_run_start(runs,run))
    val next = bidi_run_next(runs,run)
    val count = iadd(total,size)
  in if ilt(next,0) then count else sequence_size(n-1,runs,next,count) end

fun copy_run {n:nat} .<n>. (
  n: int(n), runs: !BidiRuns, output: !Buf, at: int, offset: int
): void = if n = 0 then () else let
  val () = buf_set32(output,offset,bidi_run_active(runs,at))
in copy_run(n-1,runs,output,iadd(at,1),iadd(offset,1)) end

fun append_runs {n:nat} .<n>. (
  n: int(n), runs: !BidiRuns, output: !Buf, run: int, count: &int >> _
): int = if ilt(run,0) then sequence_exhausted() else if n = 0 then sequence_exhausted() else let
  val start = bidi_run_start(runs,run)
  val size = isub(bidi_run_end(runs,run),start)
  val () = copy_run(airlock_nat(size),runs,output,start,count)
  val () = count := iadd(count,size)
  val next = bidi_run_next(runs,run)
in if ilt(next,0) then run else append_runs(n-1,runs,output,next,count) end

implement bidi_runs_sequence(runs,work,root,capacity) = let
  val size = sequence_size(airlock_nat(iadd(capacity,1)),runs,root,0)
  val indices = buf_make(imul(size,4))
  var count: int = 0
  val last = append_runs(airlock_nat(iadd(capacity,1)),runs,indices,root,count)
  val sos = bidi_level_direction(bidi_run_before(runs,root))
  val eos = bidi_level_direction(bidi_run_after(runs,last))
  val level = bidi_run_level(runs,root)
in BidiSequence(indices,count,sos,eos,level) end
