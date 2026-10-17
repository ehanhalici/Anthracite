(* Stable LSD radix sort over the little-endian signed owner word. Four byte
   passes return the result to the original buffer. Work = 4 * (2*R + 256).
   Every pass moves full records; equal owners retain their original order. *)
macdef REGION_RADIX_BUCKETS = 256
macdef REGION_SIGN_BIT = 128

fun region_owner_digit(regions: !Buf, index: int, digit: int): int = let
  val byte = buf_get(regions, iadd(imul(index, FR_ENTRY_BYTES), digit))
in
  if ieq(digit, isub(WORD32_BYTES, 1)) then
    (if ilt(byte, REGION_SIGN_BIT) then iadd(byte, REGION_SIGN_BIT) else isub(byte, REGION_SIGN_BIT))
  else byte
end

fun region_histogram{n:nat} .<n>. (
  remaining: int(n), regions: !Buf, buckets: !Buf, index: int, digit: int, work: int
): int =
  if remaining > 0 then let
    val key = region_owner_digit(regions, index, digit)
    val () = buf_set32(buckets, key, iadd(buf_get32(buckets, key), 1))
  in region_histogram(remaining-1, regions, buckets, iadd(index, 1), digit, iadd(work, 1)) end else work

fun region_bucket_starts{n:nat} .<n>. (
  remaining: int(n), buckets: !Buf, key: int, start: int, work: int
): int =
  if remaining > 0 then let
    val count = buf_get32(buckets, key)
    val () = buf_set32(buckets, key, start)
  in region_bucket_starts(remaining-1, buckets, iadd(key, 1), iadd(start, count), iadd(work, 1)) end else work

fun region_scatter{n:nat} .<n>. (
  remaining: int(n), source: !Buf, target: !Buf, buckets: !Buf, index: int, digit: int, work: int
): int =
  if remaining > 0 then let
    val key = region_owner_digit(source, index, digit)
    val destination = buf_get32(buckets, key)
    val () = buf_copy_range(target, imul(destination, FR_ENTRY_BYTES),
      source, imul(index, FR_ENTRY_BYTES), FR_ENTRY_BYTES)
    val () = buf_set32(buckets, key, iadd(destination, 1))
  in region_scatter(remaining-1, source, target, buckets, iadd(index, 1), digit, iadd(work, 1)) end else work

fun region_radix_passes{p:nat} .<p>. (
  passes: int(p), source: !Buf, target: !Buf, buckets: !Buf, count: int, digit: int
): int =
  if passes > 0 then let
    val () = buf_zero(buckets)
    val histogram_work = region_histogram(airlock_nat(count), source, buckets, 0, digit, 0)
    val prefix_work = region_bucket_starts(REGION_RADIX_BUCKETS, buckets, 0, 0, 0)
    val scatter_work = region_scatter(airlock_nat(count), source, target, buckets, 0, digit, 0)
    val later_work = region_radix_passes(passes-1, target, source, buckets, count, iadd(digit, 1))
  in iadd(iadd(histogram_work, prefix_work), iadd(scatter_work, later_work)) end else 0

fun regions_sort_work(regions: !Buf): int = let
  val count = idiv(buf_len(regions), FR_ENTRY_BYTES)
in
  if ilt(count, 2) then 0 else let
    val scratch = buf_make(buf_len(regions))
    val () = buf_set_len(scratch, buf_len(regions))
    val buckets = buf_make(imul(REGION_RADIX_BUCKETS, WORD32_BYTES))
    val work = region_radix_passes(WORD32_BYTES, regions, scratch, buckets, count, 0)
    val () = buf_free(buckets)
    val () = buf_free(scratch)
  in work end
end
