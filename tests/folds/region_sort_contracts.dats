#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"
staload "airlock.sats"
staload "data_ast/folding/fold_region.sats"
#include "data_ast/folding/private/fold_region/regions_radix_sort.hats"

macdef TERNARY_CASE_COUNT = 6561 (* Every eight-owner sequence over {-1,0,1}. *)
macdef SIGNED_OWNER_MAX = 2147483647
macdef SIGNED_OWNER_MIN = ~2147483647 - 1

fun owner_fixture(index: int, count: int, code: int): int =
  if ieq(code, ~2) then (if ieq(imod(index, 2), 0) then SIGNED_OWNER_MAX else SIGNED_OWNER_MIN)
  else if ilt(code, 0) then isub(count, index) else isub(imod(code, 3), 1)

fun fill{n:nat} .<n>. (left: int(n), b: !Buf, index: int, count: int, code: int): void =
  if left > 0 then let
    val base = imul(index, FR_ENTRY_WORDS)
    val owner = owner_fixture(index, count, code)
    val () = buf_set32(b, iadd(base, FR_OWNER), owner)
    val () = buf_set32(b, iadd(base, FR_END), iadd(index, 1))
    val () = buf_set32(b, iadd(base, FR_OFFSET), index)
    val () = buf_set32(b, iadd(base, FR_KIND), imod(index, 3))
  in fill(left-1, b, iadd(index, 1), count, if ilt(code, 0) then code else idiv(code, 3)) end else ()

fun verify{n:nat} .<n>. (left: int(n), b: !Buf, original: !Buf, seen: !Buf, index: int, count: int, errors: int): int =
  if left > 0 then let
    val base = imul(index, FR_ENTRY_WORDS)
    val owner = buf_get32(b, iadd(base, FR_OWNER))
    val identity = buf_get32(b, iadd(base, FR_OFFSET))
    val previous = isub(base, FR_ENTRY_WORDS)
    val ordered = ieq(index, 0) orelse ilt(buf_get32(b, previous), owner) orelse
      (ieq(buf_get32(b, previous), owner) andalso ilt(buf_get32(b, iadd(previous, FR_OFFSET)), identity))
    val record = ige(identity, 0) andalso ilt(identity, count) andalso ieq(buf_get(seen, identity), 0)
      andalso ieq(owner, buf_get32(original, imul(identity, FR_ENTRY_WORDS)))
      andalso ieq(buf_get32(b, iadd(base, FR_END)), iadd(identity, 1))
      andalso ieq(buf_get32(b, iadd(base, FR_KIND)), imod(identity, 3))
    val () = buf_set(seen, identity, 1)
    val error = if ordered andalso record then 0 else 1
  in verify(left-1, b, original, seen, iadd(index, 1), count, iadd(errors, error)) end else errors

fun run_case(count: int, code: int): int = let
  val before = mem_live()
  val b = buf_make(imul(count, FR_ENTRY_BYTES))
  val () = buf_set_len(b, imul(count, FR_ENTRY_BYTES))
  val () = fill(airlock_nat(count), b, 0, count, code)
  val original = buf_make(buf_len(b))
  val () = buf_copy_range(original, 0, b, 0, buf_len(b))
  val work = regions_sort_work(b)
  val seen = buf_make(count)
  val errors = verify(airlock_nat(count), b, original, seen, 0, count, 0)
  val expected = if ilt(count, 2) then 0 else imul(WORD32_BYTES, iadd(imul(2, count), REGION_RADIX_BUCKETS))
  val () = buf_free(seen)
  val () = buf_free(original)
  val () = buf_free(b)
in iadd(errors, if ieq(work, expected) andalso ieq(before, mem_live()) then 0 else 1) end

fun exhaustive{n:nat} .<n>. (left: int(n), code: int): int =
  if left > 0 then iadd(run_case(8, code), exhaustive(left-1, iadd(code, 1))) else 0

fun growth{n:nat} .<n>. (left: int(n), count: int): int =
  if left > 0 then let
    val errors = run_case(count, ~1)
    val () = println!("event=region_sort count=", count, " errors=", errors)
  in iadd(errors, growth(left-1, imul(count, 2))) end else 0

implement main0() = let
  val small = iadd(iadd(run_case(0, 0), run_case(1, 0)), run_case(8, ~2))
  val errors = iadd(small, iadd(exhaustive(TERNARY_CASE_COUNT, 0), growth(17, 1)))
  val () = println!("event=region_sort_contracts errors=", errors)
in if igt(errors, 0) then exit(1) else () end
