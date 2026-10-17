implement folds_apply_edit(d, at, del_bytes, ins_bytes) =
  folds_apply_edit_with_fuel(airlock_nat(MAX_REC_FUEL), d, at, del_bytes, ins_bytes, 0)

fun fold_clear(d: !Doc): void = d_folds_clear(d)

fun document_field_get(d: !Doc, w: int): int =
  case+ d of
  | @DOC(s) => let
      val v =
        if w = DOC_FIELD_LO then s.lo
        else if w = DOC_FIELD_HI then s.hi
        else if w = DOC_FIELD_LEN then s.len
        else if w = DOC_FIELD_CARET then s.caret
        else if w = DOC_FIELD_ANCHOR then s.anchor
        else if w = DOC_FIELD_NLINES then s.nlines
        else if w = DOC_FIELD_NNODES then s.nnodes
        else s.span
    in
      fold@(d); v
    end

fun document_field_set(d: !Doc, w: int, v: int): void =
  case+ d of
  | @DOC(s) => let
      val () =
        if w = DOC_FIELD_LO then s.lo := v
        else if w = DOC_FIELD_HI then s.hi := v
        else if w = DOC_FIELD_LEN then s.len := v
        else if w = DOC_FIELD_CARET then s.caret := v
        else if w = DOC_FIELD_ANCHOR then s.anchor := v
        else if w = DOC_FIELD_NLINES then s.nlines := v
        else if w = DOC_FIELD_NNODES then s.nnodes := v
        else s.span := v
    in
      fold@(d)
    end

fun d_lo(d: !Doc): int = document_field_get(d, DOC_FIELD_LO)
fun d_hi(d: !Doc): int = document_field_get(d, DOC_FIELD_HI)
fun d_len(d: !Doc): int = document_field_get(d, DOC_FIELD_LEN)
fun d_caret(d: !Doc): int = document_field_get(d, DOC_FIELD_CARET)
fun d_anchor(d: !Doc): int = document_field_get(d, DOC_FIELD_ANCHOR)
fun d_nlines(d: !Doc): int = document_field_get(d, DOC_FIELD_NLINES)
fun d_nnodes(d: !Doc): int = document_field_get(d, DOC_FIELD_NNODES)
fun d_span(d: !Doc): int = document_field_get(d, DOC_FIELD_SPAN)

fun d_set_lo(d: !Doc, v: int): void = document_field_set(d, DOC_FIELD_LO, v)
fun d_set_hi(d: !Doc, v: int): void = document_field_set(d, DOC_FIELD_HI, v)
fun d_set_len(d: !Doc, v: int): void = document_field_set(d, DOC_FIELD_LEN, v)
fun d_set_caret(d: !Doc, v: int): void = document_field_set(d, DOC_FIELD_CARET, v)
fun d_set_anchor(d: !Doc, v: int): void = document_field_set(d, DOC_FIELD_ANCHOR, v)
fun d_set_nlines(d: !Doc, v: int): void = document_field_set(d, DOC_FIELD_NLINES, v)
fun d_set_nnodes(d: !Doc, v: int): void = document_field_set(d, DOC_FIELD_NNODES, v)
fun d_set_span(d: !Doc, v: int): void = document_field_set(d, DOC_FIELD_SPAN, v)

implement doc_len(d) = d_len(d)
implement doc_touch(d) = seen_int(doc_len(d))
implement doc_caret(d) = d_caret(d)
implement doc_anchor(d) = d_anchor(d)
implement doc_nlines(d) = d_nlines(d)
implement doc_nnodes(d) = d_nnodes(d)
implement doc_span(d) = d_span(d)
implement doc_set_span(d, v) = d_set_span(d, v)

fun take_gap(d: !Doc): Buf =
  case+ d of
  | @DOC(s) => let
      val b = s.gap
      val () = s.gap := buf_make(TAKE_GAP_BUFFER_INITIAL_BYTES)
    in
      fold@(d); b
    end

fun put_gap(d: !Doc, b: Buf): void =
  case+ d of
  | @DOC(s) => let
      val old = s.gap
      val () = s.gap := b
      val () = fold@(d)
    in
      buf_free(old)
    end


fun take_uhist(d: !Doc): Hist =
  case+ d of
  | @DOC(s) => let
      val h = s.uhist
      val () = s.uhist := HNil()
    in
      fold@(d); h
    end

fun put_uhist(d: !Doc, h: Hist): void =
  case+ d of
  | @DOC(s) => let
      val old = s.uhist
      val () = s.uhist := h
      val () = fold@(d)
    in
      hist_free(old)
    end

fun take_rhist(d: !Doc): Hist =
  case+ d of
  | @DOC(s) => let
      val h = s.rhist
      val () = s.rhist := HNil()
    in
      fold@(d); h
    end

fun put_rhist(d: !Doc, h: Hist): void =
  case+ d of
  | @DOC(s) => let
      val old = s.rhist
      val () = s.rhist := h
      val () = fold@(d)
    in
      hist_free(old)
    end

fun gap_get(d: !Doc, i: int): int =
  case+ d of
  | @DOC(s) => let
      val v = buf_get(s.gap, i)
    in
      fold@(d); v
    end

fun gap_set(d: !Doc, i: int, v: int): void =
  case+ d of
  | @DOC(s) => let
      val () = buf_set(s.gap, i, v)
    in
      fold@(d)
    end

implement doc_byte(d, i) = let
  val lo = d_lo(d)
  val hi = d_hi(d)
  val p = if i < lo then i else iadd(hi, isub(i, lo))
in
  gap_get(d, p)
end

fun copy_bytes_forward(src: !Buf, so: int, dst: !Buf, dst0: int, n: int): void =
  buf_copy_range(dst, dst0, src, so, n)

fun move_bytes_forward(b: !Buf, so: int, dst0: int, n: int): void =
  buf_move_within(b, dst0, so, n)

fun move_bytes_backward(b: !Buf, so: int, dst0: int, n: int): void =
  buf_move_within(b, dst0, so, n)

fun gap_grow(d: !Doc, need: int): void = let
  val lo = d_lo(d)
  val hi = d_hi(d)
  val len = d_len(d)
  val b0 = take_gap(d)
  val cap = buf_cap(b0)
  val want = imax(imul(cap, 2), iadd(iadd(len, need), 64))
  val b1 = buf_make(want)
  val tail = isub(len, lo)
  val nhi = isub(want, tail)
  val () = copy_bytes_forward(b0, 0, b1, 0, lo)
  val () = copy_bytes_forward(b0, hi, b1, nhi, tail)
  val () = buf_free(b0)
  val () = put_gap(d, b1)
  val () = d_set_hi(d, nhi)
in
end

fun gap_shift_back(d: !Doc, at: int, lo: int, hi: int): void = let
  val n = isub(lo, at)
  val b = take_gap(d)
  val () = move_bytes_backward(b, at, isub(hi, n), n)
  val () = put_gap(d, b)
  val () = d_set_lo(d, at)
  val () = d_set_hi(d, isub(hi, n))
in
end

fun gap_shift_fwd(d: !Doc, at: int, lo: int, hi: int): void = let
  val n = isub(at, lo)
  val b = take_gap(d)
  val () = move_bytes_forward(b, hi, lo, n)
  val () = put_gap(d, b)
  val () = d_set_lo(d, at)
  val () = d_set_hi(d, iadd(hi, n))
in
end

fun gap_move(d: !Doc, at0: int): void = let
  val len = d_len(d)
  val at = if at0 < 0 then 0 else if at0 > len then len else at0
  val lo = d_lo(d)
  val hi = d_hi(d)
in
  if ieq(at, lo) then ()
  else if ilt(at, lo) then gap_shift_back(d, at, lo, hi)
  else gap_shift_fwd(d, at, lo, hi)
end

