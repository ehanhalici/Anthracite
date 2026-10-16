#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_text/bidi/bidi_types.sats"
staload "data_text/bidi/bidi_sequence.sats"
staload "data_text/bidi/bidi_predicates.sats"
staload "data_text/bidi/bidi_resolution.sats"
staload "data_text/utf8/utf8.sats"
staload "data_text/bidi/bidi_status.sats"
staload "data_text/bidi/bidi_runs.sats"
staload "data_text/bidi/bidi_weak.sats"
staload "data_text/bidi/bidi_bracket_pairs.sats"
staload "data_text/bidi/bidi_bracket_data.sats"

fun resolve_sequence(work: !BidiWork, text: !ScalarText, brackets: !BidiBrackets, seq: !BidiSequence): void = let
  val () = bidi_weak_marks(work,seq)
  val () = bidi_weak_numbers(work,seq)
  val () = bidi_weak_latin(work,seq)
  val () = bidi_resolve_brackets(brackets,text,work,seq)
  val () = bidi_resolve_neutrals(work,seq)
in bidi_implicit_levels(work,seq) end

fun resolve_root(work: !BidiWork, text: !ScalarText, brackets: !BidiBrackets, runs: !BidiRuns, i: int): void =
  if bidi_run_incoming(runs,i) then () else let
    val seq = bidi_runs_sequence(runs,work,i,bidi_count(work))
    val () = resolve_sequence(work,text,brackets,seq)
  in bidi_sequence_dispose(seq) end

fun roots {n:nat} .<n>. (
  n: int(n), work: !BidiWork, text: !ScalarText, brackets: !BidiBrackets, runs: !BidiRuns, i: int
): void = if n = 0 then () else let
  val () = resolve_root(work,text,brackets,runs,i)
in roots(n-1,work,text,brackets,runs,iadd(i,1)) end

fun resolve_runs(work: !BidiWork, text: !ScalarText, brackets: !BidiBrackets, base: int): void = let
  val runs = bidi_runs_make(bidi_count(work))
  val counts = bidi_runs_build(runs,work)
  val () = bidi_runs_link(runs,work,counts,base)
  val () = roots(airlock_nat(counts.runs),work,text,brackets,runs,0)
in bidi_runs_dispose(runs) end

implement bidi_resolve(work,text,brackets,direction) = let
  val () = bidi_match_isolates(work)
  val base = bidi_paragraph_level(work,direction)
  val () = bidi_explicit_levels(work,base)
  val () = resolve_runs(work,text,brackets,base)
in base end
