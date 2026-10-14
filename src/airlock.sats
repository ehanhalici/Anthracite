(* Airlock: the single trusted boundary where dynamic integers enter the
   statically indexed core. The declared type is the proof obligation;
   airlock.cats checks the value at run time so the claim holds whenever the
   program continues. Keep this file the only place that crosses the boundary. *)

%{#
#include "airlock.cats"
%}

fun airlock_nat(n: int): [m:nat] int(m) = "mac#anth_airlock_nat"
fun airlock_pos(n: int): [m:pos] int(m) = "mac#anth_airlock_pos"
fun airlock_below {n:nat} (i: int, cap: int(n)): [k:nat | k < n] int(k) = "mac#anth_airlock_below"
fun airlock_word {n:nat} (i: int, cap: int(n)): [k:nat | 4*k+4 <= n] int(k) = "mac#anth_airlock_word"

(* Span bridge: the remaining step count of a bounded loop, hi - lo.
   Callers must guard lo < hi (or lo <= hi) before the call; the run-time
   check in airlock.cats enforces order and representability in signed int. *)
fun airlock_span(lo: int, hi: int): [r:nat] int(r) = "mac#anth_airlock_span"
(* Postiats 0.4.2 declares llint -> int but omits its C implementation.
   Only numeric representation crosses here; overflow policy stays in ATS. *)
fun airlock_i32(value: llint): int = "mac#anth_airlock_i32"

(* Recursion fuel. Every self-recursive function spends one unit per call.
   2^28 covers any input this program can hold; running out aborts the
   process (anth_airlock_die_any) instead of returning a made-up value. *)
macdef MAX_REC_FUEL = 268435456
