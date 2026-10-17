implement fold_has(d, off) =
  fold_has_with_fuel(airlock_nat(MAX_REC_FUEL), d, off, 0, fold_count(d))

implement fold_add(d, off) =
  if fold_has(d, off) then ()
  else case+ d of
  | @DOC(s) => let
      val len = buf_len(s.folds)
      val () = buf_ensure(s.folds, iadd(len, 4))
      val () = buf_set32(s.folds, len, off)
      val () = buf_set_len(s.folds, iadd(len, 4))
    in
      fold@(d)
    end

fun doc_take_regions(d: !Doc): Buf =
  case+ d of
  | @DOC(s) => let
      val b = s.regions
      val () = s.regions := buf_make(DOC_TAKE_REGIONS_BUFFER_INITIAL_BYTES)
    in
      fold@(d); b
    end

fun doc_put_regions(d: !Doc, b: Buf): void =
  case+ d of
  | @DOC(s) => let
      val () = buf_free(s.regions)
      val () = s.regions := b
    in
      fold@(d)
    end

fun doc_take_hidden(d: !Doc): Buf =
  case+ d of
  | @DOC(s) => let
      val b = s.hidden
      val () = s.hidden := buf_make(DOC_TAKE_HIDDEN_BUFFER_INITIAL_BYTES)
    in
      fold@(d); b
    end

fun doc_put_hidden(d: !Doc, b: Buf): void =
  case+ d of
  | @DOC(s) => let
      val () = buf_free(s.hidden)
      val () = s.hidden := b
    in
      fold@(d)
    end

implement doc_is_line_hidden(d, line) =
  case+ d of
  | @DOC(s) => let
      val h = fold_region_line_hidden(s.hidden, line)
    in
      fold@(d); h
    end

implement doc_line_region(d, line) =
  case+ d of
  | @DOC(s) => let
      val idx = fold_region_of_line(s.regions, line)
    in
      fold@(d); idx
    end

implement doc_region_count(d) =
  case+ d of
  | @DOC(s) => let
      val n = fold_region_count(s.regions)
    in
      fold@(d); n
    end

implement doc_region_owner(d, idx) =
  case+ d of
  | @DOC(s) => let
      val o = fold_region_owner(s.regions, idx)
    in
      fold@(d); o
    end

implement doc_region_end(d, idx) =
  case+ d of
  | @DOC(s) => let
      val e = fold_region_end(s.regions, idx)
    in
      fold@(d); e
    end

implement doc_region_offset(d, idx) =
  case+ d of
  | @DOC(s) => let
      val o = fold_region_offset(s.regions, idx)
    in
      fold@(d); o
    end

extern fun fold_del_shift_fuel_exhausted(d: !Doc, i: int, n: int): void = "mac#anth_die_void"

fun fold_del_shift_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, i: int, n: int
): void =
  if recursion_fuel_available(recfuel) then (
    if i >= n then ()
    else let
      val v = fold_get(d, iadd(i, 1))
      val () = fold_set(d, i, v)
    in
      fold_del_shift_with_fuel(recfuel - 1, d, iadd(i, 1), n)
    end
  ) else fold_del_shift_fuel_exhausted(d, i, n)

extern fun fold_del_find_fuel_exhausted(d: !Doc, off: int, i: int, n: int): void = "mac#anth_die_void"

fun d_folds_trunc(d: !Doc): void =
  case+ d of
  | @DOC(s) => let
      val b = s.folds
      val n = buf_len(b)
      val () = buf_set_len(b, isub(n, 4))
      val () = s.folds := b
    in
      fold@(d)
    end

fun d_folds_clear(d: !Doc): void =
  case+ d of
  | @DOC(s) => let
      val b = s.folds
      val () = buf_set_len(b, 0)
      val () = s.folds := b
    in
      fold@(d)
    end

extern fun fold_del_find_fuel_exhausted(d: !Doc, off: int, i: int, n: int): void = "mac#anth_die_void"

fun fold_del_find_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, off: int, i: int, n: int
): void =
  if recursion_fuel_available(recfuel) then (
    if i >= n then ()
    else if fold_get(d, i) = off then let
      val () = fold_del_shift_with_fuel(airlock_nat(MAX_REC_FUEL), d, i, isub(n, 1))
      val () = d_folds_trunc(d)
    in
    end else fold_del_find_with_fuel(recfuel - 1, d, off, iadd(i, 1), n)
  ) else fold_del_find_fuel_exhausted(d, off, i, n)

implement fold_del(d, off) =
  fold_del_find_with_fuel(airlock_nat(MAX_REC_FUEL), d, off, 0, fold_count(d))

extern fun fold_shift_fuel_exhausted(d: !Doc, at: int, delta: int, i: int, n: int): void = "mac#anth_die_void"

fun fold_shift_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, at: int, delta: int, i: int, n: int
): void =
  if recursion_fuel_available(recfuel) then (
    if i >= n then ()
    else let
      val v = fold_get(d, i)
      val () = if v >= at then fold_set(d, i, iadd(v, delta)) else ()
    in
      fold_shift_with_fuel(recfuel - 1, d, at, delta, iadd(i, 1), n)
    end
  ) else fold_shift_fuel_exhausted(d, at, delta, i, n)

fun fold_shift(d: !Doc, at: int, delta: int): void =
  fold_shift_with_fuel(airlock_nat(MAX_REC_FUEL), d, at, delta, 0, fold_count(d))

extern fun folds_apply_edit_fuel_exhausted(d: !Doc, at: int, del_bytes: int, ins_bytes: int, i: int): void = "mac#anth_die_void"

fun update_edited_fold(d: !Doc, i: int, off: int, at: int, deleted: int, inserted: int): int =
  if ilt(off, at) then iadd(i, 1)
  else if ilt(off, iadd(at, deleted)) then (fold_del(d, off); i)
  else (fold_set(d, i, iadd(off, isub(inserted, deleted))); iadd(i, 1))

fun folds_apply_edit_with_fuel {recfuel:nat} .<recfuel>. (
  recfuel: int(recfuel), d: !Doc, at: int, del_bytes: int, ins_bytes: int, i: int
): void =
  if recursion_fuel_available(recfuel) then (
    if i >= fold_count(d) then ()
    else let
      val off = fold_get(d, i)
      val next = update_edited_fold(d, i, off, at, del_bytes, ins_bytes)
    in
      folds_apply_edit_with_fuel(recfuel - 1, d, at, del_bytes, ins_bytes, next)
    end
  ) else folds_apply_edit_fuel_exhausted(d, at, del_bytes, ins_bytes, i)
