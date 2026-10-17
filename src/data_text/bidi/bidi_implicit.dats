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

extern fun implicit_invalid(): int = "mac#anth_die_int"

fun increment(kind: BidiClass, level: int): int = case+ kind of
  | BL() => imod(level,2)
  | BR() => isub(1,imod(level,2))
  | BEN() => isub(2,imod(level,2))
  | BAN() => isub(2,imod(level,2))
  | BAL() => implicit_invalid() | BES() => implicit_invalid() | BET() => implicit_invalid()
  | BCS() => implicit_invalid() | BB() => implicit_invalid() | BS() => implicit_invalid()
  | BWS() => implicit_invalid() | BON() => implicit_invalid() | BLRE() => implicit_invalid()
  | BLRO() => implicit_invalid() | BRLE() => implicit_invalid() | BRLO() => implicit_invalid()
  | BPDF() => implicit_invalid() | BNSM() => implicit_invalid() | BBN() => implicit_invalid()
  | BFSI() => implicit_invalid() | BLRI() => implicit_invalid() | BRLI() => implicit_invalid()
  | BPDI() => implicit_invalid()

fun resolve {n:nat} .<n>. (n: int(n), work: !BidiWork, seq: !BidiSequence, i: int): void =
  if n = 0 then () else let
    val cp = bidi_sequence_index(seq,i)
    val level = bidi_level(work,cp)
    val next = iadd(level,increment(bidi_current(work,cp),level))
    val () = bidi_set_level(work,cp,next)
  in resolve(n-1,work,seq,iadd(i,1)) end

implement bidi_implicit_levels(work,seq) =
  resolve(airlock_nat(bidi_sequence_count(seq)),work,seq,0)
