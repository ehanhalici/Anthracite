#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
#include "common.hats"
staload "mem.sats"

macdef TEST_INT_MAX = 2147483647
macdef TEST_INT_MIN = ~2147483647 - 1
macdef FIRST_WORD = 16909060 (* 0x01020304 *)
macdef SECOND_WORD = 84281096 (* 0x05060708 *)

fun rejected_index(index: int): int = let
  val b = buf_make(imul(2, WORD32_BYTES))
  val () = buf_set32(b, 0, FIRST_WORD)
  val () = buf_set32(b, 1, SECOND_WORD)
  val p = buf_ptr(b)
  val capacity = buf_cap(b)
  val reads = ieq(mem_i32(p, capacity, index), 0) andalso ieq(buf_get32(b, index), 0)
  val () = buf_set32(b, index, ~1)
  val () = mem_set_i32(p, capacity, index, ~1)
  val () = mem_set_f32(p, capacity, index, 1.0f)
  val () = buf_set_f32(b, index, 1.0f)
  val unchanged = ieq(buf_get32(b, 0), FIRST_WORD) andalso ieq(buf_get32(b, 1), SECOND_WORD)
  val () = buf_free(b)
in if reads andalso unchanged then 0 else 1 end

fun capacities{n:nat} .<n>. (left: int(n), capacity: int): int =
  if left > 0 then let
    val b = buf_make(capacity)
    val last = isub(idiv(capacity, WORD32_BYTES), 1)
    val () = buf_set32(b, last, FIRST_WORD)
    val valid = if ige(last, 0) then ieq(buf_get32(b, last), FIRST_WORD) else true
    val rejected = ieq(buf_get32(b, iadd(last, 1)), 0)
    val () = buf_free(b)
    val error = if valid andalso rejected then 0 else 1
  in iadd(error, capacities(left-1, iadd(capacity, 1))) end else 0

implement main0() = let
  val before = mem_live()
  val extremes = iadd(rejected_index(TEST_INT_MAX), rejected_index(TEST_INT_MIN))
  val multiply = iadd(rejected_index(idiv(TEST_INT_MAX, WORD32_BYTES)),
    rejected_index(iadd(idiv(TEST_INT_MAX, WORD32_BYTES), 1)))
  val near_end = iadd(rejected_index(2), rejected_index(~1))
  val errors = iadd(iadd(extremes, multiply), iadd(near_end, capacities(12, 1)))
  val ok = ieq(errors, 0) andalso ieq(before, mem_live())
  val () = println!("event=word_boundary_contracts ok=", ok)
in if ok then () else exit(1) end
