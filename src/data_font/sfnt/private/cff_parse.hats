(* Compact Font Format (CFF v1) table validation and INDEX/DICT lookup. *)

typedef CffIndex = @{ok=bool, count=int, off_size=int, arr=int, base=int, next=int}

fun cff_idx_fail(): CffIndex =
  @{ok=false, count=0, off_size=0, arr=0, base=0, next=0}

fun cff_off_acc {n:nat} .<n>. (
  rem: int(n), b: !Buf, p: int, acc: int
): int =
  if rem = 0 then acc
  else cff_off_acc(rem - 1, b, iadd(p, 1), iadd(imul(acc, 256), buf_get(b, p)))

fun cff_read_off(b: !Buf, p: int, sz: int): int =
  if ilt(sz, 1) orelse igt(sz, 4) then ~1
  else if ieq(sz, 4) andalso igt(buf_get(b, p), 127) then ~1
  else cff_off_acc(airlock_nat(sz), b, p, 0)

fun cff_offsets_monotonic {n:nat} .<n>. (
  rem: int(n), b: !Buf, arr: int, sz: int, i: int, prev: int, max_rel: int
): bool =
  if rem = 0 then true
  else let
    val o = cff_read_off(b, iadd(arr, imul(i, sz)), sz)
  in
    if ilt(o, prev) orelse igt(o, max_rel) then false
    else cff_offsets_monotonic(rem - 1, b, arr, sz, iadd(i, 1), o, max_rel)
  end

fun cff_index_body(b: !Buf, pos: int, count: int, limit: int): CffIndex =
  if igt(iadd(pos, 3), limit) then cff_idx_fail()
  else let
    val sz = buf_get(b, iadd(pos, 2))
  in
    if ilt(sz, 1) orelse igt(sz, 4) then cff_idx_fail()
    else let
      val arr = iadd(pos, 3)
      val arr_bytes = imul(iadd(count, 1), sz)
    in
      if igt(iadd(arr, arr_bytes), limit) then cff_idx_fail()
      else let
        val base = isub(iadd(arr, arr_bytes), 1)
        val o0 = cff_read_off(b, arr, sz)
        val o_end = cff_read_off(b, iadd(arr, imul(count, sz)), sz)
        val max_rel = isub(limit, base)
      in
        if ine(o0, 1) orelse ilt(o_end, 1) orelse igt(iadd(base, o_end), limit) then cff_idx_fail()
        else if not(cff_offsets_monotonic(airlock_nat(iadd(count, 1)), b, arr, sz, 0, 1, max_rel)) then cff_idx_fail()
        else @{ok=true, count=count, off_size=sz, arr=arr, base=base, next=iadd(base, o_end)}
      end
    end
  end

fun cff_index_read(b: !Buf, pos: int, limit: int): CffIndex =
  if ilt(pos, 0) orelse igt(iadd(pos, 2), limit) then cff_idx_fail()
  else let
    val count = sfnt_be16(b, pos)
  in
    if ieq(count, 0) then @{ok=true, count=0, off_size=1, arr=iadd(pos, 2), base=iadd(pos, 2), next=iadd(pos, 2)}
    else cff_index_body(b, pos, count, limit)
  end

fun cff_index_item_at(b: !Buf, pos: int, limit: int, item: int): SfntOptional =
  if ilt(pos, 0) orelse igt(iadd(pos, 3), limit) orelse ilt(item, 0) then NoSfntTable()
  else let
    val count = sfnt_be16(b, pos)
    val sz = buf_get(b, iadd(pos, 2))
  in
    if ige(item, count) orelse ilt(sz, 1) orelse igt(sz, 4) then NoSfntTable()
    else let
      val arr = iadd(pos, 3)
      val arr_bytes = imul(iadd(count, 1), sz)
    in
      if igt(iadd(arr, arr_bytes), limit) then NoSfntTable()
      else let
        val base = isub(iadd(arr, arr_bytes), 1)
        val o0 = cff_read_off(b, iadd(arr, imul(item, sz)), sz)
        val o1 = cff_read_off(b, iadd(arr, imul(iadd(item, 1), sz)), sz)
      in
        if ilt(o0, 1) orelse ilt(o1, o0) orelse igt(iadd(base, o1), limit) then NoSfntTable()
        else HasSfntTable(@{offset=iadd(base, o0), length=isub(o1, o0)})
      end
    end
  end

fun cff_signed32(b: !Buf, p: int): int = let
  val hi = sfnt_be16(b, p)
  val lo = sfnt_be16(b, iadd(p, 2))
in
  if ilt(hi, 32768) then iadd(imul(hi, WORD16_MODULUS), lo)
  else if ieq(hi, 32768) andalso ieq(lo, 0) then ~2147483647 - 1
  else iadd(imul(isub(hi, WORD16_MODULUS), WORD16_MODULUS), lo)
end

fun cff_nibbles_end {n:nat} .<n>. (rem: int(n), b: !Buf, p: int): int =
  if rem = 0 then p
  else let
    val byte = buf_get(b, p)
    val hi = idiv(byte, 16)
    val lo = imod(byte, 16)
  in
    if ieq(hi, 15) orelse ieq(lo, 15) then iadd(p, 1)
    else cff_nibbles_end(rem - 1, b, iadd(p, 1))
  end

typedef CffDictVals = @{
  ok=bool, charstrings=int, priv_sz=int, priv_off=int,
  subrs=int, fdarray=int, fdselect=int
}

fun cff_dict_init(): CffDictVals =
  @{ok=true, charstrings= ~1, priv_sz=0, priv_off= ~1, subrs= ~1, fdarray= ~1, fdselect= ~1}

fun cff_dict_apply1(d: CffDictVals, d_op: int, cnt: int, a: int, v: int): CffDictVals =
  if ieq(d_op, 17) andalso ige(cnt, 1) then @{ok=d.ok, charstrings=v, priv_sz=d.priv_sz, priv_off=d.priv_off, subrs=d.subrs, fdarray=d.fdarray, fdselect=d.fdselect}
  else if ieq(d_op, 18) andalso ige(cnt, 2) then @{ok=d.ok, charstrings=d.charstrings, priv_sz=a, priv_off=v, subrs=d.subrs, fdarray=d.fdarray, fdselect=d.fdselect}
  else if ieq(d_op, 19) andalso ige(cnt, 1) then @{ok=d.ok, charstrings=d.charstrings, priv_sz=d.priv_sz, priv_off=d.priv_off, subrs=v, fdarray=d.fdarray, fdselect=d.fdselect}
  else d

fun cff_dict_apply2(d: CffDictVals, op2: int, cnt: int, v: int): CffDictVals =
  if ieq(op2, 36) andalso ige(cnt, 1) then @{ok=d.ok, charstrings=d.charstrings, priv_sz=d.priv_sz, priv_off=d.priv_off, subrs=d.subrs, fdarray=v, fdselect=d.fdselect}
  else if ieq(op2, 37) andalso ige(cnt, 1) then @{ok=d.ok, charstrings=d.charstrings, priv_sz=d.priv_sz, priv_off=d.priv_off, subrs=d.subrs, fdarray=d.fdarray, fdselect=v}
  else d

fun cff_dict_num(b: !Buf, p: int, limit: int, b0: int, next_p: &int >> _, val_out: &int >> _): bool =
  if ieq(b0, 28) then (
    if igt(iadd(p, 3), limit) then false
    else let val () = next_p := iadd(p, 3) val () = val_out := sfnt_signed16(b, iadd(p, 1)) in true end
  ) else if ieq(b0, 29) then (
    if igt(iadd(p, 5), limit) then false
    else let val () = next_p := iadd(p, 5) val () = val_out := cff_signed32(b, iadd(p, 1)) in true end
  ) else if ieq(b0, 30) then let
    val np = cff_nibbles_end(airlock_nat(imax(0, isub(limit, iadd(p, 1)))), b, iadd(p, 1))
    val () = next_p := np
    val () = val_out := 0
  in
    true
  end else if ige(b0, 32) andalso ile(b0, 246) then let
    val () = next_p := iadd(p, 1)
    val () = val_out := isub(b0, 139)
  in
    true
  end else if ige(b0, 247) andalso ile(b0, 250) then (
    if igt(iadd(p, 2), limit) then false
    else let
      val () = next_p := iadd(p, 2)
      val () = val_out := iadd(iadd(imul(isub(b0, 247), 256), buf_get(b, iadd(p, 1))), 108)
    in true end
  ) else if ige(b0, 251) andalso ile(b0, 254) then (
    if igt(iadd(p, 2), limit) then false
    else let
      val () = next_p := iadd(p, 2)
      val () = val_out := isub(isub(0, iadd(imul(isub(b0, 251), 256), buf_get(b, iadd(p, 1)))), 108)
    in true end
  ) else false

fun cff_dict_scan {n:nat} .<n>. (
  recfuel: int(n), b: !Buf, p: int, limit: int, cnt: int, a: int, v: int, acc: CffDictVals
): CffDictVals =
  if recursion_fuel_available(recfuel) then (
    if ige(p, limit) then acc
    else let
      val b0 = buf_get(b, p)
    in
      if ile(b0, 21) then (
        if ieq(b0, 12) then (
          if igt(iadd(p, 2), limit) then @{ok=false, charstrings= ~1, priv_sz=0, priv_off= ~1, subrs= ~1, fdarray= ~1, fdselect= ~1}
          else let val acc2 = cff_dict_apply2(acc, buf_get(b, iadd(p, 1)), cnt, v)
          in cff_dict_scan(recfuel - 1, b, iadd(p, 2), limit, 0, 0, 0, acc2) end
        ) else let
          val acc2 = cff_dict_apply1(acc, b0, cnt, a, v)
        in cff_dict_scan(recfuel - 1, b, iadd(p, 1), limit, 0, 0, 0, acc2) end
      ) else let
        var np: int = p
        var nv: int = 0
      in
        if cff_dict_num(b, p, limit, b0, np, nv) then
          cff_dict_scan(recfuel - 1, b, np, limit, iadd(cnt, 1), v, nv, acc)
        else @{ok=false, charstrings= ~1, priv_sz=0, priv_off= ~1, subrs= ~1, fdarray= ~1, fdselect= ~1}
      end
    end
  ) else @{ok=false, charstrings= ~1, priv_sz=0, priv_off= ~1, subrs= ~1, fdarray= ~1, fdselect= ~1}

fun cff_parse_dict(b: !Buf, span: SfntSpan): CffDictVals =
  cff_dict_scan(airlock_nat(MAX_REC_FUEL), b, span.offset, iadd(span.offset, span.length), 0, 0, 0, cff_dict_init())

fun cff_fdselect_valid_fmt3 {n:nat} .<n>. (
  rem: int(n), b: !Buf, p: int, nr: int, i: int, prev_first: int, glyphs: int, fd_cnt: int
): bool =
  if rem = 0 then ieq(sfnt_be16(b, iadd(p, imul(nr, 3))), glyphs)
  else let
    val rp = iadd(p, imul(i, 3))
    val first = sfnt_be16(b, rp)
    val fd = buf_get(b, iadd(rp, 2))
  in
    if ilt(first, prev_first) orelse ige(fd, fd_cnt) then false
    else if ieq(i, 0) andalso ine(first, 0) then false
    else cff_fdselect_valid_fmt3(rem - 1, b, p, nr, iadd(i, 1), iadd(first, 1), glyphs, fd_cnt)
  end

fun cff_fdselect_valid_fmt0 {n:nat} .<n>. (
  rem: int(n), b: !Buf, p: int, i: int, fd_cnt: int
): bool =
  if rem = 0 then true
  else if ige(buf_get(b, iadd(p, i)), fd_cnt) then false
  else cff_fdselect_valid_fmt0(rem - 1, b, p, iadd(i, 1), fd_cnt)

fun cff_fdselect_valid(b: !Buf, fds_pos: int, limit: int, glyphs: int, fd_cnt: int): bool =
  if ilt(fds_pos, 0) orelse igt(iadd(fds_pos, 1), limit) orelse ile(fd_cnt, 0) then false
  else let
    val fmt = buf_get(b, fds_pos)
  in
    if ieq(fmt, 0) then
      ile(iadd(iadd(fds_pos, 1), glyphs), limit)
      andalso cff_fdselect_valid_fmt0(airlock_nat(imax(0, glyphs)), b, iadd(fds_pos, 1), 0, fd_cnt)
    else if ieq(fmt, 3) then (
      if igt(iadd(fds_pos, 3), limit) then false
      else let
        val nr = sfnt_be16(b, iadd(fds_pos, 1))
        val end_at = iadd(iadd(fds_pos, 3), iadd(imul(nr, 3), 2))
      in
        igt(nr, 0) andalso ile(end_at, limit)
        andalso cff_fdselect_valid_fmt3(airlock_nat(nr), b, iadd(fds_pos, 3), nr, 0, 0, glyphs, fd_cnt)
      end
    ) else false
  end

fun cff_priv_lsubr_at(b: !Buf, cff_off: int, limit: int, psz: int, poff: int): int =
  if ilt(poff, 0) then ~1
  else if ilt(psz, 0) orelse igt(iadd(iadd(cff_off, poff), psz), limit) then ~2
  else let
    val pabs = iadd(cff_off, poff)
    val pd = cff_parse_dict(b, @{offset=pabs, length=psz})
  in
    if not(pd.ok) then ~2
    else if ilt(pd.subrs, 0) then ~1
    else let
      val sabs = iadd(pabs, pd.subrs)
      val idx = cff_index_read(b, sabs, limit)
    in
      if idx.ok then sabs else ~2
    end
  end

fun cff_fdarray_valid {n:nat} .<n>. (
  rem: int(n), b: !Buf, cff_off: int, limit: int, fd_pos: int, i: int
): bool =
  if rem = 0 then true
  else case+ cff_index_item_at(b, fd_pos, limit, i) of
    | ~NoSfntTable() => false
    | ~HasSfntTable(span) => let
        val fd = cff_parse_dict(b, span)
      in
        if not(fd.ok) then false
        else if ilt(cff_priv_lsubr_at(b, cff_off, limit, fd.priv_sz, fd.priv_off), ~1) then false
        else cff_fdarray_valid(rem - 1, b, cff_off, limit, fd_pos, iadd(i, 1))
      end

fun cff_ctx_invalid(): SfntCffContext =
  @{valid=false, cff= @{offset=0, length=0}, charstrings= ~1, gsubrs= ~1, lsubrs= ~1, fdarray= ~1, fdselect= ~1}

fun cff_next_index(b: !Buf, prev: CffIndex, limit: int): CffIndex =
  if prev.ok then cff_index_read(b, prev.next, limit) else cff_idx_fail()

fun cff_build_ctx(b: !Buf, cff: SfntSpan, glyphs_expected: int): SfntCffContext = let
  val cend = iadd(cff.offset, cff.length)
in
  if ilt(cff.length, 4) then cff_ctx_invalid()
  else let
    val maj = buf_get(b, cff.offset)
    val minv = buf_get(b, iadd(cff.offset, 1))
    val hsz = buf_get(b, iadd(cff.offset, 2))
  in
    if ine(maj, 1) orelse ine(minv, 0) orelse ilt(hsz, 4) orelse igt(iadd(cff.offset, hsz), cend) then cff_ctx_invalid()
    else let
      val names = cff_index_read(b, iadd(cff.offset, hsz), cend)
      val tops = cff_next_index(b, names, cend)
      val strs = cff_next_index(b, tops, cend)
      val gsubrs = cff_next_index(b, strs, cend)
    in
      if not(names.ok) orelse not(tops.ok) orelse not(strs.ok) orelse not(gsubrs.ok)
         orelse ilt(names.count, 1) orelse ine(tops.count, names.count) then cff_ctx_invalid()
      else case+ cff_index_item_at(b, names.next, cend, 0) of
        | ~NoSfntTable() => cff_ctx_invalid()
        | ~HasSfntTable(td_span) => let
            val td = cff_parse_dict(b, td_span)
          in
            if not(td.ok) orelse ilt(td.charstrings, 1) then cff_ctx_invalid()
            else let
              val cs_abs = iadd(cff.offset, td.charstrings)
              val cs = cff_index_read(b, cs_abs, cend)
            in
              if not(cs.ok) orelse (ige(glyphs_expected, 0) andalso ine(cs.count, glyphs_expected)) then cff_ctx_invalid()
              else if ige(td.fdarray, 0) orelse ige(td.fdselect, 0) then (
                if ilt(td.fdarray, 1) orelse ilt(td.fdselect, 1) then cff_ctx_invalid()
                else let
                  val fda_abs = iadd(cff.offset, td.fdarray)
                  val fds_abs = iadd(cff.offset, td.fdselect)
                  val fda = cff_index_read(b, fda_abs, cend)
                in
                  if not(fda.ok) orelse not(cff_fdarray_valid(airlock_nat(fda.count), b, cff.offset, cend, fda_abs, 0))
                     orelse not(cff_fdselect_valid(b, fds_abs, cend, cs.count, fda.count)) then cff_ctx_invalid()
                  else @{valid=true, cff=cff, charstrings=cs_abs, gsubrs=strs.next, lsubrs= ~1, fdarray=fda_abs, fdselect=fds_abs}
                end
              ) else let
                val lsub = cff_priv_lsubr_at(b, cff.offset, cend, td.priv_sz, td.priv_off)
              in
                if ilt(lsub, ~1) then cff_ctx_invalid()
                else @{valid=true, cff=cff, charstrings=cs_abs, gsubrs=strs.next, lsubrs=lsub, fdarray= ~1, fdselect= ~1}
              end
            end
          end
    end
  end
end

fun cff_fdselect_lookup_fmt3 {n:nat} .<n>. (
  rem: int(n), b: !Buf, p: int, nr: int, lo: int, hi: int, gid: int
): int =
  if rem = 0 then ~1
  else if ige(lo, hi) then ~1
  else let
    val mid = iadd(lo, idiv(isub(hi, lo), 2))
    val first = sfnt_be16(b, iadd(p, imul(mid, 3)))
    val next_first = sfnt_be16(b, iadd(p, imul(iadd(mid, 1), 3)))
  in
    if ilt(gid, first) then cff_fdselect_lookup_fmt3(rem - 1, b, p, nr, lo, mid, gid)
    else if ige(gid, next_first) then cff_fdselect_lookup_fmt3(rem - 1, b, p, nr, iadd(mid, 1), hi, gid)
    else buf_get(b, iadd(p, iadd(imul(mid, 3), 2)))
  end

fun cff_fd_for_gid(b: !Buf, ctx: SfntCffContext, gid: int): int =
  if ilt(ctx.fdselect, 0) orelse ilt(gid, 0) then ~1
  else let
    val fmt = buf_get(b, ctx.fdselect)
  in
    if ieq(fmt, 0) then buf_get(b, iadd(iadd(ctx.fdselect, 1), gid))
    else if ieq(fmt, 3) then let
      val nr = sfnt_be16(b, iadd(ctx.fdselect, 1))
    in
      cff_fdselect_lookup_fmt3(airlock_nat(iadd(nr, 1)), b, iadd(ctx.fdselect, 3), nr, 0, nr, gid)
    end else ~1
  end

fun cff_lsubr_pos_for_gid(b: !Buf, ctx: SfntCffContext, gid: int): int =
  if ilt(ctx.fdarray, 0) then ctx.lsubrs
  else let
    val fdi = cff_fd_for_gid(b, ctx, gid)
    val cend = iadd(ctx.cff.offset, ctx.cff.length)
  in
    if ilt(fdi, 0) then ~1
    else case+ cff_index_item_at(b, ctx.fdarray, cend, fdi) of
      | ~NoSfntTable() => ~1
      | ~HasSfntTable(span) => let
          val fd = cff_parse_dict(b, span)
        in
          if not(fd.ok) then ~1
          else let val p = cff_priv_lsubr_at(b, ctx.cff.offset, cend, fd.priv_sz, fd.priv_off)
          in if ilt(p, 0) then ~1 else p end
        end
  end

implement sfnt_cff_context_empty() = cff_ctx_invalid()

implement sfnt_cff_context(b, cff) = cff_build_ctx(b, cff, ~1)

implement sfnt_cff_subr_bias(count) =
  if ilt(count, 1240) then 107
  else if ilt(count, 33900) then 1131
  else 32768

implement sfnt_cff_glyph_span(b, ctx, gid) =
  if not(ctx.valid) orelse ilt(ctx.charstrings, 0) then NoSfntTable()
  else cff_index_item_at(b, ctx.charstrings, iadd(ctx.cff.offset, ctx.cff.length), gid)

implement sfnt_cff_gsubr_count(b, ctx) =
  if not(ctx.valid) orelse ilt(ctx.gsubrs, 0) then 0
  else sfnt_be16(b, ctx.gsubrs)

implement sfnt_cff_gsubr_span(b, ctx, idx) =
  if not(ctx.valid) orelse ilt(ctx.gsubrs, 0) then NoSfntTable()
  else cff_index_item_at(b, ctx.gsubrs, iadd(ctx.cff.offset, ctx.cff.length), idx)

implement sfnt_cff_lsubr_count(b, ctx, gid) = let
  val p = cff_lsubr_pos_for_gid(b, ctx, gid)
in
  if not(ctx.valid) orelse ilt(p, 0) then 0
  else sfnt_be16(b, p)
end

implement sfnt_cff_lsubr_span(b, ctx, gid, idx) = let
  val p = cff_lsubr_pos_for_gid(b, ctx, gid)
in
  if not(ctx.valid) orelse ilt(p, 0) then NoSfntTable()
  else cff_index_item_at(b, p, iadd(ctx.cff.offset, ctx.cff.length), idx)
end
