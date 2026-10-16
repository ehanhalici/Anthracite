#ifndef ANTHRACITE_STB_JPG_IDCT_HATS
#define ANTHRACITE_STB_JPG_IDCT_HATS

macdef IDCT_CONST_0_541 = 2217
macdef IDCT_CONST_N1_847 = ~7567
macdef IDCT_CONST_0_765 = 3135
macdef IDCT_CONST_1_175 = 4816
macdef IDCT_CONST_0_298 = 1223
macdef IDCT_CONST_2_053 = 8410
macdef IDCT_CONST_3_072 = 12586
macdef IDCT_CONST_1_501 = 6149
macdef IDCT_CONST_N0_899 = ~3685
macdef IDCT_CONST_N2_562 = ~10497
macdef IDCT_CONST_N1_961 = ~8034
macdef IDCT_CONST_N0_390 = ~1597
macdef IDCT_COL_BIAS = 512
macdef IDCT_ROW_BIAS = 16842752

typedef IdctEven = @{x0= int, x1= int, x2= int, x3= int, t2= int, t3= int}
typedef IdctOdd = @{t0= int, t1= int, t2= int, t3= int}

fun idct_calc_even(s0: int, s2: int, s4: int, s6: int, bias: int): IdctEven = let
  val p1 = imul(iadd(s2, s6), IDCT_CONST_0_541)
  val t2 = iadd(p1, imul(s6, IDCT_CONST_N1_847))
  val t3 = iadd(p1, imul(s2, IDCT_CONST_0_765))
  val t0 = imul(iadd(s0, s4), 4096)
  val t1 = imul(isub(s0, s4), 4096)
in
  @{x0= iadd(iadd(t0, t3), bias),
    x1= iadd(iadd(t1, t2), bias),
    x2= iadd(isub(t1, t2), bias),
    x3= iadd(isub(t0, t3), bias),
    t2= t2, t3= t3}
end

fun idct_calc_odd(s1: int, s3: int, s5: int, s7: int): IdctOdd = let
  val p3 = iadd(s7, s3) and p4 = iadd(s5, s1)
  val p1 = iadd(s7, s1) and p2 = iadd(s5, s3)
  val p5 = imul(iadd(p3, p4), IDCT_CONST_1_175)
  val o1 = iadd(p5, imul(p1, IDCT_CONST_N0_899))
  val o2 = iadd(p5, imul(p2, IDCT_CONST_N2_562))
  val o3 = imul(p3, IDCT_CONST_N1_961)
  val o4 = imul(p4, IDCT_CONST_N0_390)
in
  @{t0= iadd(iadd(imul(s7, IDCT_CONST_0_298), o1), o3),
    t1= iadd(iadd(imul(s5, IDCT_CONST_2_053), o2), o4),
    t2= iadd(iadd(imul(s3, IDCT_CONST_3_072), o2), o3),
    t3= iadd(iadd(imul(s1, IDCT_CONST_1_501), o1), o4)}
end

fun idct_col_save(val_buf: !Buf, c: int, ev: IdctEven, od: IdctOdd): void = let
  val () = buf_set32(val_buf, c, ashr(iadd(ev.x0, od.t3), 10))
  val () = buf_set32(val_buf, iadd(c, 56), ashr(isub(ev.x0, od.t3), 10))
  val () = buf_set32(val_buf, iadd(c, 8), ashr(iadd(ev.x1, od.t2), 10))
  val () = buf_set32(val_buf, iadd(c, 48), ashr(isub(ev.x1, od.t2), 10))
  val () = buf_set32(val_buf, iadd(c, 16), ashr(iadd(ev.x2, od.t1), 10))
  val () = buf_set32(val_buf, iadd(c, 40), ashr(isub(ev.x2, od.t1), 10))
  val () = buf_set32(val_buf, iadd(c, 24), ashr(iadd(ev.x3, od.t0), 10))
  val () = buf_set32(val_buf, iadd(c, 32), ashr(isub(ev.x3, od.t0), 10))
in
end

fun idct_col_shortcut(val_buf: !Buf, c: int, d0: int): void = let
  val term = imul(d0, 4)
  val () = buf_set32(val_buf, c, term)
  val () = buf_set32(val_buf, iadd(c, 8), term)
  val () = buf_set32(val_buf, iadd(c, 16), term)
  val () = buf_set32(val_buf, iadd(c, 24), term)
  val () = buf_set32(val_buf, iadd(c, 32), term)
  val () = buf_set32(val_buf, iadd(c, 40), term)
  val () = buf_set32(val_buf, iadd(c, 48), term)
  val () = buf_set32(val_buf, iadd(c, 56), term)
in
end

fun idct_col_full(val_buf: !Buf, c: int, d0: int, d1: int, d2: int, d3: int, d4: int, d5: int, d6: int, d7: int): void = let
  val ev = idct_calc_even(d0, d2, d4, d6, IDCT_COL_BIAS)
  val od = idct_calc_odd(d1, d3, d5, d7)
in
  idct_col_save(val_buf, c, ev, od)
end

fun idct_col(val_buf: !Buf, data: !Buf, sbase: int, c: int): void = let
  val d0 = buf_get32(data, iadd(sbase, c))
  val d1 = buf_get32(data, iadd(sbase, iadd(c, 8)))
  val d2 = buf_get32(data, iadd(sbase, iadd(c, 16)))
  val d3 = buf_get32(data, iadd(sbase, iadd(c, 24)))
  val d4 = buf_get32(data, iadd(sbase, iadd(c, 32)))
  val d5 = buf_get32(data, iadd(sbase, iadd(c, 40)))
  val d6 = buf_get32(data, iadd(sbase, iadd(c, 48)))
  val d7 = buf_get32(data, iadd(sbase, iadd(c, 56)))
in
  if ieq(d1, 0) andalso ieq(d2, 0) andalso ieq(d3, 0) andalso ieq(d4, 0)
     andalso ieq(d5, 0) andalso ieq(d6, 0) andalso ieq(d7, 0) then
    idct_col_shortcut(val_buf, c, d0)
  else idct_col_full(val_buf, c, d0, d1, d2, d3, d4, d5, d6, d7)
end

extern fun idct_cols_fuel_exhausted(val_buf: !Buf, data: !Buf, sbase: int, c: int): void = "mac#anth_die_void"

fun idct_cols_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), val_buf: !Buf, data: !Buf, sbase: int, c: int): void =
  if recfuel > 0 then (
    if ige(c, 8) then ()
    else let
      val () = idct_col(val_buf, data, sbase, c)
    in
      idct_cols_with_fuel(recfuel - 1, val_buf, data, sbase, iadd(c, 1))
    end
  ) else idct_cols_fuel_exhausted(val_buf, data, sbase, c)

fun idct_row_save(dst: !Buf, dbase: int, ev: IdctEven, od: IdctOdd): void = let
  val () = buf_set(dst, dbase, clamp255(ashr(iadd(ev.x0, od.t3), 17)))
  val () = buf_set(dst, iadd(dbase, 7), clamp255(ashr(isub(ev.x0, od.t3), 17)))
  val () = buf_set(dst, iadd(dbase, 1), clamp255(ashr(iadd(ev.x1, od.t2), 17)))
  val () = buf_set(dst, iadd(dbase, 6), clamp255(ashr(isub(ev.x1, od.t2), 17)))
  val () = buf_set(dst, iadd(dbase, 2), clamp255(ashr(iadd(ev.x2, od.t1), 17)))
  val () = buf_set(dst, iadd(dbase, 5), clamp255(ashr(isub(ev.x2, od.t1), 17)))
  val () = buf_set(dst, iadd(dbase, 3), clamp255(ashr(iadd(ev.x3, od.t0), 17)))
  val () = buf_set(dst, iadd(dbase, 4), clamp255(ashr(isub(ev.x3, od.t0), 17)))
in
end

fun idct_row(dst: !Buf, dbase: int, val_buf: !Buf, r: int): void = let
  val rbase = imul(r, 8)
  val v0 = buf_get32(val_buf, rbase)
  val v1 = buf_get32(val_buf, iadd(rbase, 1))
  val v2 = buf_get32(val_buf, iadd(rbase, 2))
  val v3 = buf_get32(val_buf, iadd(rbase, 3))
  val v4 = buf_get32(val_buf, iadd(rbase, 4))
  val v5 = buf_get32(val_buf, iadd(rbase, 5))
  val v6 = buf_get32(val_buf, iadd(rbase, 6))
  val v7 = buf_get32(val_buf, iadd(rbase, 7))
  val ev = idct_calc_even(v0, v2, v4, v6, IDCT_ROW_BIAS)
  val od = idct_calc_odd(v1, v3, v5, v7)
in
  idct_row_save(dst, dbase, ev, od)
end

extern fun idct_rows_fuel_exhausted(dst: !Buf, out_off: int, out_stride: int, val_buf: !Buf, r: int): void = "mac#anth_die_void"

fun idct_rows_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), dst: !Buf, out_off: int, out_stride: int, val_buf: !Buf, r: int): void =
  if recfuel > 0 then (
    if ige(r, 8) then ()
    else let
      val dbase = iadd(out_off, imul(r, out_stride))
      val () = idct_row(dst, dbase, val_buf, r)
    in
      idct_rows_with_fuel(recfuel - 1, dst, out_off, out_stride, val_buf, iadd(r, 1))
    end
  ) else idct_rows_fuel_exhausted(dst, out_off, out_stride, val_buf, r)

fun stbi_idct_block(dst: !Buf, out_off: int, out_stride: int, data: !Buf, sbase: int, val_buf: !Buf): void = let
  val () = idct_cols_with_fuel(airlock_nat(MAX_REC_FUEL), val_buf, data, sbase, 0)
in
  idct_rows_with_fuel(airlock_nat(MAX_REC_FUEL), dst, out_off, out_stride, val_buf, 0)
end

#endif
