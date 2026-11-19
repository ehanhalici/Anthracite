(* TrueType Collection (TTC) face-0 validation and standalone SFNT extraction. *)

fun ttc_hdr_end(b: !Buf): int =
  if ilt(buf_len(b), 16) then ~1
  else let
    val maj = sfnt_be16(b, 4)
    val minv = sfnt_be16(b, 6)
    val nfonts = sfnt_be32(b, 8)
  in
    if not(ieq(maj, 1) orelse ieq(maj, 2)) orelse ine(minv, 0)
       orelse ile(nfonts, 0) orelse igt(nfonts, 4096) then ~1
    else let
      val ends = iadd(12, imul(nfonts, 4))
    in
      if igt(ends, buf_len(b)) then ~1 else ends
    end
  end

fun ttc_face0_dir(b: !Buf): int =
  if ilt(buf_len(b), 16) orelse ine(sfnt_be32(b, 0), table_tag("ttcf")) then ~1
  else let
    val ends = ttc_hdr_end(b)
  in
    if ilt(ends, 0) then ~1
    else let
      val off = sfnt_be32(b, 12)
    in
      if ilt(off, ends) orelse igt(iadd(off, 12), buf_len(b)) then ~1 else off
    end
  end

fun ttc_pad4(n: int): int =
  if ile(n, 0) then 0 else imul(idiv(iadd(n, 3), 4), 4)

fun ttc_data_bytes {n:nat} .<n>. (
  rem: int(n), b: !Buf, rec_off: int, acc: int
): int =
  if rem = 0 then acc
  else let
    val p = ttc_pad4(sfnt_be32(b, iadd(rec_off, 12)))
  in
    if ilt(p, 0) orelse igt(p, isub(SIGNED_INT_MAX_VALUE, acc)) then ~1
    else ttc_data_bytes(rem - 1, b, iadd(rec_off, 16), iadd(acc, p))
  end

fun ttc_put_be32(b: !Buf, at: int, v: int): void = let
  val b0 = anth_iand(idiv(v, 16777216), 255)
  val b1 = anth_iand(idiv(v, 65536), 255)
  val b2 = anth_iand(idiv(v, 256), 255)
  val b3 = anth_iand(v, 255)
  val () = buf_set(b, at, b0)
  val () = buf_set(b, iadd(at, 1), b1)
  val () = buf_set(b, iadd(at, 2), b2)
in
  buf_set(b, iadd(at, 3), b3)
end

fun ttc_copy_tables {n:nat} .<n>. (
  rem: int(n), src: !Buf, src_rec: int, dst: !Buf, dst_rec: int, cur_off: int
): void =
  if rem = 0 then ()
  else let
    val orig_off = sfnt_be32(src, iadd(src_rec, 8))
    val orig_len = sfnt_be32(src, iadd(src_rec, 12))
    val () = buf_copy_range(dst, dst_rec, src, src_rec, 16)
    val () = ttc_put_be32(dst, iadd(dst_rec, 8), cur_off)
    val () = if igt(orig_len, 0) then buf_copy_range(dst, cur_off, src, orig_off, orig_len) else ()
    val next_off = iadd(cur_off, ttc_pad4(orig_len))
  in
    ttc_copy_tables(rem - 1, src, iadd(src_rec, 16), dst, iadd(dst_rec, 16), next_off)
  end

fun ttc_build_standalone(src: !Buf, dir_off: int): Option_vt(Buf) = let
  val n = sfnt_be16(src, iadd(dir_off, 4))
  val hdr = iadd(12, imul(n, 16))
  val data_sz = ttc_data_bytes(airlock_nat(n), src, iadd(dir_off, 12), 0)
in
  if ilt(data_sz, 0) orelse igt(hdr, isub(SIGNED_INT_MAX_VALUE, data_sz)) then None_vt()
  else let
    val out_sz = iadd(hdr, data_sz)
    val dst = buf_make(out_sz)
    val () = buf_set_len(dst, out_sz)
    val () = buf_copy_range(dst, 0, src, dir_off, 12)
    val () = ttc_copy_tables(airlock_nat(n), src, iadd(dir_off, 12), dst, 12, hdr)
  in
    Some_vt(dst)
  end
end

fun ttc_unpack_face0(src: !Buf): Option_vt(Buf) = let
  val dir_off = ttc_face0_dir(src)
  val floor = ttc_hdr_end(src)
in
  if ilt(dir_off, 0) orelse ilt(floor, 0) then None_vt()
  else if not(sfnt_container_valid(sfnt_be32(src, dir_off))) then None_vt()
  else if not(directory_header_at(src, dir_off, floor)) then None_vt()
  else ttc_build_standalone(src, dir_off)
end
