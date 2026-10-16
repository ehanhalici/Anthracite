#ifndef ANTHRACITE_STB_JPG_TABLES_HATS
#define ANTHRACITE_STB_JPG_TABLES_HATS

fun dezigzag_0_15(k: int): int =
  if ieq(k, 0) then 0 else if ieq(k, 1) then 1 else if ieq(k, 2) then 8 else if ieq(k, 3) then 16
  else if ieq(k, 4) then 9 else if ieq(k, 5) then 2 else if ieq(k, 6) then 3 else if ieq(k, 7) then 10
  else if ieq(k, 8) then 17 else if ieq(k, 9) then 24 else if ieq(k, 10) then 32 else if ieq(k, 11) then 25
  else if ieq(k, 12) then 18 else if ieq(k, 13) then 11 else if ieq(k, 14) then 4 else 5

fun dezigzag_16_31(k: int): int =
  if ieq(k, 16) then 12 else if ieq(k, 17) then 19 else if ieq(k, 18) then 26 else if ieq(k, 19) then 33
  else if ieq(k, 20) then 40 else if ieq(k, 21) then 48 else if ieq(k, 22) then 41 else if ieq(k, 23) then 34
  else if ieq(k, 24) then 27 else if ieq(k, 25) then 20 else if ieq(k, 26) then 13 else if ieq(k, 27) then 6
  else if ieq(k, 28) then 7 else if ieq(k, 29) then 14 else if ieq(k, 30) then 21 else 28

fun dezigzag_32_47(k: int): int =
  if ieq(k, 32) then 35 else if ieq(k, 33) then 42 else if ieq(k, 34) then 49 else if ieq(k, 35) then 56
  else if ieq(k, 36) then 57 else if ieq(k, 37) then 50 else if ieq(k, 38) then 43 else if ieq(k, 39) then 36
  else if ieq(k, 40) then 29 else if ieq(k, 41) then 22 else if ieq(k, 42) then 15 else if ieq(k, 43) then 23
  else if ieq(k, 44) then 30 else if ieq(k, 45) then 37 else if ieq(k, 46) then 44 else 51

fun dezigzag_48_63(k: int): int =
  if ieq(k, 48) then 58 else if ieq(k, 49) then 59 else if ieq(k, 50) then 52 else if ieq(k, 51) then 45
  else if ieq(k, 52) then 38 else if ieq(k, 53) then 31 else if ieq(k, 54) then 39 else if ieq(k, 55) then 46
  else if ieq(k, 56) then 53 else if ieq(k, 57) then 60 else if ieq(k, 58) then 61 else if ieq(k, 59) then 54
  else if ieq(k, 60) then 47 else if ieq(k, 61) then 55 else if ieq(k, 62) then 62 else 63

fun dezigzag(k: int): int =
  if ilt(k, 0) then 0
  else if ilt(k, 16) then dezigzag_0_15(k)
  else if ilt(k, 32) then dezigzag_16_31(k)
  else if ilt(k, 48) then dezigzag_32_47(k)
  else if ilt(k, 64) then dezigzag_48_63(k)
  else 63

fun dequant_word_idx(tbl: int, idx: int): int =
  iadd(imul(iand(tbl, 3), JPG_DCT_BLOCK_SIZE), iand(idx, 63))

fun dequant_get(dqt_buf: !Buf, tbl: int, idx: int): int =
  buf_get32(dqt_buf, dequant_word_idx(tbl, idx))

fun dequant_set(dqt_buf: !Buf, tbl: int, idx: int, v: int): void =
  buf_set32(dqt_buf, dequant_word_idx(tbl, idx), v)

extern fun zero_block_fuel_exhausted(data: !Buf, dbase: int, i: int): void = "mac#anth_die_void"

fun zero_block_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), data: !Buf, dbase: int, i: int): void =
  if recursion_fuel_available(recfuel) then (
    if ige(i, JPG_DCT_BLOCK_SIZE) then ()
    else let
      val () = buf_set32(data, iadd(dbase, i), 0)
    in
      zero_block_with_fuel(recfuel - 1, data, dbase, iadd(i, 1))
    end
  ) else zero_block_fuel_exhausted(data, dbase, i)

fun zero_block(data: !Buf, dbase: int): void =
  zero_block_with_fuel(airlock_nat(MAX_REC_FUEL), data, dbase, 0)

extern fun dequantize_block_fuel_exhausted(data: !Buf, dbase: int, dqt_buf: !Buf, tbl: int, i: int): void = "mac#anth_die_void"

fun dequantize_block_with_fuel {recfuel:nat} .<recfuel>. (recfuel: int(recfuel), data: !Buf, dbase: int, dqt_buf: !Buf, tbl: int, i: int): void =
  if recursion_fuel_available(recfuel) then (
    if ige(i, JPG_DCT_BLOCK_SIZE) then ()
    else let
      val dq = dequant_get(dqt_buf, tbl, i)
      val w = buf_get32(data, iadd(dbase, i))
      val () = buf_set32(data, iadd(dbase, i), imul(w, dq))
    in
      dequantize_block_with_fuel(recfuel - 1, data, dbase, dqt_buf, tbl, iadd(i, 1))
    end
  ) else dequantize_block_fuel_exhausted(data, dbase, dqt_buf, tbl, i)

fun dequantize_block(data: !Buf, dbase: int, dqt_buf: !Buf, tbl: int): void =
  dequantize_block_with_fuel(airlock_nat(MAX_REC_FUEL), data, dbase, dqt_buf, tbl, 0)

#endif
